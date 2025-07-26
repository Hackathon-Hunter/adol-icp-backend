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
        pricePerToken : Nat; // Price in USD cents
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
        price : Nat; // Price when minted (USD cents)
    };

    // NFT Collection creation request
    public type CreateCollectionRequest = {
        projectId : Text;
        name : Text;
        symbol : Text;
        description : Text;
        image : ?Text;
        maxSupply : Nat;
        pricePerToken : ?Nat; // Optional - will calculate from funding goal if not provided (USD cents)
    };

    // Mint request
    public type MintRequest = {
        collectionId : Text;
        to : Principal;
        tokenMetadata : TokenMetadata;
    };

    // Enhanced purchase request with ICP support
    public type PurchaseRequest = {
        collectionId : Text;
        quantity : Nat; // Number of NFTs to buy
        paymentAmount : Nat; // Expected payment amount in USD cents (will be converted to ICP)
        useICP : ?Bool; // Optional flag to explicitly use ICP payment (default: true)
    };

    // Enhanced purchase request for ICP-specific purchases
    public type ICPPurchaseRequest = {
        collectionId : Text;
        quantity : Nat;
        maxICPAmount : Nat; // Maximum ICP amount willing to pay (in e8s)
        projectWallet : Principal; // Where to send the ICP payment
    };

    // Transfer request (ICRC-7 compliant)
    public type TransferRequest = {
        from : Principal;
        to : Principal;
        token_id : TokenId;
        memo : ?Text;
        created_at_time : ?Int;
    };

    // Transfer result
    public type TransferResult = Result.Result<TokenId, TransferError>;

    // Transfer error types
    public type TransferError = {
        #Unauthorized;
        #TokenNotFound;
        #InvalidRecipient;
        #InsufficientBalance;
        #TransferFailed : Text;
    };

    // Collection result types
    public type CollectionResult = Result.Result<NFTCollection, Text>;
    public type TokenResult = Result.Result<NFTToken, Text>;
    public type MintResult = Result.Result<TokenId, Text>;
    public type PurchaseResult = Result.Result<[TokenId], Text>;

    // Enhanced purchase result with payment details
    public type ICPPurchaseResult = Result.Result<{ tokenIds : [TokenId]; totalCostUSD : Nat; totalCostICP : Nat; exchangeRate : Float; transactionId : Nat; remainingSupply : Nat }, Text>;

    // Collection statistics
    public type CollectionStats = {
        totalCollections : Nat;
        totalTokens : Nat;
        totalVolume : Nat; // Total trading volume in USD cents
        averagePrice : Nat; // Average token price in USD cents
    };

    // Token ownership info
    public type TokenOwnership = {
        tokenId : TokenId;
        owner : Principal;
        collection : Text;
        purchasePrice : Nat; // Original purchase price in USD cents
        currentValue : ?Nat; // Current estimated value in USD cents
    };

    // Market listing (for future secondary market)
    public type MarketListing = {
        tokenId : TokenId;
        seller : Principal;
        priceUSD : Nat; // Listing price in USD cents
        priceICP : ?Nat; // Optional ICP price
        listedAt : Int;
        expiresAt : ?Int;
        isActive : Bool;
    };

    // Batch mint request (for efficient minting)
    public type BatchMintRequest = {
        collectionId : Text;
        recipients : [Principal];
        baseMetadata : TokenMetadata; // Base metadata, will be customized per token
    };

    // Batch mint result
    public type BatchMintResult = Result.Result<[TokenId], Text>;

    // Collection update request (for admin functions)
    public type CollectionUpdateRequest = {
        collectionId : Text;
        isActive : ?Bool;
        pricePerToken : ?Nat; // New price in USD cents
        metadata : ?CollectionMetadata;
    };

    // Token burn request
    public type BurnRequest = {
        tokenId : TokenId;
        from : Principal;
        memo : ?Text;
    };

    // Token burn result
    public type BurnResult = Result.Result<TokenId, Text>;

    // Collection search filters
    public type CollectionFilter = {
        projectId : ?Text;
        isActive : ?Bool;
        minPrice : ?Nat;
        maxPrice : ?Nat;
        hasAvailableSupply : ?Bool;
    };

    // Pagination for large result sets
    public type Pagination = {
        offset : Nat;
        limit : Nat;
    };

    // Paginated collection result
    public type PaginatedCollections = {
        collections : [NFTCollection];
        totalCount : Nat;
        hasMore : Bool;
    };

    // Paginated token result
    public type PaginatedTokens = {
        tokens : [NFTToken];
        totalCount : Nat;
        hasMore : Bool;
    };
};
