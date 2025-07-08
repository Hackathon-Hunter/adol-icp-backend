import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Time "mo:base/Time";
import ICRC7Types "../types/ICRC7Types";

module {

    public class ICRC7Storage() {

        // Storage maps
        private var tokens = HashMap.HashMap<ICRC7Types.TokenId, ICRC7Types.Account>(
            0,
            Nat.equal,
            Hash.hash,
        );

        private var tokenMetadata = HashMap.HashMap<ICRC7Types.TokenId, ICRC7Types.FarmNFTMetadata>(
            0,
            Nat.equal,
            Hash.hash,
        );

        private var ownerTokens = HashMap.HashMap<Principal, [ICRC7Types.TokenId]>(
            0,
            Principal.equal,
            Principal.hash,
        );

        private var approvals = HashMap.HashMap<ICRC7Types.TokenId, ICRC7Types.Account>(
            0,
            Nat.equal,
            Hash.hash,
        );

        // NFT Collections by Investment ID
        private var nftCollections = HashMap.HashMap<Nat, ICRC7Types.NFTCollection>(
            0,
            Nat.equal,
            Hash.hash,
        );

        // NFT Collection operations (defined first)
        public func createNFTCollection(
            investmentId : Nat,
            totalSupply : Nat,
            nftPrice : Nat,
        ) {
            let collection : ICRC7Types.NFTCollection = {
                investmentId = investmentId;
                totalSupply = totalSupply;
                nftPrice = nftPrice;
                availableSupply = totalSupply;
                soldSupply = 0;
                tokenIds = [];
                createdAt = Time.now();
            };
            nftCollections.put(investmentId, collection);
        };

        public func getNFTCollection(investmentId : Nat) : ?ICRC7Types.NFTCollection {
            nftCollections.get(investmentId);
        };

        public func updateNFTCollectionTokenCount(investmentId : Nat, tokenId : ICRC7Types.TokenId) {
            switch (nftCollections.get(investmentId)) {
                case (?collection) {
                    let updatedTokenIds = Array.append<ICRC7Types.TokenId>(collection.tokenIds, [tokenId]);
                    let updatedCollection : ICRC7Types.NFTCollection = {
                        collection with
                        tokenIds = updatedTokenIds;
                        soldSupply = collection.soldSupply + 1;
                        availableSupply = if (collection.availableSupply > 0) {
                            collection.availableSupply - 1;
                        } else { 0 };
                    };
                    nftCollections.put(investmentId, updatedCollection);
                };
                case null {
                    // Collection doesn't exist yet, which is fine during initial setup
                };
            };
        };

        public func getAllNFTCollections() : [ICRC7Types.NFTCollection] {
            Iter.toArray(nftCollections.vals());
        };

        // Token operations (now using the properly defined function above)
        public func mintToken(
            tokenId : ICRC7Types.TokenId,
            to : ICRC7Types.Account,
            metadata : ICRC7Types.FarmNFTMetadata,
        ) : Bool {
            // Check if token already exists
            switch (tokens.get(tokenId)) {
                case (?_) { false }; // Token already exists
                case null {
                    // Mint the token
                    tokens.put(tokenId, to);
                    tokenMetadata.put(tokenId, metadata);

                    // Update owner's token list
                    switch (ownerTokens.get(to.owner)) {
                        case (?existingTokens) {
                            let updatedTokens = Array.append<ICRC7Types.TokenId>(existingTokens, [tokenId]);
                            ownerTokens.put(to.owner, updatedTokens);
                        };
                        case null {
                            ownerTokens.put(to.owner, [tokenId]);
                        };
                    };

                    // Update NFT collection if it exists (function is now defined above)
                    updateNFTCollectionTokenCount(metadata.investmentId, tokenId);

                    true;
                };
            };
        };

        public func getTokenOwner(tokenId : ICRC7Types.TokenId) : ?ICRC7Types.Account {
            tokens.get(tokenId);
        };

        public func getTokenMetadata(tokenId : ICRC7Types.TokenId) : ?ICRC7Types.FarmNFTMetadata {
            tokenMetadata.get(tokenId);
        };

        public func transferToken(
            tokenId : ICRC7Types.TokenId,
            from : ICRC7Types.Account,
            to : ICRC7Types.Account,
        ) : Bool {
            switch (tokens.get(tokenId)) {
                case null { false }; // Token doesn't exist
                case (?currentOwner) {
                    if (currentOwner.owner != from.owner) {
                        return false; // Not the owner
                    };

                    // Update token owner
                    tokens.put(tokenId, to);

                    // Remove from old owner's list
                    switch (ownerTokens.get(from.owner)) {
                        case (?fromTokens) {
                            let filteredTokens = Array.filter<ICRC7Types.TokenId>(
                                fromTokens,
                                func(id) { id != tokenId },
                            );
                            ownerTokens.put(from.owner, filteredTokens);
                        };
                        case null {};
                    };

                    // Add to new owner's list
                    switch (ownerTokens.get(to.owner)) {
                        case (?toTokens) {
                            let updatedTokens = Array.append<ICRC7Types.TokenId>(toTokens, [tokenId]);
                            ownerTokens.put(to.owner, updatedTokens);
                        };
                        case null {
                            ownerTokens.put(to.owner, [tokenId]);
                        };
                    };

                    // Clear any existing approvals
                    approvals.delete(tokenId);

                    true;
                };
            };
        };

        public func getOwnerTokens(owner : Principal) : [ICRC7Types.TokenId] {
            switch (ownerTokens.get(owner)) {
                case (?tokens) { tokens };
                case null { [] };
            };
        };

        public func getBalanceOf(owner : Principal) : Nat {
            switch (ownerTokens.get(owner)) {
                case (?tokens) { tokens.size() };
                case null { 0 };
            };
        };

        public func getTotalSupply() : Nat {
            tokens.size();
        };

        public func getAllTokens() : [ICRC7Types.TokenId] {
            Iter.toArray(tokens.keys());
        };

        public func exists(tokenId : ICRC7Types.TokenId) : Bool {
            switch (tokens.get(tokenId)) {
                case null { false };
                case (?_) { true };
            };
        };

        // Approval operations
        public func approve(
            tokenId : ICRC7Types.TokenId,
            spender : ICRC7Types.Account,
        ) : Bool {
            switch (tokens.get(tokenId)) {
                case null { false }; // Token doesn't exist
                case (?_) {
                    approvals.put(tokenId, spender);
                    true;
                };
            };
        };

        public func getApproved(tokenId : ICRC7Types.TokenId) : ?ICRC7Types.Account {
            approvals.get(tokenId);
        };

        public func isApproved(
            tokenId : ICRC7Types.TokenId,
            spender : Principal,
        ) : Bool {
            switch (approvals.get(tokenId)) {
                case (?approved) { approved.owner == spender };
                case null { false };
            };
        };

        // Get tokens by investment ID
        public func getTokensByInvestmentId(investmentId : Nat) : [ICRC7Types.TokenId] {
            let allTokens = Iter.toArray(tokens.keys());
            Array.mapFilter<ICRC7Types.TokenId, ICRC7Types.TokenId>(
                allTokens,
                func(tokenId) {
                    switch (tokenMetadata.get(tokenId)) {
                        case (?metadata) {
                            if (metadata.investmentId == investmentId) {
                                ?tokenId;
                            } else { null };
                        };
                        case null { null };
                    };
                },
            );
        };

        // Get tokens by farmer
        public func getTokensByFarmer(farmerId : Principal) : [ICRC7Types.TokenId] {
            let allTokens = Iter.toArray(tokens.keys());
            Array.mapFilter<ICRC7Types.TokenId, ICRC7Types.TokenId>(
                allTokens,
                func(tokenId) {
                    switch (tokenMetadata.get(tokenId)) {
                        case (?metadata) {
                            if (metadata.farmerId == farmerId) {
                                ?tokenId;
                            } else { null };
                        };
                        case null { null };
                    };
                },
            );
        };

        // For stable storage during upgrades
        public func getTokenEntries() : [(ICRC7Types.TokenId, ICRC7Types.Account)] {
            Iter.toArray(tokens.entries());
        };

        public func getMetadataEntries() : [(ICRC7Types.TokenId, ICRC7Types.FarmNFTMetadata)] {
            Iter.toArray(tokenMetadata.entries());
        };

        public func getOwnerTokenEntries() : [(Principal, [ICRC7Types.TokenId])] {
            Iter.toArray(ownerTokens.entries());
        };

        public func getApprovalEntries() : [(ICRC7Types.TokenId, ICRC7Types.Account)] {
            Iter.toArray(approvals.entries());
        };

        public func getNFTCollectionEntries() : [(Nat, ICRC7Types.NFTCollection)] {
            Iter.toArray(nftCollections.entries());
        };

        public func initFromStable(
            tokenEntries : [(ICRC7Types.TokenId, ICRC7Types.Account)],
            metadataEntries : [(ICRC7Types.TokenId, ICRC7Types.FarmNFTMetadata)],
            ownerTokenEntries : [(Principal, [ICRC7Types.TokenId])],
            approvalEntries : [(ICRC7Types.TokenId, ICRC7Types.Account)],
            collectionEntries : [(Nat, ICRC7Types.NFTCollection)],
        ) {
            tokens := HashMap.fromIter(tokenEntries.vals(), tokenEntries.size(), Nat.equal, Hash.hash);
            tokenMetadata := HashMap.fromIter(metadataEntries.vals(), metadataEntries.size(), Nat.equal, Hash.hash);
            ownerTokens := HashMap.fromIter(ownerTokenEntries.vals(), ownerTokenEntries.size(), Principal.equal, Principal.hash);
            approvals := HashMap.fromIter(approvalEntries.vals(), approvalEntries.size(), Nat.equal, Hash.hash);
            nftCollections := HashMap.fromIter(collectionEntries.vals(), collectionEntries.size(), Nat.equal, Hash.hash);
        };

        // Statistics helper functions
        public func getInvestmentCount() : Nat {
            nftCollections.size();
        };

        public func getFarmerCount() : Nat {
            ownerTokens.size();
        };

        public func getTotalFundingRequested() : Nat {
            let allCollections = Iter.toArray(nftCollections.vals());
            Array.foldLeft<ICRC7Types.NFTCollection, Nat>(
                allCollections,
                0,
                func(acc, collection) {
                    acc + (collection.nftPrice * collection.totalSupply);
                },
            );
        };
    };
};
