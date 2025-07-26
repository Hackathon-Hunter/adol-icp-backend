import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Blob "mo:base/Blob";
import Nat64 "mo:base/Nat64";
import Float "mo:base/Float";
import DateTime "mo:datetime/DateTime";
import NFTTypes "../types/NFTTypes";
import ProjectTypes "../types/ProjectTypes";
import DummyICPTypes "../types/DummyICPTypes";
import NFTStorage "../storage/NFTStorage";
import DummyICPTokenService "../services/DummyICPTokenService";

module NFTService {

    type NFTCollection = NFTTypes.NFTCollection;
    type NFTToken = NFTTypes.NFTToken;
    type CreateCollectionRequest = NFTTypes.CreateCollectionRequest;
    type MintRequest = NFTTypes.MintRequest;
    type PurchaseRequest = NFTTypes.PurchaseRequest;
    type CollectionResult = NFTTypes.CollectionResult;
    type TokenResult = NFTTypes.TokenResult;
    type MintResult = NFTTypes.MintResult;
    type PurchaseResult = NFTTypes.PurchaseResult;
    type TokenId = NFTTypes.TokenId;
    type CollectionMetadata = NFTTypes.CollectionMetadata;
    type TokenMetadata = NFTTypes.TokenMetadata;
    type Project = ProjectTypes.Project;
    type ProjectStatus = ProjectTypes.ProjectStatus;
    type PaymentRequest = DummyICPTypes.PaymentRequest;
    type PaymentResult = DummyICPTypes.PaymentResult;
    type TransferArgs = DummyICPTypes.TransferArgs;

    public class NFTManager() {

        private let storage = NFTStorage.NFTStore();
        private let icpToken = DummyICPTokenService.DummyICPToken();

        // Initialize the ICP token service
        public func init() {
            icpToken.init();
        };

        // System functions for upgrades
        public func preupgrade() : ([(Text, NFTCollection)], [(TokenId, NFTToken)], [(Principal, [TokenId])]) {
            storage.preupgrade();
        };

        public func postupgrade(
            collectionEntries : [(Text, NFTCollection)],
            tokenEntries : [(TokenId, NFTToken)],
            ownerEntries : [(Principal, [TokenId])],
        ) {
            storage.postupgrade(collectionEntries, tokenEntries, ownerEntries);
        };

        // Calculate NFT price based on funding goal and supply (returns price in USD cents)
        private func calculateTokenPrice(fundingGoal : Nat, maxSupply : Nat) : Nat {
            if (maxSupply == 0) {
                return 0;
            };
            // Simple calculation: funding goal / max supply
            // Add 10% buffer for platform fees and price stability
            let basePrice = fundingGoal / maxSupply;
            basePrice + (basePrice / 10); // +10%
        };

        // Validate project is approved and ready for NFT launch
        private func validateProjectForNFT(project : ?Project) : Result.Result<Project, Text> {
            switch (project) {
                case null { #err("Project not found") };
                case (?proj) {
                    switch (proj.status) {
                        case (#InReview) { #ok(proj) }; // Admin can launch NFTs for approved projects
                        case (#Active) { #ok(proj) }; // Already active projects
                        case (_) {
                            #err("Project must be approved before launching NFT collection");
                        };
                    };
                };
            };
        };

        // Create NFT collection for approved project (Admin function)
        public func createCollection(
            request : CreateCollectionRequest,
            project : ?Project,
            adminPrincipal : Principal,
        ) : CollectionResult {
            // Validate project
            switch (validateProjectForNFT(project)) {
                case (#err(error)) { return #err(error) };
                case (#ok(validProject)) {

                    // Check if collection already exists for this project
                    let existingCollections = storage.getCollectionsByProject(request.projectId);
                    if (existingCollections.size() > 0) {
                        return #err("NFT collection already exists for this project");
                    };

                    // Calculate price per token in USD cents
                    let pricePerToken = switch (request.pricePerToken) {
                        case (?price) { price };
                        case null {
                            calculateTokenPrice(validProject.fundingGoal, request.maxSupply);
                        };
                    };

                    // Generate collection ID
                    let collectionId = "nft-" # request.projectId # "-" # Int.toText(Time.now());

                    // Create collection metadata
                    let metadata : CollectionMetadata = {
                        name = request.name;
                        symbol = request.symbol;
                        description = request.description;
                        image = request.image;
                        supply_cap = ?request.maxSupply;
                    };

                    // Create new collection
                    let newCollection : NFTCollection = {
                        id = collectionId;
                        projectId = request.projectId;
                        metadata = metadata;
                        totalSupply = 0;
                        maxSupply = request.maxSupply;
                        pricePerToken = pricePerToken; // Price in USD cents
                        createdAt = Time.now();
                        createdBy = adminPrincipal;
                        isActive = true;
                    };

                    // Store collection
                    storage.putCollection(collectionId, newCollection);

                    #ok(newCollection);
                };
            };
        };

        // Process ICP payment for NFT purchase
        private func processICPPayment(
            buyer : Principal,
            recipient : Principal,
            amountUSD : Nat,
            memo : ?Text,
        ) : PaymentResult {
            // Convert USD to ICP
            let amountICP = icpToken.usdCentsToICPe8s(amountUSD);

            // Check buyer's balance
            let buyerBalance = icpToken.balanceOf(buyer);
            if (buyerBalance < amountICP) {
                return #err(#InsufficientBalance({ required = amountICP; available = buyerBalance }));
            };

            // Prepare transfer arguments
            let transferArgs : TransferArgs = {
                to = recipient;
                amount = amountICP;
                fee = ?10000; // Default ICP fee: 0.0001 ICP
                memo = switch (memo) {
                    case (?m) { ?Blob.toArray(Text.encodeUtf8(m)) };
                    case null { null };
                };
                from_subaccount = null;
                to_subaccount = null;
                created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
            };

            // Execute transfer
            switch (icpToken.transferFrom(buyer, transferArgs)) {
                case (#err(error)) {
                    let errorMsg = switch (error) {
                        case (#InsufficientFunds({ balance })) {
                            "Insufficient funds. Available: " # Nat.toText(balance) # " e8s";
                        };
                        case (#BadFee({ expected_fee })) {
                            "Invalid fee. Expected: " # Nat.toText(expected_fee) # " e8s";
                        };
                        case (#GenericError({ message })) { message };
                        case (_) { "Transfer failed" };
                    };
                    #err(#TransferFailed(errorMsg));
                };
                case (#ok(transactionId)) {
                    #ok({
                        transactionId = transactionId;
                        amountICP = amountICP;
                        amountUSD = amountUSD;
                        exchangeRate = icpToken.getICPToUSDRate();
                        timestamp = Time.now();
                    });
                };
            };
        };

        // Purchase NFTs with ICP tokens
        public func purchaseTokensWithICP(
            request : PurchaseRequest,
            buyer : Principal,
            projectWallet : Principal // Project's wallet to receive funds
        ) : Result.Result<{ tokenIds : [TokenId]; paymentDetails : DummyICPTypes.PaymentSuccess; totalSupplyAfter : Nat }, Text> {
            switch (storage.getCollection(request.collectionId)) {
                case null { #err("Collection not found") };
                case (?collection) {
                    // Check if collection is active
                    if (not collection.isActive) {
                        return #err("Collection is not active");
                    };

                    // Check remaining supply
                    let remainingSupply = collection.maxSupply - collection.totalSupply;
                    if (remainingSupply < request.quantity) {
                        return #err("Not enough tokens available. Remaining: " # Nat.toText(remainingSupply));
                    };

                    // Calculate total cost in USD cents
                    let totalCostUSD = collection.pricePerToken * request.quantity;

                    // Process ICP payment
                    let paymentMemo = "NFT Purchase - Collection: " # collection.id # " - Quantity: " # Nat.toText(request.quantity);
                    switch (processICPPayment(buyer, projectWallet, totalCostUSD, ?paymentMemo)) {
                        case (#err(paymentError)) {
                            let errorMsg = switch (paymentError) {
                                case (#InsufficientBalance({ required; available })) {
                                    let requiredICP = icpToken.icpE8sToUSDCents(required);
                                    let availableICP = icpToken.icpE8sToUSDCents(available);
                                    "Insufficient ICP balance. Required: ~$" # Nat.toText(requiredICP / 100) # " USD worth of ICP";
                                };
                                case (#TransferFailed(msg)) {
                                    "Payment failed: " # msg;
                                };
                                case (_) { "Payment processing error" };
                            };
                            return #err(errorMsg);
                        };
                        case (#ok(paymentDetails)) {
                            // Payment successful, now mint the NFTs
                            let mintedTokens = Buffer.Buffer<TokenId>(request.quantity);
                            var i = 0;

                            while (i < request.quantity) {
                                let tokenNumber = collection.totalSupply + i + 1;
                                let tokenMetadata : TokenMetadata = {
                                    name = collection.metadata.name # " #" # Nat.toText(tokenNumber);
                                    description = "Investment token for " # collection.metadata.name;
                                    image = collection.metadata.image;
                                    attributes = [
                                        ("collection", collection.metadata.name),
                                        ("token_number", Nat.toText(tokenNumber)),
                                        ("price_usd", Nat.toText(collection.pricePerToken)),
                                        ("price_icp", Nat.toText(paymentDetails.amountICP / request.quantity)),
                                        ("purchase_date", DateTime.now().toText()),
                                        ("exchange_rate", Float.toText(paymentDetails.exchangeRate)),
                                    ];
                                };

                                let mintRequest : MintRequest = {
                                    collectionId = request.collectionId;
                                    to = buyer;
                                    tokenMetadata = tokenMetadata;
                                };

                                switch (mintToken(mintRequest, buyer)) {
                                    case (#err(error)) {
                                        return #err("Failed to mint token: " # error);
                                    };
                                    case (#ok(tokenId)) {
                                        mintedTokens.add(tokenId);
                                    };
                                };

                                i += 1;
                            };

                            // Update collection total supply
                            let updatedCollection : NFTCollection = {
                                id = collection.id;
                                projectId = collection.projectId;
                                metadata = collection.metadata;
                                totalSupply = collection.totalSupply + request.quantity;
                                maxSupply = collection.maxSupply;
                                pricePerToken = collection.pricePerToken;
                                createdAt = collection.createdAt;
                                createdBy = collection.createdBy;
                                isActive = collection.isActive;
                            };
                            ignore storage.updateCollection(request.collectionId, updatedCollection);

                            #ok({
                                tokenIds = Buffer.toArray(mintedTokens);
                                paymentDetails = paymentDetails;
                                totalSupplyAfter = updatedCollection.totalSupply;
                            });
                        };
                    };
                };
            };
        };

        // Legacy purchase function (for backward compatibility)
        public func purchaseTokens(request : PurchaseRequest, buyer : Principal) : PurchaseResult {
            // This now redirects to the ICP-based purchase
            // You would need to provide a default project wallet
            let defaultProjectWallet = Principal.fromText("rdmx6-jaaaa-aaaaa-aaadq-cai");

            switch (purchaseTokensWithICP(request, buyer, defaultProjectWallet)) {
                case (#err(error)) { #err(error) };
                case (#ok(result)) { #ok(result.tokenIds) };
            };
        };

        // Mint individual token
        public func mintToken(request : MintRequest, minter : Principal) : MintResult {
            switch (storage.getCollection(request.collectionId)) {
                case null { #err("Collection not found") };
                case (?collection) {
                    // Check if collection exists and is active
                    if (not collection.isActive) {
                        return #err("Collection is not active");
                    };

                    // Check supply limit
                    if (collection.totalSupply >= collection.maxSupply) {
                        return #err("Collection has reached maximum supply");
                    };

                    // Generate token ID
                    let tokenId : TokenId = collection.totalSupply + 1;
                    let currentTime = Time.now();

                    // Create new token
                    let newToken : NFTToken = {
                        tokenId = tokenId;
                        collectionId = request.collectionId;
                        owner = request.to;
                        metadata = request.tokenMetadata;
                        mintedAt = currentTime;
                        price = collection.pricePerToken;
                    };

                    // Store token
                    storage.putToken(tokenId, newToken);

                    #ok(tokenId);
                };
            };
        };

        // Get collection information
        public func getCollection(collectionId : Text) : ?NFTCollection {
            storage.getCollection(collectionId);
        };

        // Get collections by project
        public func getCollectionsByProject(projectId : Text) : [NFTCollection] {
            storage.getCollectionsByProject(projectId);
        };

        // Get token by ID
        public func getToken(tokenId : TokenId) : ?NFTToken {
            storage.getToken(tokenId);
        };

        // Get tokens owned by principal
        public func getTokensByOwner(owner : Principal) : [NFTToken] {
            let tokenIds = storage.getTokensByOwner(owner);
            let tokens = Buffer.Buffer<NFTToken>(tokenIds.size());
            for (tokenId in tokenIds.vals()) {
                switch (storage.getToken(tokenId)) {
                    case (?token) { tokens.add(token) };
                    case null {};
                };
            };
            Buffer.toArray(tokens);
        };

        // Get remaining supply for a collection
        public func getRemainingSupply(collectionId : Text) : Nat {
            switch (storage.getCollection(collectionId)) {
                case null { 0 };
                case (?collection) {
                    if (collection.totalSupply >= collection.maxSupply) {
                        0;
                    } else {
                        collection.maxSupply - collection.totalSupply;
                    };
                };
            };
        };

        // Get ICP token service for balance checks etc.
        public func getICPToken() : DummyICPTokenService.DummyICPToken {
            icpToken;
        };

        // Helper function to get current ICP/USD exchange rate
        public func getExchangeRate() : { icpToUsd : Float; usdToIcp : Float } {
            icpToken.getExchangeRateInfo();
        };

        // Calculate ICP amount needed for USD purchase
        public func calculateICPForUSD(usdCents : Nat) : Nat {
            icpToken.usdCentsToICPe8s(usdCents);
        };

        // Calculate USD value of ICP amount
        public func calculateUSDForICP(icpE8s : Nat) : Nat {
            icpToken.icpE8sToUSDCents(icpE8s);
        };
    };
};
