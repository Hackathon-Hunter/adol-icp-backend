import Map "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Nat32 "mo:base/Nat32";
import NFTTypes "../types/NFTTypes";

module NFTStorage {

    type NFTCollection = NFTTypes.NFTCollection;
    type NFTToken = NFTTypes.NFTToken;
    type TokenId = NFTTypes.TokenId;
    type OwnerBalance = {
        owner : Principal;
        collectionId : Text;
        tokenIds : [TokenId];
        totalTokens : Nat;
    };

    public class NFTStore() {

        // Storage for collections
        private var collectionsEntries : [(Text, NFTCollection)] = [];
        private var collections = Map.fromIter<Text, NFTCollection>(collectionsEntries.vals(), collectionsEntries.size(), Text.equal, Text.hash);

        // Storage for tokens
        private var tokensEntries : [(TokenId, NFTToken)] = [];
        private var tokens = Map.fromIter<TokenId, NFTToken>(tokensEntries.vals(), tokensEntries.size(), Nat.equal, Nat32.fromNat);

        // Storage for ownership mapping: Principal -> [TokenId]
        private var ownershipEntries : [(Principal, [TokenId])] = [];
        private var ownership = Map.fromIter<Principal, [TokenId]>(ownershipEntries.vals(), ownershipEntries.size(), Principal.equal, Principal.hash);

        // Counter for generating collection IDs and token IDs
        private var collectionCounter : Nat = 0;
        private var tokenCounter : Nat = 0;

        // System functions for upgrades
        public func preupgrade() : ([(Text, NFTCollection)], [(TokenId, NFTToken)], [(Principal, [TokenId])]) {
            (
                Iter.toArray(collections.entries()),
                Iter.toArray(tokens.entries()),
                Iter.toArray(ownership.entries())
            );
        };

        public func postupgrade(
            collectionEntries : [(Text, NFTCollection)],
            tokenEntries : [(TokenId, NFTToken)],
            ownerEntries : [(Principal, [TokenId])],
        ) {
            collections := Map.fromIter<Text, NFTCollection>(collectionEntries.vals(), collectionEntries.size(), Text.equal, Text.hash);
            tokens := Map.fromIter<TokenId, NFTToken>(tokenEntries.vals(), tokenEntries.size(), Nat.equal, Nat32.fromNat);
            ownership := Map.fromIter<Principal, [TokenId]>(ownerEntries.vals(), ownerEntries.size(), Principal.equal, Principal.hash);
        };

        // Generate unique collection ID
        public func generateCollectionId() : Text {
            collectionCounter += 1;
            "COLLECTION-" # Nat.toText(collectionCounter);
        };

        // Generate unique token ID
        public func generateTokenId() : TokenId {
            tokenCounter += 1;
            tokenCounter;
        };

        // Collection management
        public func putCollection(collectionId : Text, collection : NFTCollection) {
            collections.put(collectionId, collection);
        };

        public func getCollection(collectionId : Text) : ?NFTCollection {
            collections.get(collectionId);
        };

        public func getAllCollections() : [NFTCollection] {
            collections.vals() |> Iter.toArray(_);
        };

        public func getCollectionsByProject(projectId : Text) : [NFTCollection] {
            let foundCollections = Array.filter<NFTCollection>(
                collections.vals() |> Iter.toArray(_),
                func(collection : NFTCollection) : Bool {
                    collection.projectId == projectId;
                },
            );
            foundCollections;
        };

        public func getActiveCollections() : [NFTCollection] {
            let activeCollections = Array.filter<NFTCollection>(
                collections.vals() |> Iter.toArray(_),
                func(collection : NFTCollection) : Bool {
                    collection.isActive;
                },
            );
            activeCollections;
        };

        public func updateCollection(collectionId : Text, collection : NFTCollection) : Bool {
            switch (collections.get(collectionId)) {
                case null { false };
                case (?_) {
                    collections.put(collectionId, collection);
                    true;
                };
            };
        };

        // Token management
        public func putToken(tokenId : TokenId, token : NFTToken) {
            tokens.put(tokenId, token);

            // Update ownership mapping
            switch (ownership.get(token.owner)) {
                case null {
                    ownership.put(token.owner, [tokenId]);
                };
                case (?currentTokens) {
                    let newTokens = Array.append<TokenId>(currentTokens, [tokenId]);
                    ownership.put(token.owner, newTokens);
                };
            };
        };

        public func getToken(tokenId : TokenId) : ?NFTToken {
            tokens.get(tokenId);
        };

        public func getTokensByCollection(collectionId : Text) : [NFTToken] {
            let foundTokens = Array.filter<NFTToken>(
                tokens.vals() |> Iter.toArray(_),
                func(token : NFTToken) : Bool {
                    token.collectionId == collectionId;
                },
            );
            foundTokens;
        };

        public func getTokensByOwner(owner : Principal) : [TokenId] {
            switch (ownership.get(owner)) {
                case null { [] };
                case (?tokenIds) { tokenIds };
            };
        };

        public func getTokensOwnedByUser(owner : Principal) : [NFTToken] {
            let tokenIds = getTokensByOwner(owner);
            let ownedTokens = Array.mapFilter<TokenId, NFTToken>(
                tokenIds,
                func(tokenId : TokenId) : ?NFTToken {
                    getToken(tokenId);
                },
            );
            ownedTokens;
        };

        // Transfer token ownership
        public func transferToken(tokenId : TokenId, from : Principal, to : Principal) : Bool {
            switch (getToken(tokenId)) {
                case null { false };
                case (?token) {
                    if (token.owner != from) {
                        return false;
                    };

                    // Update token owner
                    let updatedToken : NFTToken = {
                        tokenId = token.tokenId;
                        collectionId = token.collectionId;
                        owner = to;
                        metadata = token.metadata;
                        mintedAt = token.mintedAt;
                        price = token.price;
                    };
                    tokens.put(tokenId, updatedToken);

                    // Update ownership mappings
                    // Remove from old owner
                    switch (ownership.get(from)) {
                        case null { /* This shouldn't happen */ };
                        case (?fromTokens) {
                            let updatedFromTokens = Array.filter<TokenId>(fromTokens, func(id : TokenId) : Bool { id != tokenId });
                            ownership.put(from, updatedFromTokens);
                        };
                    };

                    // Add to new owner
                    switch (ownership.get(to)) {
                        case null {
                            ownership.put(to, [tokenId]);
                        };
                        case (?toTokens) {
                            let updatedToTokens = Array.append<TokenId>(toTokens, [tokenId]);
                            ownership.put(to, updatedToTokens);
                        };
                    };

                    true;
                };
            };
        };

        // Statistics
        public func getCollectionCount() : Nat {
            collections.size();
        };

        public func getTotalTokenCount() : Nat {
            tokens.size();
        };

        public func getTokenCountByCollection(collectionId : Text) : Nat {
            getTokensByCollection(collectionId).size();
        };

        public func getTotalValueLocked() : Nat {
            let allTokens = tokens.vals() |> Iter.toArray(_);
            var total : Nat = 0;
            for (token in allTokens.vals()) {
                total += token.price;
            };
            total;
        };

        // Collection supply management
        public func getRemainingSupply(collectionId : Text) : Nat {
            switch (getCollection(collectionId)) {
                case null { 0 };
                case (?collection) {
                    let minted = getTokenCountByCollection(collectionId);
                    if (collection.maxSupply > minted) {
                        collection.maxSupply - minted;
                    } else {
                        0;
                    };
                };
            };
        };

        public func isCollectionSoldOut(collectionId : Text) : Bool {
            getRemainingSupply(collectionId) == 0;
        };

        // Owner balance information
        public func getOwnerBalance(owner : Principal, collectionId : Text) : OwnerBalance {
            let allTokens = getTokensOwnedByUser(owner);
            let collectionTokens = Array.filter<NFTToken>(
                allTokens,
                func(token : NFTToken) : Bool {
                    token.collectionId == collectionId;
                },
            );
            let tokenIds = Array.map<NFTToken, TokenId>(
                collectionTokens,
                func(token : NFTToken) : TokenId {
                    token.tokenId;
                },
            );

            {
                owner = owner;
                collectionId = collectionId;
                tokenIds = tokenIds;
                totalTokens = tokenIds.size();
            };
        };
    };
};
