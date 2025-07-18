import Text "mo:base/Text";
import FounderTypes "../types/FounderTypes";

module Validation {

    type FounderRegistrationRequest = FounderTypes.FounderRegistrationRequest;
    type ValidationResult = FounderTypes.ValidationResult;

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

    // Validate phone number
    public func validatePhoneNumber(phone : Text) : ValidationResult {
        if (Text.size(phone) < 8) {
            return #err("Phone number must be at least 8 characters");
        };
        if (Text.size(phone) > 20) {
            return #err("Phone number must be less than 20 characters");
        };
        #ok(());
    };

    // Validate government ID
    public func validateGovernmentId(govId : Text) : ValidationResult {
        if (Text.size(govId) < 5) {
            return #err("Government ID must be at least 5 characters");
        };
        if (Text.size(govId) > 50) {
            return #err("Government ID must be less than 50 characters");
        };
        #ok(());
    };

    // Validate complete registration request
    public func validateRegistrationRequest(request : FounderRegistrationRequest) : ValidationResult {
        switch (validateFullName(request.fullName)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateEmail(request.email)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validatePhoneNumber(request.phoneNumber)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateGovernmentId(request.governmentId)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        #ok(());
    };
};
