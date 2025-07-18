import Time "mo:base/Time";
import Principal "mo:base/Principal";
import FounderTypes "../types/FounderTypes";
import FounderValidation "../utils/FounderValidation";
import FounderStorage "../storage/FounderStorage";

module FounderService {

    type Founder = FounderTypes.Founder;
    type FounderRegistrationRequest = FounderTypes.FounderRegistrationRequest;
    type RegistrationResult = FounderTypes.RegistrationResult;
    type UpdateResult = FounderTypes.UpdateResult;

    public class FounderManager() {

        private let storage = FounderStorage.FounderStore();

        // System functions for upgrades
        public func preupgrade() : [(Text, Founder)] {
            storage.preupgrade();
        };

        public func postupgrade(entries : [(Text, Founder)]) {
            storage.postupgrade(entries);
        };

        // Register new founder
        public func registerFounder(request : FounderRegistrationRequest, caller : Principal) : RegistrationResult {
            // Validate input
            switch (FounderValidation.validateRegistrationRequest(request)) {
                case (#err(error)) { return #err(error) };
                case (#ok(())) {};
            };

            // Check if email already exists
            if (storage.emailExists(request.email)) {
                return #err("Email already registered");
            };

            // Create new founder
            let founderId = storage.generateFounderId();
            let newFounder : Founder = {
                id = founderId;
                fullName = request.fullName;
                email = request.email;
                phoneNumber = request.phoneNumber;
                governmentId = request.governmentId;
                registrationDate = Time.now();
                isVerified = false;
                principal = caller;
            };

            // Store founder
            storage.putFounder(founderId, newFounder);

            #ok(newFounder);
        };

        // Get founder by ID
        public func getFounder(founderId : Text) : ?Founder {
            storage.getFounder(founderId);
        };

        // Get founder by email
        public func getFounderByEmail(email : Text) : ?Founder {
            storage.getFounderByEmail(email);
        };

        // Get founder by principal
        public func getFounderByPrincipal(principal : Principal) : ?Founder {
            storage.getFounderByPrincipal(principal);
        };

        // Update founder verification status
        public func updateFounderVerification(founderId : Text, isVerified : Bool) : UpdateResult {
            switch (storage.getFounder(founderId)) {
                case null { #err("Founder not found") };
                case (?founder) {
                    let updatedFounder : Founder = {
                        id = founder.id;
                        fullName = founder.fullName;
                        email = founder.email;
                        phoneNumber = founder.phoneNumber;
                        governmentId = founder.governmentId;
                        registrationDate = founder.registrationDate;
                        isVerified = isVerified;
                        principal = founder.principal;
                    };

                    if (storage.updateFounder(founderId, updatedFounder)) {
                        #ok(());
                    } else {
                        #err("Failed to update founder");
                    };
                };
            };
        };

        // Update founder profile
        public func updateFounderProfile(founderId : Text, request : FounderRegistrationRequest, caller : Principal) : UpdateResult {
            switch (storage.getFounder(founderId)) {
                case null { #err("Founder not found") };
                case (?founder) {
                    // Check if caller is the founder
                    if (founder.principal != caller) {
                        return #err("Unauthorized: Can only update own profile");
                    };

                    // Validate new data
                    switch (FounderValidation.validateRegistrationRequest(request)) {
                        case (#err(error)) { return #err(error) };
                        case (#ok(())) {};
                    };

                    // Check if new email already exists (but allow same email)
                    if (request.email != founder.email and storage.emailExists(request.email)) {
                        return #err("Email already registered");
                    };

                    let updatedFounder : Founder = {
                        id = founder.id;
                        fullName = request.fullName;
                        email = request.email;
                        phoneNumber = request.phoneNumber;
                        governmentId = request.governmentId;
                        registrationDate = founder.registrationDate;
                        isVerified = founder.isVerified; // Keep verification status
                        principal = founder.principal;
                    };

                    if (storage.updateFounder(founderId, updatedFounder)) {
                        #ok(());
                    } else {
                        #err("Failed to update founder profile");
                    };
                };
            };
        };

        // Get all founders (admin function)
        public func getAllFounders() : [Founder] {
            storage.getAllFounders();
        };

        // Get founder count
        public func getFounderCount() : Nat {
            storage.getFounderCount();
        };

        // Check if founder exists by email
        public func founderExistsByEmail(email : Text) : Bool {
            storage.emailExists(email);
        };
    };
};
