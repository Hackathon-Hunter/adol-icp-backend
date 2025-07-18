import Map "mo:base/HashMap";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import FounderTypes "../types/FounderTypes";

module FounderStorage {

    type Founder = FounderTypes.Founder;

    public class FounderStore() {

        // Storage for founders
        private var foundersEntries : [(Text, Founder)] = [];
        private var founders = Map.fromIter<Text, Founder>(foundersEntries.vals(), foundersEntries.size(), Text.equal, Text.hash);

        // Counter for generating founder IDs
        private var founderCounter : Nat = 0;

        // System functions for upgrades
        public func preupgrade() : [(Text, Founder)] {
            Iter.toArray(founders.entries());
        };

        public func postupgrade(entries : [(Text, Founder)]) {
            founders := Map.fromIter<Text, Founder>(entries.vals(), entries.size(), Text.equal, Text.hash);
        };

        // Generate unique founder ID
        public func generateFounderId() : Text {
            founderCounter += 1;
            "FARMER-" # Nat.toText(founderCounter);
        };

        // Store founder
        public func putFounder(founderId : Text, founder : Founder) {
            founders.put(founderId, founder);
        };

        // Get founder by ID
        public func getFounder(founderId : Text) : ?Founder {
            founders.get(founderId);
        };

        // Get founder by email
        public func getFounderByEmail(email : Text) : ?Founder {
            for ((_, founder) in founders.entries()) {
                if (founder.email == email) {
                    return ?founder;
                };
            };
            null;
        };

        // Get founder by principal
        public func getFounderByPrincipal(principal : Principal) : ?Founder {
            for ((_, founder) in founders.entries()) {
                if (founder.principal == principal) {
                    return ?founder;
                };
            };
            null;
        };

        // Check if email exists
        public func emailExists(email : Text) : Bool {
            switch (getFounderByEmail(email)) {
                case null { false };
                case (?_) { true };
            };
        };

        // Get all founders
        public func getAllFounders() : [Founder] {
            founders.vals() |> Iter.toArray(_);
        };

        // Get founder count
        public func getFounderCount() : Nat {
            founders.size();
        };

        // Update founder
        public func updateFounder(founderId : Text, founder : Founder) : Bool {
            switch (founders.get(founderId)) {
                case null { false };
                case (?_) {
                    founders.put(founderId, founder);
                    true;
                };
            };
        };

        // Delete founder
        public func deleteFounder(founderId : Text) : Bool {
            switch (founders.remove(founderId)) {
                case null { false };
                case (?_) { true };
            };
        };
    };
};
