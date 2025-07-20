import Time "mo:base/Time";
import Principal "mo:base/Principal";
import InvestorTypes "../types/InvestorTypes";
import InvestorValidation "../utils/InvestorValidation";
import InvestorStorage "../storage/InvestorStorage";

module InvestorService {

    type Investor = InvestorTypes.Investor;
    type InvestorRegistrationRequest = InvestorTypes.InvestorRegistrationRequest;
    type RegistrationResult = InvestorTypes.RegistrationResult;
    type UpdateResult = InvestorTypes.UpdateResult;

    public class InvestorManager() {

        private let storage = InvestorStorage.InvestorStore();

        // System functions for upgrades
        public func preupgrade() : [(Text, Investor)] {
            storage.preupgrade();
        };

        public func postupgrade(entries : [(Text, Investor)]) {
            storage.postupgrade(entries);
        };

        // Register new investor
        public func registerInvestor(request : InvestorRegistrationRequest, caller : Principal) : RegistrationResult {
            // Validate input
            switch (InvestorValidation.validateRegistrationRequest(request)) {
                case (#err(error)) { return #err(error) };
                case (#ok(())) {};
            };

            // Check if email already exists
            if (storage.emailExists(request.email)) {
                return #err("Email already registered");
            };

            // Create new investor
            let investorId = storage.generateInvestorId();
            let newInvestor : Investor = {
                id = investorId;
                fullName = request.fullName;
                email = request.email;
                registrationDate = Time.now();
                isVerified = false; // New investors start unverified
                principal = caller;
            };

            // Store investor
            storage.putInvestor(investorId, newInvestor);

            #ok(newInvestor);
        };

        // Get investor by ID
        public func getInvestor(investorId : Text) : ?Investor {
            storage.getInvestor(investorId);
        };

        // Get investor by email
        public func getInvestorByEmail(email : Text) : ?Investor {
            storage.getInvestorByEmail(email);
        };

        // Get investor by principal
        public func getInvestorByPrincipal(principal : Principal) : ?Investor {
            storage.getInvestorByPrincipal(principal);
        };

        // Update investor verification status
        public func updateInvestorVerification(investorId : Text, isVerified : Bool) : UpdateResult {
            switch (storage.getInvestor(investorId)) {
                case null { #err("Investor not found") };
                case (?investor) {
                    let updatedInvestor : Investor = {
                        id = investor.id;
                        fullName = investor.fullName;
                        email = investor.email;
                        registrationDate = investor.registrationDate;
                        isVerified = isVerified;
                        principal = investor.principal;
                    };

                    if (storage.updateInvestor(investorId, updatedInvestor)) {
                        #ok(());
                    } else {
                        #err("Failed to update investor");
                    };
                };
            };
        };

        // Update investor profile
        public func updateInvestorProfile(investorId : Text, request : InvestorRegistrationRequest, caller : Principal) : UpdateResult {
            switch (storage.getInvestor(investorId)) {
                case null { #err("Investor not found") };
                case (?investor) {
                    // Check if caller is the investor
                    if (investor.principal != caller) {
                        return #err("Unauthorized: Can only update own profile");
                    };

                    // Validate new data
                    switch (InvestorValidation.validateRegistrationRequest(request)) {
                        case (#err(error)) { return #err(error) };
                        case (#ok(())) {};
                    };

                    // Check if new email already exists (but allow same email)
                    if (request.email != investor.email and storage.emailExists(request.email)) {
                        return #err("Email already registered");
                    };

                    let updatedInvestor : Investor = {
                        id = investor.id;
                        fullName = request.fullName;
                        email = request.email;
                        registrationDate = investor.registrationDate;
                        isVerified = investor.isVerified; // Keep verification status
                        principal = investor.principal;
                    };

                    if (storage.updateInvestor(investorId, updatedInvestor)) {
                        #ok(());
                    } else {
                        #err("Failed to update investor profile");
                    };
                };
            };
        };

        // Get all investors (admin function)
        public func getAllInvestors() : [Investor] {
            storage.getAllInvestors();
        };

        // Get investor count
        public func getInvestorCount() : Nat {
            storage.getInvestorCount();
        };

        // Check if investor exists by email
        public func investorExistsByEmail(email : Text) : Bool {
            storage.emailExists(email);
        };
    };
};
