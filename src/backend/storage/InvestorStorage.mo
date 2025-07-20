import Map "mo:base/HashMap";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import InvestorTypes "../types/InvestorTypes";

module InvestorStorage {

    type Investor = InvestorTypes.Investor;

    public class InvestorStore() {

        // Storage for investors
        private var investorsEntries : [(Text, Investor)] = [];
        private var investors = Map.fromIter<Text, Investor>(investorsEntries.vals(), investorsEntries.size(), Text.equal, Text.hash);

        // Counter for generating investor IDs
        private var investorCounter : Nat = 0;

        // System functions for upgrades
        public func preupgrade() : [(Text, Investor)] {
            Iter.toArray(investors.entries());
        };

        public func postupgrade(entries : [(Text, Investor)]) {
            investors := Map.fromIter<Text, Investor>(entries.vals(), entries.size(), Text.equal, Text.hash);
        };

        // Generate unique investor ID
        public func generateInvestorId() : Text {
            investorCounter += 1;
            "INVESTOR-" # Nat.toText(investorCounter);
        };

        // Store investor
        public func putInvestor(investorId : Text, investor : Investor) {
            investors.put(investorId, investor);
        };

        // Get investor by ID
        public func getInvestor(investorId : Text) : ?Investor {
            investors.get(investorId);
        };

        // Get investor by email
        public func getInvestorByEmail(email : Text) : ?Investor {
            for ((_, investor) in investors.entries()) {
                if (investor.email == email) {
                    return ?investor;
                };
            };
            null;
        };

        // Get investor by principal
        public func getInvestorByPrincipal(principal : Principal) : ?Investor {
            for ((_, investor) in investors.entries()) {
                if (investor.principal == principal) {
                    return ?investor;
                };
            };
            null;
        };

        // Check if email exists
        public func emailExists(email : Text) : Bool {
            switch (getInvestorByEmail(email)) {
                case null { false };
                case (?_) { true };
            };
        };

        // Get all investors
        public func getAllInvestors() : [Investor] {
            investors.vals() |> Iter.toArray(_);
        };

        // Get investor count
        public func getInvestorCount() : Nat {
            investors.size();
        };

        // Update investor
        public func updateInvestor(investorId : Text, investor : Investor) : Bool {
            switch (investors.get(investorId)) {
                case null { false };
                case (?_) {
                    investors.put(investorId, investor);
                    true;
                };
            };
        };

        // Delete investor
        public func deleteInvestor(investorId : Text) : Bool {
            switch (investors.remove(investorId)) {
                case null { false };
                case (?_) { true };
            };
        };
    };
};
