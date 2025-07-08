import Principal "mo:base/Principal";
import Blob "mo:base/Blob";

module {
    public type TokenId = Nat;
    public type Account = {
        owner : Principal;
        subaccount : ?Blob;
    };

    public type TransferArg = {
        from_subaccount : ?Blob;
        to : Account;
        token_id : TokenId;
        memo : ?Blob;
        created_at_time : ?Nat64;
    };

    public type TransferResult = {
        #Ok : TokenId;
        #Err : TransferError;
    };

    public type TransferError = {
        #NonExistentTokenId;
        #InvalidRecipient;
        #Unauthorized;
        #TooOld;
        #CreatedInFuture : { ledger_time : Nat64 };
        #Duplicate : { duplicate_of : TokenId };
        #GenericError : { error_code : Nat; message : Text };
        #GenericBatchError : { error_code : Nat; message : Text };
    };

    public type Value = {
        #Blob : Blob;
        #Text : Text;
        #Nat : Nat;
        #Int : Int;
        #Array : [Value];
        #Map : [(Text, Value)];
    };

    public type TokenMetadata = [(Text, Value)];

    public type Standard = {
        name : Text;
        url : Text;
    };

    // Farm NFT specific metadata
    public type FarmNFTMetadata = {
        investmentId : Nat;
        farmerId : Principal;
        cropType : Text;
        location : Text;
        area : Text;
        fundingAmount : Nat;
        createdAt : Int;
        projectStatus : Text;
        expectedYield : Text;
        harvestTimeline : Text;
        imageUrl : ?Text;
        // NFT Supply and Pricing
        totalSupply : Nat;
        nftPrice : Nat; // Price per NFT in ICP (in e8s format - 1 ICP = 100_000_000 e8s)
        availableSupply : Nat;
        soldSupply : Nat;
    };

    public type MintRequest = {
        to : Account;
        token_id : TokenId;
        metadata : FarmNFTMetadata;
        totalSupply : ?Nat; // Optional override for total supply
    };

    public type MintResult = {
        #Ok : TokenId;
        #Err : MintError;
    };

    public type MintError = {
        #TokenIdAlreadyExists;
        #InvalidRecipient;
        #Unauthorized;
        #GenericError : { error_code : Nat; message : Text };
    };

    public type BalanceOfRequest = {
        owner : Principal;
        subaccount : ?Blob;
    };

    public type TokensOfRequest = {
        owner : Principal;
        subaccount : ?Blob;
    };

    public type ApprovalInfo = {
        from_subaccount : ?Blob;
        spender : Account;
        memo : ?Blob;
        expires_at : ?Nat64;
        created_at_time : ?Nat64;
    };

    public type ApprovalResult = {
        #Ok : TokenId;
        #Err : ApprovalError;
    };

    public type ApprovalError = {
        #NonExistentTokenId;
        #InvalidSpender;
        #Unauthorized;
        #TooOld;
        #CreatedInFuture : { ledger_time : Nat64 };
        #GenericError : { error_code : Nat; message : Text };
    };

    // NFT Collection for Investment Project
    public type NFTCollection = {
        investmentId : Nat;
        totalSupply : Nat;
        nftPrice : Nat; // Price per NFT in ICP e8s
        availableSupply : Nat;
        soldSupply : Nat;
        tokenIds : [TokenId];
        createdAt : Int;
    };

    // Purchase NFT Request
    public type PurchaseNFTRequest = {
        investmentId : Nat;
        quantity : Nat;
        paymentAmount : Nat; // Amount in ICP e8s
    };

    public type PurchaseNFTResult = {
        #Success : {
            tokenIds : [TokenId];
            totalPaid : Nat;
            remainingAvailable : Nat;
        };
        #InsufficientPayment : { required : Nat; provided : Nat };
        #InsufficientSupply : { available : Nat; requested : Nat };
        #ProjectNotFound;
        #InvalidQuantity;
        #Error : Text;
    };
};
