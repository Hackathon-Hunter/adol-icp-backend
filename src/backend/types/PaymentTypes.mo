import Principal "mo:base/Principal";

module {
    public type PaymentId = Nat;
    
    public type PaymentMethod = {
        #ICP;
        #TopUp;
    };
    
    public type PaymentStatus = {
        #Pending;
        #Completed;
        #Failed;
        #Refunded;
    };
    
    public type Payment = {
        id: PaymentId;
        userId: Principal;
        amount: Nat;
        method: PaymentMethod;
        status: PaymentStatus;
        transactionId: ?Text;
        createdAt: Int;
        completedAt: ?Int;
    };
    
    public type TopUpRequest = {
        amount: Nat;
    };
    
    public type ICPTopUpRequest = {
        amount: Nat;
        blockIndex: ?Nat; // Optional block index for verification
    };
    
    public type PaymentError = {
        #PaymentNotFound;
        #InsufficientFunds;
        #InvalidAmount;
        #PaymentFailed: Text;
        #Unauthorized;
        #TransferFailed: Text;
        #InvalidBlockIndex;
    };
}
