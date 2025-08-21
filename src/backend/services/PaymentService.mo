import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import PaymentTypes "../types/PaymentTypes";
import PaymentStorage "../storage/PaymentStorage";
import UserService "./UserService";

// Note: For real ICP integration, uncomment this and configure dfx.json
// import Ledger "canister:ledger";

module {
    public class PaymentService(
        storage: PaymentStorage.PaymentStorage,
        userService: UserService.UserService
    ) {
        
        // Configuration - set to false for real ICP integration
        private let USE_SIMULATION = true;
        
        // Platform's ICP account for receiving payments (update this for production)
        // Using anonymous principal for development - replace with real platform principal
        private let PLATFORM_ACCOUNT = Principal.fromText("2vxsx-fae");
        
        public func processTopUp(
            userId: Principal,
            request: PaymentTypes.TopUpRequest
        ) : async Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {
            
            // Validate amount
            if (request.amount == 0) {
                return #err(#InvalidAmount);
            };
            
            // Check if user exists
            switch (userService.getUser(userId)) {
                case (#err(_)) { return #err(#Unauthorized) };
                case (#ok(_)) {
                    
                    // Create payment record
                    let payment = PaymentStorage.createPayment(
                        storage,
                        userId,
                        request.amount,
                        #TopUp
                    );
                    
                    if (USE_SIMULATION) {
                        // SIMULATION MODE - for development and testing
                        await processSimulatedTopUp(userId, payment, request.amount)
                    } else {
                        // REAL ICP MODE - for production
                        await processRealTopUp(userId, payment, request.amount)
                    };
                };
            };
        };
        
        private func processSimulatedTopUp(
            userId: Principal,
            payment: PaymentTypes.Payment,
            amount: Nat
        ) : async Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {
            
            // Simulate successful payment processing
            switch (PaymentStorage.updatePaymentStatus(storage, payment.id, #Completed, ?("simulated-tx-" # Nat.toText(payment.id)))) {
                case (#err(error)) { #err(error) };
                case (#ok(updatedPayment)) {
                    
                    // Add balance to user account
                    switch (userService.topUpBalance(userId, amount)) {
                        case (#err(_)) {
                            // If balance update fails, mark payment as failed
                            ignore PaymentStorage.updatePaymentStatus(storage, payment.id, #Failed, null);
                            #err(#PaymentFailed("Failed to update user balance"));
                        };
                        case (#ok(_)) {
                            #ok(updatedPayment)
                        };
                    };
                };
            };
        };
        
        private func processRealTopUp(
            userId: Principal,
            payment: PaymentTypes.Payment,
            amount: Nat
        ) : async Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {
            
            // For real ICP integration, uncomment this section and configure ICP Ledger
            /*
            try {
                // Check if user has transferred ICP to platform account
                let transferResult = await Ledger.account_balance({
                    account = { 
                        owner = PLATFORM_ACCOUNT;
                        subaccount = ?Principal.toLedgerAccount(userId);
                    }
                });
                
                if (transferResult.e8s >= amount) {
                    // Transfer detected, process the top-up
                    switch (PaymentStorage.updatePaymentStatus(storage, payment.id, #Completed, ?("icp-ledger-confirmed"))) {
                        case (#err(error)) { #err(error) };
                        case (#ok(updatedPayment)) {
                            
                            // Add balance to user account
                            switch (userService.topUpBalance(userId, amount)) {
                                case (#err(_)) {
                                    ignore PaymentStorage.updatePaymentStatus(storage, payment.id, #Failed, null);
                                    #err(#PaymentFailed("Failed to update user balance"));
                                };
                                case (#ok(_)) {
                                    #ok(updatedPayment)
                                };
                            };
                        };
                    };
                } else {
                    ignore PaymentStorage.updatePaymentStatus(storage, payment.id, #Failed, ?("insufficient_transfer"));
                    #err(#PaymentFailed("Transfer not found or insufficient amount"));
                }
            } catch (error) {
                ignore PaymentStorage.updatePaymentStatus(storage, payment.id, #Failed, ?("ledger_error"));
                #err(#PaymentFailed("Failed to verify transfer"));
            }
            */
            
            // Temporary fallback to simulation until ICP Ledger is configured
            await processSimulatedTopUp(userId, payment, amount)
        };
        
        public func getPayment(
            paymentId: PaymentTypes.PaymentId,
            userId: Principal
        ) : Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {
            switch (PaymentStorage.getPayment(storage, paymentId)) {
                case null { #err(#PaymentNotFound) };
                case (?payment) {
                    if (payment.userId != userId) {
                        return #err(#Unauthorized);
                    };
                    #ok(payment)
                };
            }
        };
        
        public func getUserPayments(userId: Principal) : [PaymentTypes.Payment] {
            PaymentStorage.getUserPayments(storage, userId)
        };
        
        public func getAllPayments() : [PaymentTypes.Payment] {
            PaymentStorage.getAllPayments(storage)
        };
        
        public func getPaymentsByStatus(status: PaymentTypes.PaymentStatus) : [PaymentTypes.Payment] {
            PaymentStorage.getPaymentsByStatus(storage, status)
        };
        
        // Admin function to manually update payment status
        public func updatePaymentStatus(
            paymentId: PaymentTypes.PaymentId,
            newStatus: PaymentTypes.PaymentStatus,
            transactionId: ?Text
        ) : Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {
            PaymentStorage.updatePaymentStatus(storage, paymentId, newStatus, transactionId)
        };
        
        // Get platform ICP account for deposits (for real integration)
        public func getPlatformAccount() : Principal {
            PLATFORM_ACCOUNT
        };
        
        // Generate user-specific deposit information
        public func getUserDepositInfo(userId: Principal) : { 
            platformAccount: Principal; 
            userSubaccount: Text;
            instructions: Text;
        } {
            {
                platformAccount = PLATFORM_ACCOUNT;
                userSubaccount = Principal.toText(userId);
                instructions = "Transfer ICP to the platform account with your user ID as memo for automatic credit";
            }
        };
        
        // Check if simulation mode is enabled
        public func isSimulationMode() : Bool {
            USE_SIMULATION
        };
        
        // Get payment configuration info
        public func getPaymentConfig() : {
            simulationMode: Bool;
            platformAccount: Principal;
            minimumAmount: Nat;
        } {
            {
                simulationMode = USE_SIMULATION;
                platformAccount = PLATFORM_ACCOUNT;
                minimumAmount = if (USE_SIMULATION) 1 else 10000; // 0.0001 ICP minimum for real mode
            }
        };
    }
}
