import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import Array "mo:base/Array";
import InvestorTypes "../types/InvestorTypes";

module {

    public class InvestorStorage() {

        // Storage maps
        private var investors = HashMap.HashMap<InvestorTypes.InvestorId, InvestorTypes.InvestorProfile>(
            0,
            Principal.equal,
            Principal.hash,
        );

        private var emailToInvestor = HashMap.HashMap<Text, InvestorTypes.InvestorId>(
            0,
            Text.equal,
            Text.hash,
        );

        // Investor investments tracking
        private var investorInvestments = HashMap.HashMap<InvestorTypes.InvestorId, [InvestorTypes.InvestorInvestment]>(
            0,
            Principal.equal,
            Principal.hash,
        );

        // Storage operations
        public func putInvestor(investorId : InvestorTypes.InvestorId, investor : InvestorTypes.InvestorProfile) {
            investors.put(investorId, investor);
            emailToInvestor.put(investor.email, investorId);
        };

        public func getInvestor(investorId : InvestorTypes.InvestorId) : ?InvestorTypes.InvestorProfile {
            investors.get(investorId);
        };

        public func getInvestorByEmail(email : Text) : ?InvestorTypes.InvestorId {
            emailToInvestor.get(email);
        };

        public func updateInvestor(investorId : InvestorTypes.InvestorId, investor : InvestorTypes.InvestorProfile) {
            // Remove old email mapping if email changed
            switch (investors.get(investorId)) {
                case (?oldInvestor) {
                    if (oldInvestor.email != investor.email) {
                        emailToInvestor.delete(oldInvestor.email);
                        emailToInvestor.put(investor.email, investorId);
                    };
                };
                case null {};
            };

            investors.put(investorId, investor);
        };

        public func getAllInvestors() : [InvestorTypes.InvestorProfile] {
            Iter.toArray(investors.vals());
        };

        public func deleteInvestor(investorId : InvestorTypes.InvestorId) {
            switch (investors.get(investorId)) {
                case (?investor) {
                    emailToInvestor.delete(investor.email);
                    investors.delete(investorId);
                    investorInvestments.delete(investorId);
                };
                case null {};
            };
        };

        // Investment tracking operations
        public func addInvestorInvestment(
            investorId : InvestorTypes.InvestorId,
            investment : InvestorTypes.InvestorInvestment,
        ) {
            switch (investorInvestments.get(investorId)) {
                case (?existingInvestments) {
                    let updatedInvestments = Array.append<InvestorTypes.InvestorInvestment>(existingInvestments, [investment]);
                    investorInvestments.put(investorId, updatedInvestments);
                };
                case null {
                    investorInvestments.put(investorId, [investment]);
                };
            };
        };

        public func getInvestorInvestments(investorId : InvestorTypes.InvestorId) : [InvestorTypes.InvestorInvestment] {
            switch (investorInvestments.get(investorId)) {
                case (?investments) { investments };
                case null { [] };
            };
        };

        public func updateInvestorInvestment(
            investorId : InvestorTypes.InvestorId,
            investmentId : Nat,
            updatedInvestment : InvestorTypes.InvestorInvestment,
        ) {
            switch (investorInvestments.get(investorId)) {
                case (?investments) {
                    let updatedInvestments = Array.map<InvestorTypes.InvestorInvestment, InvestorTypes.InvestorInvestment>(
                        investments,
                        func(inv) {
                            if (inv.investmentId == investmentId) {
                                updatedInvestment;
                            } else {
                                inv;
                            };
                        },
                    );
                    investorInvestments.put(investorId, updatedInvestments);
                };
                case null {};
            };
        };

        // Get investors by status
        public func getInvestorsByStatus(status : InvestorTypes.InvestorStatus) : [InvestorTypes.InvestorProfile] {
            let allInvestors = Iter.toArray(investors.vals());
            Array.filter(
                allInvestors,
                func(investor : InvestorTypes.InvestorProfile) : Bool {
                    investor.status == status;
                },
            );
        };

        // For stable storage during upgrades
        public func getEntries() : [(InvestorTypes.InvestorId, InvestorTypes.InvestorProfile)] {
            Iter.toArray(investors.entries());
        };

        public func getEmailEntries() : [(Text, InvestorTypes.InvestorId)] {
            Iter.toArray(emailToInvestor.entries());
        };

        public func getInvestmentEntries() : [(InvestorTypes.InvestorId, [InvestorTypes.InvestorInvestment])] {
            Iter.toArray(investorInvestments.entries());
        };

        public func initFromStable(
            investorEntries : [(InvestorTypes.InvestorId, InvestorTypes.InvestorProfile)],
            emailEntries : [(Text, InvestorTypes.InvestorId)],
            investmentEntries : [(InvestorTypes.InvestorId, [InvestorTypes.InvestorInvestment])],
        ) {
            investors := HashMap.fromIter(investorEntries.vals(), investorEntries.size(), Principal.equal, Principal.hash);
            emailToInvestor := HashMap.fromIter(emailEntries.vals(), emailEntries.size(), Text.equal, Text.hash);
            investorInvestments := HashMap.fromIter(investmentEntries.vals(), investmentEntries.size(), Principal.equal, Principal.hash);
        };

        // Statistics helper functions
        public func getInvestorCount() : Nat {
            investors.size();
        };

        public func getTotalInvestmentVolume() : Nat {
            let allInvestors = Iter.toArray(investors.vals());
            Array.foldLeft<InvestorTypes.InvestorProfile, Nat>(
                allInvestors,
                0,
                func(acc, investor) {
                    acc + investor.totalInvestmentAmount;
                },
            );
        };
    };
};
