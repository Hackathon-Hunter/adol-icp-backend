import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import FarmerTypes "../types/FarmerTypes";

module {

    public class FarmerStorage() {

        // Storage maps
        private var farmers = HashMap.HashMap<FarmerTypes.FarmerId, FarmerTypes.FarmerProfile>(
            0,
            Principal.equal,
            Principal.hash,
        );

        private var emailToFarmer = HashMap.HashMap<Text, FarmerTypes.FarmerId>(
            0,
            Text.equal,
            Text.hash,
        );

        private var governmentIdToFarmer = HashMap.HashMap<Text, FarmerTypes.FarmerId>(
            0,
            Text.equal,
            Text.hash,
        );

        // Storage operations
        public func putFarmer(farmerId : FarmerTypes.FarmerId, farmer : FarmerTypes.FarmerProfile) {
            farmers.put(farmerId, farmer);
            emailToFarmer.put(farmer.email, farmerId);
            governmentIdToFarmer.put(farmer.governmentId, farmerId);
        };

        public func getFarmer(farmerId : FarmerTypes.FarmerId) : ?FarmerTypes.FarmerProfile {
            farmers.get(farmerId);
        };

        public func getFarmerByEmail(email : Text) : ?FarmerTypes.FarmerId {
            emailToFarmer.get(email);
        };

        public func getFarmerByGovernmentId(govId : Text) : ?FarmerTypes.FarmerId {
            governmentIdToFarmer.get(govId);
        };

        public func updateFarmer(farmerId : FarmerTypes.FarmerId, farmer : FarmerTypes.FarmerProfile) {
            // Remove old email mapping if email changed
            switch (farmers.get(farmerId)) {
                case (?oldFarmer) {
                    if (oldFarmer.email != farmer.email) {
                        emailToFarmer.delete(oldFarmer.email);
                        emailToFarmer.put(farmer.email, farmerId);
                    };
                };
                case null {};
            };

            farmers.put(farmerId, farmer);
        };

        public func getAllFarmers() : [FarmerTypes.FarmerProfile] {
            Iter.toArray(farmers.vals());
        };

        public func deleteFarmer(farmerId : FarmerTypes.FarmerId) {
            switch (farmers.get(farmerId)) {
                case (?farmer) {
                    emailToFarmer.delete(farmer.email);
                    governmentIdToFarmer.delete(farmer.governmentId);
                    farmers.delete(farmerId);
                };
                case null {};
            };
        };

        // For stable storage during upgrades
        public func getEntries() : [(FarmerTypes.FarmerId, FarmerTypes.FarmerProfile)] {
            Iter.toArray(farmers.entries());
        };

        public func getEmailEntries() : [(Text, FarmerTypes.FarmerId)] {
            Iter.toArray(emailToFarmer.entries());
        };

        public func getGovernmentIdEntries() : [(Text, FarmerTypes.FarmerId)] {
            Iter.toArray(governmentIdToFarmer.entries());
        };

        public func initFromStable(
            farmerEntries : [(FarmerTypes.FarmerId, FarmerTypes.FarmerProfile)],
            emailEntries : [(Text, FarmerTypes.FarmerId)],
            govIdEntries : [(Text, FarmerTypes.FarmerId)],
        ) {
            farmers := HashMap.fromIter(farmerEntries.vals(), farmerEntries.size(), Principal.equal, Principal.hash);
            emailToFarmer := HashMap.fromIter(emailEntries.vals(), emailEntries.size(), Text.equal, Text.hash);
            governmentIdToFarmer := HashMap.fromIter(govIdEntries.vals(), govIdEntries.size(), Text.equal, Text.hash);
        };
    };
};
