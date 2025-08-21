import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import PaymentTypes "../types/PaymentTypes";
import PaymentStorage "../storage/PaymentStorage";
import UserService "./UserService";

// ICP Ledger interface for real integration
import Ledger "canister:ledger";

module {
  public class PaymentServiceV2(
    storage : PaymentStorage.PaymentStorage,
    userService : UserService.UserService,
  ) {

    // Platform's ICP account for receiving payments
    private let PLATFORM_ACCOUNT = Principal.fromText("rdmx6-jaaaa-aaaah-qcaiq-cai"); // Replace with actual platform account

    public func processTopUp(
      userId : Principal,
      request : PaymentTypes.TopUpRequest,
    ) : async Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {

      // Validate amount (minimum 0.0001 ICP = 10,000 e8s)
      if (request.amount < 10000) {
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
            #TopUp,
          );

          // REAL ICP INTEGRATION - Wait for actual transfer
          try {
            // Check if user has transferred ICP to platform account
            let transferResult = await Ledger.account_balance({
              account = {
                owner = PLATFORM_ACCOUNT;
                subaccount = ?Principal.toLedgerAccount(userId);
              };
            });

            if (transferResult.e8s >= request.amount) {
              // Transfer detected, process the top-up

              // Update payment status to completed
              switch (PaymentStorage.updatePaymentStatus(storage, payment.id, #Completed, ?("icp-ledger-confirmed"))) {
                case (#err(error)) { #err(error) };
                case (#ok(updatedPayment)) {

                  // Add balance to user account
                  switch (userService.topUpBalance(userId, request.amount)) {
                    case (#err(_)) {
                      // If balance update fails, mark payment as failed
                      ignore PaymentStorage.updatePaymentStatus(storage, payment.id, #Failed, null);
                      #err(#PaymentFailed("Failed to update user balance"));
                    };
                    case (#ok(_)) {
                      #ok(updatedPayment);
                    };
                  };
                };
              };
            } else {
              // Transfer not found or insufficient amount
              ignore PaymentStorage.updatePaymentStatus(storage, payment.id, #Failed, ?("insufficient_transfer"));
              #err(#PaymentFailed("Transfer not found or insufficient amount"));
            };
          } catch (error) {
            // Ledger call failed
            ignore PaymentStorage.updatePaymentStatus(storage, payment.id, #Failed, ?("ledger_error"));
            #err(#PaymentFailed("Failed to verify transfer"));
          };
        };
      };
    };

    // Alternative: Process top-up with explicit transfer verification
    public func processTopUpWithTransfer(
      userId : Principal,
      request : PaymentTypes.TopUpRequest,
      transferBlockIndex : Nat,
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
            #TopUp,
          );

          try {
            // Verify the transfer using block index
            let blockResult = await Ledger.query_blocks({
              start = transferBlockIndex;
              length = 1;
            });

            // Validate the transfer details
            switch (blockResult.blocks[0]) {
              case (?block) {
                let transaction = block.transaction;
                // Verify sender, receiver, and amount
                if (transaction.transfer) {
                  let transfer = transaction.transfer;
                  if (
                    transfer.to == PLATFORM_ACCOUNT and
                    transfer.amount.e8s >= request.amount
                  ) {

                    // Valid transfer confirmed
                    switch (PaymentStorage.updatePaymentStatus(storage, payment.id, #Completed, ?("block-" # Nat.toText(transferBlockIndex)))) {
                      case (#err(error)) { #err(error) };
                      case (#ok(updatedPayment)) {

                        // Add balance to user account
                        switch (userService.topUpBalance(userId, request.amount)) {
                          case (#err(_)) {
                            ignore PaymentStorage.updatePaymentStatus(storage, payment.id, #Failed, null);
                            #err(#PaymentFailed("Failed to update user balance"));
                          };
                          case (#ok(_)) {
                            #ok(updatedPayment);
                          };
                        };
                      };
                    };
                  } else {
                    ignore PaymentStorage.updatePaymentStatus(storage, payment.id, #Failed, ?("invalid_transfer"));
                    #err(#PaymentFailed("Invalid transfer details"));
                  };
                } else {
                  ignore PaymentStorage.updatePaymentStatus(storage, payment.id, #Failed, ?("no_transfer_found"));
                  #err(#PaymentFailed("No transfer found in block"));
                };
              };
              case null {
                ignore PaymentStorage.updatePaymentStatus(storage, payment.id, #Failed, ?("block_not_found"));
                #err(#PaymentFailed("Block not found"));
              };
            };
          } catch (error) {
            ignore PaymentStorage.updatePaymentStatus(storage, payment.id, #Failed, ?("ledger_query_error"));
            #err(#PaymentFailed("Failed to query ledger"));
          };
        };
      };
    };

    public func getPayment(
      paymentId : PaymentTypes.PaymentId,
      userId : Principal,
    ) : Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {
      switch (PaymentStorage.getPayment(storage, paymentId)) {
        case null { #err(#PaymentNotFound) };
        case (?payment) {
          if (payment.userId != userId) {
            return #err(#Unauthorized);
          };
          #ok(payment);
        };
      };
    };

    public func getUserPayments(userId : Principal) : [PaymentTypes.Payment] {
      PaymentStorage.getUserPayments(storage, userId);
    };

    public func getAllPayments() : [PaymentTypes.Payment] {
      PaymentStorage.getAllPayments(storage);
    };

    public func getPaymentsByStatus(status : PaymentTypes.PaymentStatus) : [PaymentTypes.Payment] {
      PaymentStorage.getPaymentsByStatus(storage, status);
    };

    // Admin function to manually update payment status
    public func updatePaymentStatus(
      paymentId : PaymentTypes.PaymentId,
      newStatus : PaymentTypes.PaymentStatus,
      transactionId : ?Text,
    ) : Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {
      PaymentStorage.updatePaymentStatus(storage, paymentId, newStatus, transactionId);
    };

    // Get platform ICP account for deposits
    public func getPlatformAccount() : Principal {
      PLATFORM_ACCOUNT;
    };

    // Generate user-specific subaccount for easier tracking
    public func getUserDepositAccount(userId : Principal) : {
      owner : Principal;
      subaccount : ?[Nat8];
    } {
      {
        owner = PLATFORM_ACCOUNT;
        subaccount = ?Principal.toLedgerAccount(userId);
      };
    };
  };
};
