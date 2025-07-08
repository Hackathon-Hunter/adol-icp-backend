import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import InvestmentTypes "../types/InvestmentTypes";

module {

    public class InvestmentStorage() {

        // Storage maps
        private var investments = HashMap.HashMap<InvestmentTypes.InvestmentId, InvestmentTypes.InvestmentProject>(
            0,
            Nat.equal,
            Hash.hash,
        );

        private var farmerInvestments = HashMap.HashMap<InvestmentTypes.FarmerId, [InvestmentTypes.InvestmentId]>(
            0,
            Principal.equal,
            Principal.hash,
        );

        private var verificationTrackers = HashMap.HashMap<InvestmentTypes.InvestmentId, InvestmentTypes.VerificationTracker>(
            0,
            Nat.equal,
            Hash.hash,
        );

        // Investment operations
        public func putInvestment(investmentId : InvestmentTypes.InvestmentId, investment : InvestmentTypes.InvestmentProject) {
            investments.put(investmentId, investment);

            // Update farmer's investments list
            switch (farmerInvestments.get(investment.farmerId)) {
                case (?existingInvestments) {
                    let updatedInvestments = Array.append<InvestmentTypes.InvestmentId>(existingInvestments, [investmentId]);
                    farmerInvestments.put(investment.farmerId, updatedInvestments);
                };
                case null {
                    farmerInvestments.put(investment.farmerId, [investmentId]);
                };
            };
        };

        public func getInvestment(investmentId : InvestmentTypes.InvestmentId) : ?InvestmentTypes.InvestmentProject {
            investments.get(investmentId);
        };

        public func updateInvestment(investmentId : InvestmentTypes.InvestmentId, investment : InvestmentTypes.InvestmentProject) {
            investments.put(investmentId, investment);
        };

        public func getAllInvestments() : [InvestmentTypes.InvestmentProject] {
            Iter.toArray(investments.vals());
        };

        public func getInvestmentsByFarmer(farmerId : InvestmentTypes.FarmerId) : [InvestmentTypes.InvestmentProject] {
            switch (farmerInvestments.get(farmerId)) {
                case (?investmentIds) {
                    Array.mapFilter<InvestmentTypes.InvestmentId, InvestmentTypes.InvestmentProject>(
                        investmentIds,
                        func(id) { investments.get(id) },
                    );
                };
                case null { [] };
            };
        };

        public func getInvestmentsByStatus(status : InvestmentTypes.InvestmentStatus) : [InvestmentTypes.InvestmentProject] {
            let allInvestments = Iter.toArray(investments.vals());
            Array.filter(
                allInvestments,
                func(investment : InvestmentTypes.InvestmentProject) : Bool {
                    investment.status == status;
                },
            );
        };

        public func deleteInvestment(investmentId : InvestmentTypes.InvestmentId) {
            switch (investments.get(investmentId)) {
                case (?investment) {
                    // Remove from farmer's investments list
                    switch (farmerInvestments.get(investment.farmerId)) {
                        case (?investmentIds) {
                            let filteredIds = Array.filter<InvestmentTypes.InvestmentId>(
                                investmentIds,
                                func(id) { id != investmentId },
                            );
                            farmerInvestments.put(investment.farmerId, filteredIds);
                        };
                        case null {};
                    };

                    investments.delete(investmentId);
                    verificationTrackers.delete(investmentId);
                };
                case null {};
            };
        };

        // Verification tracker operations
        public func putVerificationTracker(investmentId : InvestmentTypes.InvestmentId, tracker : InvestmentTypes.VerificationTracker) {
            verificationTrackers.put(investmentId, tracker);
        };

        public func getVerificationTracker(investmentId : InvestmentTypes.InvestmentId) : ?InvestmentTypes.VerificationTracker {
            verificationTrackers.get(investmentId);
        };

        public func updateVerificationTracker(investmentId : InvestmentTypes.InvestmentId, tracker : InvestmentTypes.VerificationTracker) {
            verificationTrackers.put(investmentId, tracker);
        };

        // Filter investments by crop type
        public func getInvestmentsByCrop(cropType : InvestmentTypes.CropType) : [InvestmentTypes.InvestmentProject] {
            let allInvestments = Iter.toArray(investments.vals());
            Array.filter(
                allInvestments,
                func(investment : InvestmentTypes.InvestmentProject) : Bool {
                    investment.farmInfo.cropType == cropType;
                },
            );
        };

        // Filter investments by location
        public func getInvestmentsByLocation(country : Text, state : ?Text) : [InvestmentTypes.InvestmentProject] {
            let allInvestments = Iter.toArray(investments.vals());
            Array.filter(
                allInvestments,
                func(investment : InvestmentTypes.InvestmentProject) : Bool {
                    if (investment.farmInfo.country != country) {
                        return false;
                    };

                    switch (state) {
                        case (?stateFilter) {
                            investment.farmInfo.stateProvince == stateFilter;
                        };
                        case null { true };
                    };
                },
            );
        };

        // Get investments requiring funding within range
        public func getInvestmentsByFundingRange(minAmount : Nat, maxAmount : Nat) : [InvestmentTypes.InvestmentProject] {
            let allInvestments = Iter.toArray(investments.vals());
            Array.filter(
                allInvestments,
                func(investment : InvestmentTypes.InvestmentProject) : Bool {
                    let funding = investment.farmInfo.fundingRequired;
                    funding >= minAmount and funding <= maxAmount;
                },
            );
        };

        // Get recent investments (by creation date)
        public func getRecentInvestments(limit : Nat) : [InvestmentTypes.InvestmentProject] {
            let allInvestments = Iter.toArray(investments.vals());

            // Sort by creation date (newest first)
            let sorted = Array.sort<InvestmentTypes.InvestmentProject>(
                allInvestments,
                func(a, b) {
                    if (a.createdAt > b.createdAt) { #less } else if (a.createdAt < b.createdAt) {
                        #greater;
                    } else { #equal };
                },
            );

            // Return first 'limit' items
            if (sorted.size() <= limit) {
                sorted;
            } else {
                Array.tabulate<InvestmentTypes.InvestmentProject>(limit, func(i) { sorted[i] });
            };
        };

        // For stable storage during upgrades
        public func getInvestmentEntries() : [(InvestmentTypes.InvestmentId, InvestmentTypes.InvestmentProject)] {
            Iter.toArray(investments.entries());
        };

        public func getFarmerInvestmentEntries() : [(InvestmentTypes.FarmerId, [InvestmentTypes.InvestmentId])] {
            Iter.toArray(farmerInvestments.entries());
        };

        public func getVerificationTrackerEntries() : [(InvestmentTypes.InvestmentId, InvestmentTypes.VerificationTracker)] {
            Iter.toArray(verificationTrackers.entries());
        };

        public func initFromStable(
            investmentEntries : [(InvestmentTypes.InvestmentId, InvestmentTypes.InvestmentProject)],
            farmerInvestmentEntries : [(InvestmentTypes.FarmerId, [InvestmentTypes.InvestmentId])],
            trackerEntries : [(InvestmentTypes.InvestmentId, InvestmentTypes.VerificationTracker)],
        ) {
            investments := HashMap.fromIter(investmentEntries.vals(), investmentEntries.size(), Nat.equal, Hash.hash);
            farmerInvestments := HashMap.fromIter(farmerInvestmentEntries.vals(), farmerInvestmentEntries.size(), Principal.equal, Principal.hash);
            verificationTrackers := HashMap.fromIter(trackerEntries.vals(), trackerEntries.size(), Nat.equal, Hash.hash);
        };

        // Statistics helper functions
        public func getInvestmentCount() : Nat {
            investments.size();
        };

        public func getFarmerCount() : Nat {
            farmerInvestments.size();
        };

        public func getTotalFundingRequested() : Nat {
            let allInvestments = Iter.toArray(investments.vals());
            Array.foldLeft<InvestmentTypes.InvestmentProject, Nat>(
                allInvestments,
                0,
                func(acc, investment) {
                    acc + investment.farmInfo.fundingRequired;
                },
            );
        };
    };
};
