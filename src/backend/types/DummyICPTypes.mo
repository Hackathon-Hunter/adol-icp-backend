import Principal "mo:base/Principal";
import Result "mo:base/Result";

module DummyICPTypes {

    // Token balance type (e8s format: 1 ICP = 100,000,000 e8s)
    public type Balance = Nat;

    // Transfer arguments for ICRC-1 compatibility
    public type TransferArgs = {
        to : Principal;
        amount : Nat; // Amount in e8s
        fee : ?Nat;
        memo : ?[Nat8];
        from_subaccount : ?[Nat8];
        to_subaccount : ?[Nat8];
        created_at_time : ?Nat64;
    };

    // Transfer result
    public type TransferResult = Result.Result<Nat, TransferError>;

    // Transfer error types (ICRC-1 compatible)
    public type TransferError = {
        #BadFee : { expected_fee : Nat };
        #BadBurn : { min_burn_amount : Nat };
        #InsufficientFunds : { balance : Nat };
        #TooOld;
        #CreatedInFuture : { ledger_time : Nat64 };
        #TemporarilyUnavailable;
        #Duplicate : { duplicate_of : Nat };
        #GenericError : { error_code : Nat; message : Text };
    };

    // Account info
    public type Account = {
        owner : Principal;
        subaccount : ?[Nat8];
    };

    // Token metadata
    public type TokenMetadata = {
        name : Text;
        symbol : Text;
        decimals : Nat8;
        fee : Nat;
        total_supply : Nat;
    };

    // Exchange rate info
    public type ExchangeRateInfo = {
        icpToUsd : Float;
        usdToIcp : Float;
        lastUpdated : Int;
    };

    // Payment request for NFT purchases
    public type PaymentRequest = {
        buyer : Principal;
        recipient : Principal; // Platform or project wallet
        amountUSD : Nat; // Amount in USD cents
        memo : ?Text;
    };

    // Payment result
    public type PaymentResult = Result.Result<PaymentSuccess, PaymentError>;

    // Payment success response
    public type PaymentSuccess = {
        transactionId : Nat;
        amountICP : Nat; // Amount paid in ICP e8s
        amountUSD : Nat; // Amount in USD cents
        exchangeRate : Float;
        timestamp : Int;
    };

    // Payment error types
    public type PaymentError = {
        #InsufficientBalance : { required : Nat; available : Nat };
        #TransferFailed : Text;
        #InvalidAmount;
        #InvalidRecipient;
        #ExchangeRateError;
        #SystemError : Text;
    };

    // Allowance for spending
    public type Allowance = {
        allowance : Nat;
        expires_at : ?Nat64;
    };

    // Approve arguments
    public type ApproveArgs = {
        spender : Principal;
        amount : Nat;
        expires_at : ?Nat64;
        fee : ?Nat;
        memo : ?[Nat8];
        from_subaccount : ?[Nat8];
        created_at_time : ?Nat64;
    };

    // Approve result
    public type ApproveResult = Result.Result<Nat, ApproveError>;

    // Approve error types
    public type ApproveError = {
        #BadFee : { expected_fee : Nat };
        #InsufficientFunds : { balance : Nat };
        #AllowanceChanged : { current_allowance : Nat };
        #Expired : { ledger_time : Nat64 };
        #TooOld;
        #CreatedInFuture : { ledger_time : Nat64 };
        #Duplicate : { duplicate_of : Nat };
        #TemporarilyUnavailable;
        #GenericError : { error_code : Nat; message : Text };
    };
};
