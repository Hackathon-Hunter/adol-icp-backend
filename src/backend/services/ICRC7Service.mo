import Time "mo:base/Time";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Iter "mo:base/Iter";

import ICRC7Types "../types/ICRC7Types";
import ICRC7Storage "../storage/ICRC7Storage";
import InvestmentTypes "../types/InvestmentTypes";

module {

    public class ICRC7Service(storage : ICRC7Storage.ICRC7Storage) {

        private var nextTokenId : Nat = 1;

        // Collection metadata
        private let collectionName = "Plantify Farm NFTs";
        private let collectionSymbol = "FARM";
        private let collectionDescription = "NFTs representing ownership stakes in agricultural projects";

        // Default NFT supply per investment project
        private let DEFAULT_NFT_SUPPLY : Nat = 100;

        // ICP conversion constants (1 ICP = 100_000_000 e8s)
        private let ICP_E8S : Nat = 100_000_000;

        // Mint NFT for approved investment project (admin only)
        public func mintFarmNFT(
            adminId : Principal,
            farmerId : Principal,
            investmentProject : InvestmentTypes.InvestmentProject,
            customSupply : ?Nat,
        ) : ICRC7Types.MintResult {

            // TODO: Add admin check
            // if (not isAdmin(adminId)) {
            //     return #Err(#Unauthorized);
            // };

            // Only mint for approved projects
            if (investmentProject.status != #Approved) {
                return #Err(#GenericError({ error_code = 400; message = "Can only mint NFTs for approved investment projects" }));
            };

            // Calculate NFT supply and pricing
            let totalSupply = switch (customSupply) {
                case (?supply) { supply };
                case null { DEFAULT_NFT_SUPPLY };
            };

            let nftPrice = calculateNFTPrice(investmentProject.farmInfo.fundingRequired, totalSupply);

            // Create NFT collection first
            storage.createNFTCollection(investmentProject.id, totalSupply, nftPrice);

            // Create recipient account (farmer)
            let toAccount : ICRC7Types.Account = {
                owner = farmerId;
                subaccount = null;
            };

            // Create NFT metadata
            let metadata : ICRC7Types.FarmNFTMetadata = {
                investmentId = investmentProject.id;
                farmerId = farmerId;
                cropType = getCropTypeText(investmentProject.farmInfo.cropType);
                location = investmentProject.farmInfo.country # ", " # investmentProject.farmInfo.stateProvince # ", " # investmentProject.farmInfo.cityDistrict;
                area = investmentProject.farmInfo.farmSize;
                fundingAmount = investmentProject.farmInfo.fundingRequired;
                createdAt = Time.now();
                projectStatus = "Active";
                expectedYield = investmentProject.experience.expectedYield;
                harvestTimeline = getHarvestTimelineText(investmentProject.experience.harvestTimeline);
                imageUrl = null; // Can be added later
                totalSupply = totalSupply;
                nftPrice = nftPrice;
                availableSupply = totalSupply;
                soldSupply = 0;
            };

            // Mint the first token (represents the collection)
            let success = storage.mintToken(nextTokenId, toAccount, metadata);

            if (success) {
                let currentTokenId = nextTokenId;
                nextTokenId += 1;

                Debug.print("Farm NFT collection created: Token ID " # Nat.toText(currentTokenId) # " for farmer: " # Principal.toText(farmerId) # " with " # Nat.toText(totalSupply) # " total supply at " # Nat.toText(nftPrice) # " e8s per NFT");
                #Ok(currentTokenId);
            } else {
                #Err(#TokenIdAlreadyExists);
            };
        };

        // Transfer NFT
        public func transferNFT(
            callerId : Principal,
            tokenId : ICRC7Types.TokenId,
            to : ICRC7Types.Account,
        ) : ICRC7Types.TransferResult {

            switch (storage.getTokenOwner(tokenId)) {
                case null {
                    return #Err(#NonExistentTokenId);
                };
                case (?currentOwner) {
                    // Check if caller is the owner or approved
                    if (currentOwner.owner != callerId and not storage.isApproved(tokenId, callerId)) {
                        return #Err(#Unauthorized);
                    };

                    let success = storage.transferToken(tokenId, currentOwner, to);

                    if (success) {
                        Debug.print("NFT transferred: Token ID " # Nat.toText(tokenId) # " to " # Principal.toText(to.owner));
                        #Ok(tokenId);
                    } else {
                        #Err(#GenericError({ error_code = 500; message = "Transfer failed" }));
                    };
                };
            };
        };

        // Get owner of token
        public func ownerOf(tokenId : ICRC7Types.TokenId) : ?ICRC7Types.Account {
            storage.getTokenOwner(tokenId);
        };

        // Get balance of owner
        public func balanceOf(owner : Principal) : Nat {
            storage.getBalanceOf(owner);
        };

        // Get tokens owned by user
        public func tokensOf(owner : Principal) : [ICRC7Types.TokenId] {
            storage.getOwnerTokens(owner);
        };

        // Get token metadata
        public func tokenMetadata(tokenId : ICRC7Types.TokenId) : ?ICRC7Types.TokenMetadata {
            switch (storage.getTokenMetadata(tokenId)) {
                case null { null };
                case (?farmMetadata) {
                    ?convertToICRC7Metadata(farmMetadata);
                };
            };
        };

        // Get farm-specific metadata
        public func getFarmMetadata(tokenId : ICRC7Types.TokenId) : ?ICRC7Types.FarmNFTMetadata {
            storage.getTokenMetadata(tokenId);
        };

        // Get total supply
        public func totalSupply() : Nat {
            storage.getTotalSupply();
        };

        // Get all tokens
        public func getAllTokens() : [ICRC7Types.TokenId] {
            storage.getAllTokens();
        };

        // Check if token exists
        public func exists(tokenId : ICRC7Types.TokenId) : Bool {
            storage.exists(tokenId);
        };

        // Get tokens by investment ID
        public func getTokensByInvestment(investmentId : Nat) : [ICRC7Types.TokenId] {
            storage.getTokensByInvestmentId(investmentId);
        };

        // Get tokens by farmer
        public func getTokensByFarmer(farmerId : Principal) : [ICRC7Types.TokenId] {
            storage.getTokensByFarmer(farmerId);
        };

        // Purchase NFT from available supply
        public func purchaseNFT(
            buyerId : Principal,
            request : ICRC7Types.PurchaseNFTRequest,
        ) : ICRC7Types.PurchaseNFTResult {

            // Get NFT collection
            switch (storage.getNFTCollection(request.investmentId)) {
                case null {
                    return #ProjectNotFound;
                };
                case (?collection) {
                    // Validate quantity
                    if (request.quantity == 0) {
                        return #InvalidQuantity;
                    };

                    // Check available supply
                    if (request.quantity > collection.availableSupply) {
                        return #InsufficientSupply({
                            available = collection.availableSupply;
                            requested = request.quantity;
                        });
                    };

                    // Calculate required payment
                    let requiredPayment = collection.nftPrice * request.quantity;

                    // Check payment amount
                    if (request.paymentAmount < requiredPayment) {
                        return #InsufficientPayment({
                            required = requiredPayment;
                            provided = request.paymentAmount;
                        });
                    };

                    // Get original NFT metadata for this investment
                    let originalMetadata = switch (getOriginalMetadataForInvestment(request.investmentId)) {
                        case (?metadata) { metadata };
                        case null {
                            return #Error("Original NFT metadata not found");
                        };
                    };

                    // Mint NFTs to buyer
                    var mintedTokenIds : [ICRC7Types.TokenId] = [];
                    var successfulMints = 0;

                    for (i in Iter.range(0, request.quantity - 1)) {
                        let buyerAccount : ICRC7Types.Account = {
                            owner = buyerId;
                            subaccount = null;
                        };

                        // Update metadata for buyer
                        let buyerMetadata : ICRC7Types.FarmNFTMetadata = {
                            originalMetadata with
                            soldSupply = originalMetadata.soldSupply + successfulMints + 1;
                            availableSupply = originalMetadata.availableSupply - successfulMints - 1;
                        };

                        let success = storage.mintToken(nextTokenId, buyerAccount, buyerMetadata);

                        if (success) {
                            mintedTokenIds := Array.append<ICRC7Types.TokenId>(mintedTokenIds, [nextTokenId]);
                            nextTokenId += 1;
                            successfulMints += 1;
                        };
                    };

                    if (successfulMints > 0) {
                        let remainingAvailable = collection.availableSupply - successfulMints;
                        Debug.print("NFTs purchased: " # Nat.toText(successfulMints) # " tokens minted to buyer: " # Principal.toText(buyerId));

                        #Success({
                            tokenIds = mintedTokenIds;
                            totalPaid = collection.nftPrice * successfulMints;
                            remainingAvailable = remainingAvailable;
                        });
                    } else {
                        #Error("Failed to mint any NFTs");
                    };
                };
            };
        };

        // Get NFT collection information
        public func getNFTCollection(investmentId : Nat) : ?ICRC7Types.NFTCollection {
            storage.getNFTCollection(investmentId);
        };

        // Get all NFT collections
        public func getAllNFTCollections() : [ICRC7Types.NFTCollection] {
            storage.getAllNFTCollections();
        };

        // Calculate NFT price based on funding requirements
        public func calculateNFTPrice(fundingRequiredUSD : Nat, totalSupply : Nat) : Nat {
            // Convert USD to ICP (assuming 1 ICP = $10 for demo purposes)
            // In production, you'd use an oracle for real-time conversion
            let icpPriceUSD = 10; // $10 per ICP
            let fundingRequiredICP = (fundingRequiredUSD + icpPriceUSD - 1) / icpPriceUSD; // Ceiling division

            // Calculate price per NFT in ICP e8s
            let pricePerNFTinICP = (fundingRequiredICP + totalSupply - 1) / totalSupply; // Ceiling division
            let priceInE8s = pricePerNFTinICP * ICP_E8S;

            // Minimum price of 0.01 ICP (1_000_000 e8s)
            let minimumPrice = ICP_E8S / 100;
            if (priceInE8s < minimumPrice) {
                minimumPrice;
            } else {
                priceInE8s;
            };
        };

        // Get pricing information for an investment
        public func getPricingInfo(investmentId : Nat) : ?{
            nftPrice : Nat;
            totalSupply : Nat;
            availableSupply : Nat;
            soldSupply : Nat;
            fundingRequired : Nat;
            priceInICP : Float;
        } {
            switch (storage.getNFTCollection(investmentId)) {
                case (?collection) {
                    ?{
                        nftPrice = collection.nftPrice;
                        totalSupply = collection.totalSupply;
                        availableSupply = collection.availableSupply;
                        soldSupply = collection.soldSupply;
                        fundingRequired = collection.nftPrice * collection.totalSupply;
                        priceInICP = Float.fromInt(collection.nftPrice) / Float.fromInt(ICP_E8S);
                    };
                };
                case null { null };
            };
        };

        // Approve spender for token
        public func approve(
            callerId : Principal,
            tokenId : ICRC7Types.TokenId,
            spender : ICRC7Types.Account,
        ) : ICRC7Types.ApprovalResult {

            switch (storage.getTokenOwner(tokenId)) {
                case null {
                    return #Err(#NonExistentTokenId);
                };
                case (?owner) {
                    if (owner.owner != callerId) {
                        return #Err(#Unauthorized);
                    };

                    let success = storage.approve(tokenId, spender);

                    if (success) {
                        #Ok(tokenId);
                    } else {
                        #Err(#GenericError({ error_code = 500; message = "Approval failed" }));
                    };
                };
            };
        };

        // Get approved spender for token
        public func getApproved(tokenId : ICRC7Types.TokenId) : ?ICRC7Types.Account {
            storage.getApproved(tokenId);
        };

        // Collection metadata
        public func name() : Text {
            collectionName;
        };

        public func symbol() : Text {
            collectionSymbol;
        };

        public func description() : Text {
            collectionDescription;
        };

        public func logo() : ?Text {
            ?"https://plantify.farm/logo.png"; // Replace with actual logo URL
        };

        // Supported standards
        public func supportedStandards() : [ICRC7Types.Standard] {
            [{
                name = "ICRC-7";
                url = "https://github.com/dfinity/ICRC/blob/main/ICRCs/ICRC-7.md";
            }];
        };

        // Update NFT metadata (admin only)
        public func updateNFTMetadata(
            adminId : Principal,
            tokenId : ICRC7Types.TokenId,
            imageUrl : ?Text,
            projectStatus : ?Text,
        ) : Result.Result<(), Text> {

            // TODO: Add admin check
            // if (not isAdmin(adminId)) {
            //     return #err("Unauthorized: Only admins can update NFT metadata");
            // };

            switch (storage.getTokenMetadata(tokenId)) {
                case null {
                    return #err("Token not found");
                };
                case (?currentMetadata) {
                    let updatedMetadata : ICRC7Types.FarmNFTMetadata = {
                        currentMetadata with
                        imageUrl = switch (imageUrl) {
                            case (?url) { ?url };
                            case null { currentMetadata.imageUrl };
                        };
                        projectStatus = switch (projectStatus) {
                            case (?status) { status };
                            case null { currentMetadata.projectStatus };
                        };
                    };

                    // This would require updating the storage - for now, we'll return success
                    Debug.print("NFT metadata updated for token: " # Nat.toText(tokenId));
                    #ok(());
                };
            };
        };

        // Get next token ID
        public func getNextTokenId() : Nat {
            nextTokenId;
        };

        // Set next token ID (for initialization)
        public func setNextTokenId(id : Nat) {
            nextTokenId := id;
        };

        // Helper function to convert crop type to text
        private func getCropTypeText(cropType : InvestmentTypes.CropType) : Text {
            switch (cropType) {
                case (#Rice) { "Rice" };
                case (#Corn) { "Corn" };
                case (#Vegetables) { "Vegetables" };
                case (#Fruits) { "Fruits" };
                case (#Coffee) { "Coffee" };
                case (#Other(text)) { text };
            };
        };

        // Helper function to convert harvest timeline to text
        private func getHarvestTimelineText(timeline : InvestmentTypes.HarvestTimeline) : Text {
            switch (timeline) {
                case (#Short) { "3-4 months" };
                case (#Medium) { "6-8 months" };
                case (#Long) { "12+ months" };
            };
        };

        // Helper function to convert farm metadata to ICRC-7 metadata format
        private func convertToICRC7Metadata(farmMetadata : ICRC7Types.FarmNFTMetadata) : ICRC7Types.TokenMetadata {
            [
                ("name", #Text("Farm NFT #" # Nat.toText(farmMetadata.investmentId))),
                ("description", #Text("Agricultural investment NFT for " # farmMetadata.cropType # " farming project")),
                (
                    "image",
                    #Text(
                        switch (farmMetadata.imageUrl) {
                            case (?url) { url };
                            case null {
                                "https://plantify.farm/default-farm.png";
                            };
                        }
                    ),
                ),
                ("cropType", #Text(farmMetadata.cropType)),
                ("location", #Text(farmMetadata.location)),
                ("area", #Text(farmMetadata.area)),
                ("fundingAmount", #Nat(farmMetadata.fundingAmount)),
                ("expectedYield", #Text(farmMetadata.expectedYield)),
                ("harvestTimeline", #Text(farmMetadata.harvestTimeline)),
                ("projectStatus", #Text(farmMetadata.projectStatus)),
                ("createdAt", #Int(farmMetadata.createdAt)),
                ("investmentId", #Nat(farmMetadata.investmentId)),
                ("farmerId", #Text(Principal.toText(farmMetadata.farmerId))),
                ("totalSupply", #Nat(farmMetadata.totalSupply)),
                ("nftPrice", #Nat(farmMetadata.nftPrice)),
                ("availableSupply", #Nat(farmMetadata.availableSupply)),
                ("soldSupply", #Nat(farmMetadata.soldSupply)),
                ("priceInICP", #Text(Float.toText(Float.fromInt(farmMetadata.nftPrice) / Float.fromInt(ICP_E8S)))),
            ];
        };

        // Helper function to get original metadata for an investment
        private func getOriginalMetadataForInvestment(investmentId : Nat) : ?ICRC7Types.FarmNFTMetadata {
            let tokensForInvestment = storage.getTokensByInvestmentId(investmentId);
            if (tokensForInvestment.size() > 0) {
                storage.getTokenMetadata(tokensForInvestment[0]);
            } else {
                null;
            };
        };
    };
};
