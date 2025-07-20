import Map "mo:base/HashMap";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import InvestmentTypes "../types/InvestmentTypes";

module InvestmentStorage {

    type Investment = InvestmentTypes.Investment;

    public class InvestmentStore() {

        // Storage for investments
        private var investmentsEntries : [(Text, Investment)] = [];
        private var investments = Map.fromIter<Text, Investment>(investmentsEntries.vals(), investmentsEntries.size(), Text.equal, Text.hash);

        // Counter for generating investment IDs
        private var investmentCounter : Nat = 0;

        // System functions for upgrades
        public func preupgrade() : [(Text, Investment)] {
            Iter.toArray(investments.entries());
        };

        public func postupgrade(entries : [(Text, Investment)]) {
            investments := Map.fromIter<Text, Investment>(entries.vals(), entries.size(), Text.equal, Text.hash);
        };

        // Generate unique investment ID
        public func generateInvestmentId() : Text {
            investmentCounter += 1;
            "INVESTMENT-" # Nat.toText(investmentCounter);
        };

        // Store investment
        public func putInvestment(investmentId : Text, investment : Investment) {
            investments.put(investmentId, investment);
        };

        // Get investment by ID
        public func getInvestment(investmentId : Text) : ?Investment {
            investments.get(investmentId);
        };

        // Get investments by investor ID
        public func getInvestmentsByInvestor(investorId : Text) : [Investment] {
            let foundInvestments = Array.filter<Investment>(
                investments.vals() |> Iter.toArray(_),
                func(investment : Investment) : Bool {
                    investment.investorId == investorId;
                },
            );
            foundInvestments;
        };

        // Get investments by investor principal
        public func getInvestmentsByInvestorPrincipal(principal : Principal) : [Investment] {
            let foundInvestments = Array.filter<Investment>(
                investments.vals() |> Iter.toArray(_),
                func(investment : Investment) : Bool {
                    investment.investorPrincipal == principal;
                },
            );
            foundInvestments;
        };

        // Get investments by project ID
        public func getInvestmentsByProject(projectId : Text) : [Investment] {
            let foundInvestments = Array.filter<Investment>(
                investments.vals() |> Iter.toArray(_),
                func(investment : Investment) : Bool {
                    investment.projectId == projectId;
                },
            );
            foundInvestments;
        };

        // Get investments by founder ID
        public func getInvestmentsByFounder(founderId : Text) : [Investment] {
            let foundInvestments = Array.filter<Investment>(
                investments.vals() |> Iter.toArray(_),
                func(investment : Investment) : Bool {
                    investment.founderId == founderId;
                },
            );
            foundInvestments;
        };

        // Get investments by status
        public func getInvestmentsByStatus(status : InvestmentTypes.InvestmentStatus) : [Investment] {
            let foundInvestments = Array.filter<Investment>(
                investments.vals() |> Iter.toArray(_),
                func(investment : Investment) : Bool {
                    investment.status == status;
                },
            );
            foundInvestments;
        };

        // Get all investments
        public func getAllInvestments() : [Investment] {
            investments.vals() |> Iter.toArray(_);
        };

        // Get investment count
        public func getInvestmentCount() : Nat {
            investments.size();
        };

        // Update investment
        public func updateInvestment(investmentId : Text, investment : Investment) : Bool {
            switch (investments.get(investmentId)) {
                case null { false };
                case (?_) {
                    investments.put(investmentId, investment);
                    true;
                };
            };
        };

        // Get total investment amount for a project
        public func getTotalInvestmentForProject(projectId : Text) : Nat {
            let projectInvestments = getInvestmentsByProject(projectId);
            var total : Nat = 0;
            for (investment in projectInvestments.vals()) {
                if (investment.status == #Completed) {
                    total += investment.amount;
                };
            };
            total;
        };

        // Get total investment amount for a founder
        public func getTotalInvestmentForFounder(founderId : Text) : Nat {
            let founderInvestments = getInvestmentsByFounder(founderId);
            var total : Nat = 0;
            for (investment in founderInvestments.vals()) {
                if (investment.status == #Completed) {
                    total += investment.amount;
                };
            };
            total;
        };

        // Get investor count for a project
        public func getInvestorCountForProject(projectId : Text) : Nat {
            let projectInvestments = getInvestmentsByProject(projectId);
            let completedInvestments = Array.filter<Investment>(
                projectInvestments,
                func(investment : Investment) : Bool {
                    investment.status == #Completed;
                },
            );
            completedInvestments.size();
        };
    };
};
