import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Int "mo:base/Int";
import UserTypes "../types/UserTypes";
import UserStorage "../storage/UserStorage";

module {
    public class UserService(storage: UserStorage.UserStorage) {
        
        public func registerUser(
            userId: Principal,
            registration: UserTypes.UserRegistration
        ) : Result.Result<UserTypes.User, UserTypes.UserError> {
            // Validate email format
            if (not isValidEmail(registration.email)) {
                return #err(#InvalidEmail);
            };
            
            // Validate required fields
            if (registration.name == "" or registration.email == "") {
                return #err(#InvalidInput("Name and email are required"));
            };
            
            UserStorage.createUser(storage, userId, registration)
        };
        
        public func getUser(userId: Principal) : Result.Result<UserTypes.User, UserTypes.UserError> {
            switch (UserStorage.getUser(storage, userId)) {
                case null { #err(#UserNotFound) };
                case (?user) { #ok(user) };
            }
        };
        
        public func updateUser(
            userId: Principal,
            update: UserTypes.UserUpdate
        ) : Result.Result<UserTypes.User, UserTypes.UserError> {
            UserStorage.updateUser(storage, userId, update)
        };
        
        public func topUpBalance(
            userId: Principal,
            amount: Nat
        ) : Result.Result<UserTypes.User, UserTypes.UserError> {
            if (amount == 0) {
                return #err(#InvalidInput("Amount must be greater than 0"));
            };
            
            switch (UserStorage.getUser(storage, userId)) {
                case null { #err(#UserNotFound) };
                case (?user) {
                    let newBalance = user.icpBalance + amount;
                    UserStorage.updateUserBalance(storage, userId, newBalance)
                };
            }
        };
        
        public func deductBalance(
            userId: Principal,
            amount: Nat
        ) : Result.Result<UserTypes.User, UserTypes.UserError> {
            switch (UserStorage.getUser(storage, userId)) {
                case null { #err(#UserNotFound) };
                case (?user) {
                    if (user.icpBalance < amount) {
                        return #err(#InvalidInput("Insufficient balance"));
                    };
                    
                    let newBalance = Int.abs(user.icpBalance - amount);
                    UserStorage.updateUserBalance(storage, userId, newBalance)
                };
            }
        };
        
        public func getUserBalance(userId: Principal) : Result.Result<Nat, UserTypes.UserError> {
            switch (UserStorage.getUser(storage, userId)) {
                case null { #err(#UserNotFound) };
                case (?user) { #ok(user.icpBalance) };
            }
        };
        
        public func getAllUsers() : [UserTypes.User] {
            UserStorage.getAllUsers(storage)
        };
        
        private func isValidEmail(email: Text) : Bool {
            // Simple email validation - contains @ and .
            Text.contains(email, #char '@') and Text.contains(email, #char '.')
        };
    }
}
