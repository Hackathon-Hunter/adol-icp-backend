import Text "mo:base/Text";

module {

    public func isValidEmail(email : Text) : Bool {
        // Basic email validation
        let hasAtSymbol = Text.contains(email, #char '@');
        let hasDot = Text.contains(email, #char '.');
        let minLength = Text.size(email) >= 5;
        let maxLength = Text.size(email) <= 100;

        hasAtSymbol and hasDot and minLength and maxLength;
    };

    public func isValidPhone(phone : Text) : Bool {
        let size = Text.size(phone);
        size >= 10 and size <= 15;
    };

    public func isValidName(name : Text) : Bool {
        let size = Text.size(name);
        size >= 2 and size <= 100;
    };

    public func isValidGovernmentId(govId : Text) : Bool {
        let size = Text.size(govId);
        size >= 5 and size <= 50;
    };

    public func isValidFileName(fileName : Text) : Bool {
        let size = Text.size(fileName);
        size > 0 and size <= 255;
    };

    public func isValidFileHash(fileHash : Text) : Bool {
        let size = Text.size(fileHash);
        size >= 32 and size <= 128 // Assuming SHA-256 or similar
    };
};
