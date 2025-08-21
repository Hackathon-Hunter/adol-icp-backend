import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import PaymentTypes "../types/PaymentTypes";

module {
    public type PaymentStorage = {
        payments: HashMap.HashMap<PaymentTypes.PaymentId, PaymentTypes.Payment>;
        var nextPaymentId: Nat;
    };
    
    public func init() : PaymentStorage {
        {
            payments = HashMap.HashMap<PaymentTypes.PaymentId, PaymentTypes.Payment>(0, Nat.equal, func(x: Nat) : Hash.Hash { Nat32.fromNat(x) });
            var nextPaymentId = 1;
        }
    };
    
    public func createPayment(
        storage: PaymentStorage,
        userId: Principal,
        amount: Nat,
        method: PaymentTypes.PaymentMethod
    ) : PaymentTypes.Payment {
        let paymentId = storage.nextPaymentId;
        storage.nextPaymentId += 1;
        
        let payment: PaymentTypes.Payment = {
            id = paymentId;
            userId = userId;
            amount = amount;
            method = method;
            status = #Pending;
            transactionId = null;
            createdAt = Time.now();
            completedAt = null;
        };
        
        storage.payments.put(paymentId, payment);
        payment
    };
    
    public func getPayment(storage: PaymentStorage, paymentId: PaymentTypes.PaymentId) : ?PaymentTypes.Payment {
        storage.payments.get(paymentId)
    };
    
    public func updatePaymentStatus(
        storage: PaymentStorage,
        paymentId: PaymentTypes.PaymentId,
        newStatus: PaymentTypes.PaymentStatus,
        transactionId: ?Text
    ) : Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {
        switch (storage.payments.get(paymentId)) {
            case null { #err(#PaymentNotFound) };
            case (?payment) {
                let completedAt = switch (newStatus) {
                    case (#Completed or #Failed or #Refunded) { ?Time.now() };
                    case _ { payment.completedAt };
                };
                
                let updatedPayment: PaymentTypes.Payment = {
                    payment with
                    status = newStatus;
                    transactionId = transactionId;
                    completedAt = completedAt;
                };
                
                storage.payments.put(paymentId, updatedPayment);
                #ok(updatedPayment)
            };
        };
    };
    
    public func getUserPayments(storage: PaymentStorage, userId: Principal) : [PaymentTypes.Payment] {
        storage.payments.vals()
        |> Iter.filter(_, func(payment: PaymentTypes.Payment) : Bool { payment.userId == userId })
        |> Iter.toArray(_)
    };
    
    public func getAllPayments(storage: PaymentStorage) : [PaymentTypes.Payment] {
        storage.payments.vals() |> Iter.toArray(_)
    };
    
    public func getPaymentsByStatus(storage: PaymentStorage, status: PaymentTypes.PaymentStatus) : [PaymentTypes.Payment] {
        storage.payments.vals()
        |> Iter.filter(_, func(payment: PaymentTypes.Payment) : Bool { payment.status == status })
        |> Iter.toArray(_)
    };
}
