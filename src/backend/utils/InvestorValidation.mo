import Text "mo:base/Text";
import InvestorTypes "../types/InvestorTypes";

module InvestorValidation {

    type InvestorRegistrationRequest = InvestorTypes.InvestorRegistrationRequest;
    type ValidationResult = InvestorTypes.ValidationResult;

    // Validate full name
    public func validateFullName(name : Text) : ValidationResult {
        if (Text.size(name) < 2) {
            return #err("Full name must be at least 2 characters");
        };
        if (Text.size(name) > 100) {
            return #err("Full name must be less than 100 characters");
        };
        #ok(());
    };

    // Validate email format
    public func validateEmail(email : Text) : ValidationResult {
        if (Text.size(email) < 5) {
            return #err("Email must be at least 5 characters");
        };
        if (Text.size(email) > 254) {
            return #err("Email must be less than 254 characters");
        };
        if (not Text.contains(email, #text "@")) {
            return #err("Email must contain @ symbol");
        };
        if (not Text.contains(email, #text ".")) {
            return #err("Email must contain a domain");
        };
        #ok(());
    };

    // Validate complete registration request
    public func validateRegistrationRequest(request : InvestorRegistrationRequest) : ValidationResult {
        switch (validateFullName(request.fullName)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateEmail(request.email)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        #ok(());
    };
};
