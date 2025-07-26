import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Iter "mo:base/Iter";

module DummyICPTokenService {

    // Static USD to ICP conversion rate for simulation
    private let ICP_TO_USD_RATE : Float = 12.50; // 1 ICP = $12.50 USD

    // Token balance type (using Nat for e8s format, where 1 ICP = 100,000,000 e8s)
    public type Balance = Nat;
    public type TransferArgs = {
        to : Principal;
        amount : Nat; // Amount in e8s
        fee : ?Nat;
        memo : ?[Nat8];
        from_subaccount : ?[Nat8];
        to_subaccount : ?[Nat8];
        created_at_time : ?Nat64;
    };

    public type TransferResult = Result.Result<Nat, TransferError>;

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

    // Account balance storage
    // Moved balances and totalSupply inside DummyICPToken class

    public class DummyICPToken() {
        private var balances = HashMap.HashMap<Principal, Balance>(0, Principal.equal, Principal.hash);
        private var totalSupply : Nat = 1000000 * 100000000; // 1M ICP in e8s format

        private let USD_TO_ICP_RATE : Float = 1.0 / ICP_TO_USD_RATE; // 1 USD = 0.08 ICP
        // Initialize with some default balances for testing
        public func init() {
            // Give platform some initial balance for operations
            let platformPrincipal = Principal.fromText("rdmx6-jaaaa-aaaaa-aaadq-cai"); // Example platform principal
            balances.put(platformPrincipal, 100000 * 100000000); // 100K ICP
        };

        // Convert USD cents to ICP e8s
        public func usdCentsToICPe8s(usdCents : Nat) : Nat {
            let usdAmount = Float.fromInt(usdCents) / 100.0; // Convert cents to dollars
            let icpAmount = usdAmount * USD_TO_ICP_RATE;
            let icpE8s = icpAmount * 100000000.0; // Convert to e8s
            Int.abs(Float.toInt(Float.nearest(icpE8s)));
        };

        // Convert ICP e8s to USD cents
        public func icpE8sToUSDCents(icpE8s : Nat) : Nat {
            let icpAmount = Float.fromInt(icpE8s) / 100000000.0; // Convert e8s to ICP
            let usdAmount = icpAmount * ICP_TO_USD_RATE;
            let usdCents = usdAmount * 100.0; // Convert to cents
            Int.abs(Float.toInt(Float.nearest(usdCents)));
        };

        // Get current ICP to USD rate
        public func getICPToUSDRate() : Float {
            ICP_TO_USD_RATE;
        };

        // Get account balance
        public func balanceOf(account : Principal) : Balance {
            switch (balances.get(account)) {
                case (?balance) { balance };
                case null { 0 };
            };
        };

        // Mint tokens to an account (for testing purposes)
        public func mint(to : Principal, amount : Balance) : Bool {
            let currentBalance = balanceOf(to);
            balances.put(to, currentBalance + amount);
            totalSupply += amount;
            true;
        };

        // Burn tokens from an account
        public func burn(from : Principal, amount : Balance) : Bool {
            let currentBalance = balanceOf(from);
            if (currentBalance >= amount) {
                balances.put(from, currentBalance - amount);
                totalSupply -= amount;
                true;
            } else {
                false;
            };
        };

        // Transfer tokens between accounts
        public func transfer(args : TransferArgs) : TransferResult {
            let now = Int.abs(Time.now());

            let from = args.from_subaccount; // In real implementation, this would be derived from caller
            let fromBalance = balanceOf(Principal.fromBlob("\04")); // Placeholder - should use actual caller

            // Default fee of 10,000 e8s (0.0001 ICP)
            let fee = switch (args.fee) {
                case (?f) { f };
                case null { 10000 };
            };

            let totalAmount = args.amount + fee;

            // Check sufficient balance
            if (fromBalance < totalAmount) {
                return #err(#InsufficientFunds({ balance = fromBalance }));
            };

            // Simulate the transfer
            let newFromBalance = fromBalance - totalAmount;
            let toBalance = balanceOf(args.to);
            let newToBalance = toBalance + args.amount;

            // Update balances
            balances.put(Principal.fromBlob("\04"), newFromBalance); // Placeholder from
            balances.put(args.to, newToBalance);

            // Return mock transaction index
            #ok(now);
        };

        // Simulate transfer with specific caller
        public func transferFrom(caller : Principal, args : TransferArgs) : TransferResult {
            let now = Int.abs(Time.now());
            let fromBalance = balanceOf(caller);

            // Default fee of 10,000 e8s (0.0001 ICP)
            let fee = switch (args.fee) {
                case (?f) { f };
                case null { 10000 };
            };

            let totalAmount = args.amount + fee;

            // Check sufficient balance
            if (fromBalance < totalAmount) {
                return #err(#InsufficientFunds({ balance = fromBalance }));
            };

            // Execute the transfer
            let newFromBalance = fromBalance - totalAmount;
            let toBalance = balanceOf(args.to);
            let newToBalance = toBalance + args.amount;

            // Update balances
            balances.put(caller, newFromBalance);
            balances.put(args.to, newToBalance);

            // Return mock transaction index
            #ok(now);
        };

        // Get total supply
        public func getTotalSupply() : Nat {
            totalSupply;
        };

        // Get current exchange rate info
        public func getExchangeRateInfo() : {
            icpToUsd : Float;
            usdToIcp : Float;
        } {
            {
                icpToUsd = ICP_TO_USD_RATE;
                usdToIcp = USD_TO_ICP_RATE;
            };
        };

        // Approve spending (simplified for testing)
        public func approve(spender : Principal, amount : Nat) : Bool {
            // In a real token, this would set allowances
            // For dummy implementation, we'll just return true
            true;
        };

        // Check allowance (simplified for testing)
        public func allowance(owner : Principal, spender : Principal) : Nat {
            // In a real token, this would return the approved amount
            // For dummy implementation, we'll return a large number
            1000000 * 100000000; // 1M ICP
        };

        // System functions for upgrades
        public func preupgrade() : [(Principal, Balance)] {
            balances.entries() |> Iter.toArray(_);
        };

        public func postupgrade(entries : [(Principal, Balance)]) {
            balances := HashMap.fromIter<Principal, Balance>(
                entries.vals(),
                entries.size(),
                Principal.equal,
                Principal.hash,
            );
        };
    };
};
