import Time "mo:base/Time";
import Principal "mo:base/Principal";

module {
    public type UserId = Principal;
    
    public type User = {
        id: UserId;
        email: Text;
        name: Text;
        phone: ?Text;
        address: ?Address;
        icpBalance: Nat;
        createdAt: Int;
        updatedAt: Int;
        isActive: Bool;
    };
    
    public type Address = {
        street: Text;
        city: Text;
        state: Text;
        zipCode: Text;
        country: Text;
    };
    
    public type UserRegistration = {
        email: Text;
        name: Text;
        phone: ?Text;
        address: ?Address;
    };
    
    public type UserUpdate = {
        name: ?Text;
        phone: ?Text;
        address: ?Address;
    };
    
    public type UserError = {
        #UserNotFound;
        #UserAlreadyExists;
        #InvalidEmail;
        #InvalidInput: Text;
        #Unauthorized;
    };
}
