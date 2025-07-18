import Principal "mo:base/Principal";
import Result "mo:base/Result";

module FounderTypes {

    // Founder data structure
    public type Founder = {
        id : Text;
        fullName : Text;
        email : Text;
        phoneNumber : Text;
        governmentId : Text;
        registrationDate : Int;
        isVerified : Bool;
        principal : Principal;
    };

    // Registration request type
    public type FounderRegistrationRequest = {
        fullName : Text;
        email : Text;
        phoneNumber : Text;
        governmentId : Text;
    };

    // Response types
    public type RegistrationResult = Result.Result<Founder, Text>;
    public type UpdateResult = Result.Result<(), Text>;

    // Validation result
    public type ValidationResult = Result.Result<(), Text>;

    // Error types
    public type FounderError = {
        #NotFound;
        #AlreadyExists;
        #ValidationFailed : Text;
        #Unauthorized;
    };
};
