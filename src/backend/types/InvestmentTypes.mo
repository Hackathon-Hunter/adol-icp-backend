import Principal "mo:base/Principal";
import Result "mo:base/Result";

module InvestmentTypes {

    // Investment record
    public type Investment = {
        id : Text;
        investorId : Text;
        investorPrincipal : Principal;
        projectId : Text;
        founderId : Text;
        founderPrincipal : Principal;
        collectionId : Text;
        amount : Nat; // Amount in ICP (e18 format)
        quantity : Nat; // Number of NFTs purchased
        pricePerToken : Nat; // Price per NFT in ICP
        investmentDate : Int;
        status : InvestmentStatus;
        transactionHash : ?Text; // ICP transaction hash
        tokenIds : [Nat]; // NFT token IDs purchased
    };

    // Investment status
    public type InvestmentStatus = {
        #Pending;
        #Processing;
        #Completed;
        #Failed;
        #Refunded;
    };

    // Purchase request
    public type PurchaseRequest = {
        projectId : Text;
        collectionId : Text;
        quantity : Nat; // Number of NFTs to buy
        paymentAmount : Nat; // Amount willing to pay in ICP (e18 format)
    };

    // Purchase result
    public type PurchaseResult = Result.Result<Investment, Text>;

    // Transfer request for ICP
    public type ICPTransferRequest = {
        to : Principal;
        amount : Nat;
        memo : ?Text;
    };

    // Transfer result
    public type TransferResult = Result.Result<Nat, Text>; // Returns block index on success

    // Investment summary for investor
    public type InvestmentSummary = {
        id : Text;
        projectTitle : Text;
        amount : Nat;
        quantity : Nat;
        investmentDate : Int;
        status : InvestmentStatus;
        currentValue : ?Nat; // Current estimated value
    };

    // Error types
    public type InvestmentError = {
        #ProjectNotFound;
        #CollectionNotFound;
        #InvestorNotFound;
        #FounderNotFound;
        #InsufficientFunds;
        #InsufficientSupply;
        #InvalidQuantity;
        #PaymentFailed;
        #TransferFailed;
        #ProjectNotActive;
        #CollectionNotActive;
    };
};
