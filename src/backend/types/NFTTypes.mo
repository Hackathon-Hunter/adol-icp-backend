import Principal "mo:base/Principal";
import Result "mo:base/Result";

module NFTTypes {

    // ICRC-7 compliant token ID type
    public type TokenId = Nat;

    // NFT Collection metadata
    public type CollectionMetadata = {
        name : Text;
        symbol : Text;
        description : Text;
        image : ?Text;
        supply_cap : ?Nat;
    };

    // Individual NFT metadata
    public type TokenMetadata = {
        name : Text;
        description : Text;
        image : ?Text;
        attributes : [(Text, Text)]; // Key-value pairs for attributes
    };

    // NFT Collection structure
    public type NFTCollection = {
        id : Text;
        projectId : Text;
        metadata : CollectionMetadata;
        totalSupply : Nat;
        maxSupply : Nat;
        pricePerToken : Nat; // in ICP
        createdAt : Int;
        createdBy : Principal;
        isActive : Bool;
    };

    // Individual NFT token
    public type NFTToken = {
        tokenId : TokenId;
        collectionId : Text;
        owner : Principal;
        metadata : TokenMetadata;
        mintedAt : Int;
        price : Nat; // Price when minted
    };

    // NFT Collection creation request
    public type CreateCollectionRequest = {
        projectId : Text;
        name : Text;
        symbol : Text;
        description : Text;
        image : ?Text;
        maxSupply : Nat;
        pricePerToken : ?Nat; // Optional - will calculate from funding goal if not provided
    };

    // Mint request
    public type MintRequest = {
        collectionId : Text;
        to : Principal;
        tokenMetadata : TokenMetadata;
    };

    // Transfer request (ICRC-7 compliant)
    public type TransferRequest = {
        from : Principal;
        to : Principal;
        token_id : TokenId;
        memo : ?[Nat8];
        created_at_time : ?Nat64;
    };

    // ICRC-7 Transfer result
    public type TransferResult = {
        #Ok : Nat; // Transaction index
        #Err : TransferError;
    };

    // ICRC-7 Transfer errors
    public type TransferError = {
        #Unauthorized;
        #TokenNotFound;
        #InvalidRecipient;
        #CreatedInFuture : { ledger_time : Nat64 };
        #Duplicate : { duplicate_of : Nat };
        #GenericError : { error_code : Nat; message : Text };
    };

    // Purchase request
    public type PurchaseRequest = {
        collectionId : Text;
        quantity : Nat;
        paymentAmount : Nat; // in ICP
    };

    // Collection status
    public type CollectionStatus = {
        #Draft;
        #Active;
        #SoldOut;
        #Paused;
        #Completed;
    };

    // Response types
    public type CollectionResult = Result.Result<NFTCollection, Text>;
    public type TokenResult = Result.Result<NFTToken, Text>;
    public type MintResult = Result.Result<TokenId, Text>;
    public type PurchaseResult = Result.Result<[TokenId], Text>;

    // Collection statistics
    public type CollectionStats = {
        totalCollections : Nat;
        totalTokensMinted : Nat;
        totalValueLocked : Nat; // Total value in ICP
        activeCollections : Nat;
    };

    // Market data
    public type MarketData = {
        collectionId : Text;
        projectTitle : Text;
        floorPrice : Nat;
        totalVolume : Nat;
        tokensSold : Nat;
        tokensRemaining : Nat;
        lastSalePrice : ?Nat;
        lastSaleTime : ?Int;
    };

    // Owner balance
    public type OwnerBalance = {
        owner : Principal;
        collectionId : Text;
        tokenIds : [TokenId];
        totalTokens : Nat;
    };

    // Error types
    public type NFTError = {
        #CollectionNotFound;
        #TokenNotFound;
        #Unauthorized;
        #InsufficientPayment;
        #MaxSupplyReached;
        #CollectionNotActive;
        #ProjectNotApproved;
        #InvalidPrice;
        #InvalidSupply;
    };
};
