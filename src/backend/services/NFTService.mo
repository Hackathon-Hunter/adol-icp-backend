import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import DateTime "mo:datetime/DateTime";
import NFTTypes "../types/NFTTypes";
import ProjectTypes "../types/ProjectTypes";
import NFTStorage "../storage/NFTStorage";

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

    public class NFTManager() {

        private let storage = NFTStorage.NFTStore();

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

        // Calculate NFT price based on funding goal and supply
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

                    // Validate supply
                    if (request.maxSupply == 0 or request.maxSupply > 1000000) {
                        return #err("Max supply must be between 1 and 1,000,000");
                    };

                    // Calculate price per token
                    let pricePerToken = switch (request.pricePerToken) {
                        case (?price) { price };
                        case null {
                            calculateTokenPrice(validProject.fundingGoal, request.maxSupply);
                        };
                    };

                    if (pricePerToken == 0) {
                        return #err("Invalid token price calculation");
                    };

                    // Create collection
                    let collectionId = storage.generateCollectionId();
                    let currentTime = Time.now();

                    let collectionMetadata : CollectionMetadata = {
                        name = request.name;
                        symbol = request.symbol;
                        description = request.description;
                        image = request.image;
                        supply_cap = ?request.maxSupply;
                    };

                    let newCollection : NFTCollection = {
                        id = collectionId;
                        projectId = request.projectId;
                        metadata = collectionMetadata;
                        totalSupply = 0; // Start with 0 minted
                        maxSupply = request.maxSupply;
                        pricePerToken = pricePerToken;
                        createdAt = currentTime;
                        createdBy = adminPrincipal;
                        isActive = true;
                    };

                    // Store collection
                    storage.putCollection(collectionId, newCollection);

                    #ok(newCollection);
                };
            };
        };

        // Get collection by ID
        public func getCollection(collectionId : Text) : ?NFTCollection {
            storage.getCollection(collectionId);
        };

        // Get collections by project
        public func getCollectionsByProject(projectId : Text) : [NFTCollection] {
            storage.getCollectionsByProject(projectId);
        };

        // Get all active collections
        public func getActiveCollections() : [NFTCollection] {
            storage.getActiveCollections();
        };

        // Mint NFT token (when user purchases)
        public func mintToken(request : MintRequest, _buyer : Principal) : MintResult {
            switch (storage.getCollection(request.collectionId)) {
                case null { #err("Collection not found") };
                case (?collection) {
                    // Check if collection is active
                    if (not collection.isActive) {
                        return #err("Collection is not active");
                    };

                    // Check if max supply reached
                    if (storage.getRemainingSupply(request.collectionId) == 0) {
                        return #err("Collection is sold out");
                    };

                    // Generate token ID
                    let tokenId = storage.generateTokenId();
                    let currentTime = Time.now();

                    // Create token
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

                    // Update collection total supply
                    let updatedCollection : NFTCollection = {
                        id = collection.id;
                        projectId = collection.projectId;
                        metadata = collection.metadata;
                        totalSupply = collection.totalSupply + 1;
                        maxSupply = collection.maxSupply;
                        pricePerToken = collection.pricePerToken;
                        createdAt = collection.createdAt;
                        createdBy = collection.createdBy;
                        isActive = collection.isActive;
                    };
                    ignore storage.updateCollection(request.collectionId, updatedCollection);

                    #ok(tokenId);
                };
            };
        };

        // Purchase NFTs (simplified purchase flow)
        public func purchaseTokens(request : PurchaseRequest, buyer : Principal) : PurchaseResult {
            switch (storage.getCollection(request.collectionId)) {
                case null { #err("Collection not found") };
                case (?collection) {
                    // Check if collection is active
                    if (not collection.isActive) {
                        return #err("Collection is not active");
                    };

                    // Check remaining supply
                    let remainingSupply = storage.getRemainingSupply(request.collectionId);
                    if (remainingSupply < request.quantity) {
                        return #err("Not enough tokens available. Remaining: " # Nat.toText(remainingSupply));
                    };

                    // Calculate total cost
                    let totalCost = collection.pricePerToken * request.quantity;
                    if (request.paymentAmount < totalCost) {
                        return #err("Insufficient payment. Required: " # Nat.toText(totalCost) # " cents");
                    };

                    // Mint tokens
                    let mintedTokens = Buffer.Buffer<TokenId>(request.quantity);
                    var i = 0;
                    while (i < request.quantity) {
                        let tokenMetadata : TokenMetadata = {
                            name = collection.metadata.name # " #" # Nat.toText(collection.totalSupply + i + 1);
                            description = "Investment token for " # collection.metadata.name;
                            image = collection.metadata.image;
                            attributes = [
                                ("collection", collection.metadata.name),
                                ("token_number", Nat.toText(collection.totalSupply + i + 1)),
                                ("price", Nat.toText(collection.pricePerToken)),
                                ("purchase_date", DateTime.now().toText()),
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

                    #ok(Buffer.toArray(mintedTokens));
                };
            };
        };

        // Get token by ID
        public func getToken(tokenId : TokenId) : ?NFTToken {
            storage.getToken(tokenId);
        };

        // Get tokens owned by user
        public func getTokensByOwner(owner : Principal) : [NFTToken] {
            storage.getTokensOwnedByUser(owner);
        };

        // Get tokens in a collection
        public func getTokensByCollection(collectionId : Text) : [NFTToken] {
            storage.getTokensByCollection(collectionId);
        };

        // Transfer token (ICRC-7 compliant)
        public func transferToken(tokenId : TokenId, from : Principal, to : Principal) : Result.Result<(), Text> {
            switch (storage.getToken(tokenId)) {
                case null { #err("Token not found") };
                case (?token) {
                    if (token.owner != from) {
                        return #err("Unauthorized: Not token owner");
                    };

                    if (storage.transferToken(tokenId, from, to)) {
                        #ok(());
                    } else {
                        #err("Transfer failed");
                    };
                };
            };
        };

        // Admin functions
        public func pauseCollection(collectionId : Text) : Result.Result<(), Text> {
            switch (storage.getCollection(collectionId)) {
                case null { #err("Collection not found") };
                case (?collection) {
                    let updatedCollection : NFTCollection = {
                        id = collection.id;
                        projectId = collection.projectId;
                        metadata = collection.metadata;
                        totalSupply = collection.totalSupply;
                        maxSupply = collection.maxSupply;
                        pricePerToken = collection.pricePerToken;
                        createdAt = collection.createdAt;
                        createdBy = collection.createdBy;
                        isActive = false;
                    };

                    if (storage.updateCollection(collectionId, updatedCollection)) {
                        #ok(());
                    } else {
                        #err("Failed to pause collection");
                    };
                };
            };
        };

        public func resumeCollection(collectionId : Text) : Result.Result<(), Text> {
            switch (storage.getCollection(collectionId)) {
                case null { #err("Collection not found") };
                case (?collection) {
                    let updatedCollection : NFTCollection = {
                        id = collection.id;
                        projectId = collection.projectId;
                        metadata = collection.metadata;
                        totalSupply = collection.totalSupply;
                        maxSupply = collection.maxSupply;
                        pricePerToken = collection.pricePerToken;
                        createdAt = collection.createdAt;
                        createdBy = collection.createdBy;
                        isActive = true;
                    };

                    if (storage.updateCollection(collectionId, updatedCollection)) {
                        #ok(());
                    } else {
                        #err("Failed to resume collection");
                    };
                };
            };
        };

        // Statistics
        public func getCollectionStats() : NFTTypes.CollectionStats {
            {
                totalCollections = storage.getCollectionCount();
                totalTokensMinted = storage.getTotalTokenCount();
                totalValueLocked = storage.getTotalValueLocked();
                activeCollections = storage.getActiveCollections().size();
            };
        };

        // Get user's NFT balance for a specific collection
        public func getUserBalance(user : Principal, collectionId : Text) : NFTTypes.OwnerBalance {
            storage.getOwnerBalance(user, collectionId);
        };
    };
};
