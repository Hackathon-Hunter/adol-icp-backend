import Principal "mo:base/Principal";
import Result "mo:base/Result";

module InvestorTypes {

    // Investor data structure
    public type Investor = {
        id : Text;
        fullName : Text;
        email : Text;
        registrationDate : Int;
        isVerified : Bool;
        principal : Principal;
    };

    // Registration request type
    public type InvestorRegistrationRequest = {
        fullName : Text;
        email : Text;
    };

    // Response types
    public type RegistrationResult = Result.Result<Investor, Text>;
    public type UpdateResult = Result.Result<(), Text>;

    // Validation result
    public type ValidationResult = Result.Result<(), Text>;

    // Error types
    public type InvestorError = {
        #NotFound;
        #AlreadyExists;
        #ValidationFailed : Text;
        #Unauthorized;
    };
};
