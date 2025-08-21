import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import UserTypes "../types/UserTypes";

module {
  public type UserStorage = {
    users : HashMap.HashMap<Principal, UserTypes.User>;
    usersByEmail : HashMap.HashMap<Text, Principal>;
  };

  public func init() : UserStorage {
    {
      users = HashMap.HashMap<Principal, UserTypes.User>(0, Principal.equal, Principal.hash);
      usersByEmail = HashMap.HashMap<Text, Principal>(0, Text.equal, Text.hash);
    };
  };

  public func createUser(
    storage : UserStorage,
    userId : Principal,
    registration : UserTypes.UserRegistration,
  ) : Result.Result<UserTypes.User, UserTypes.UserError> {
    // Check if user already exists
    switch (storage.users.get(userId)) {
      case (?_) { #err(#UserAlreadyExists) };
      case null {
        // Check if email is already used
        switch (storage.usersByEmail.get(registration.email)) {
          case (?_) { #err(#UserAlreadyExists) };
          case null {
            let now = Time.now();
            let user : UserTypes.User = {
              id = userId;
              email = registration.email;
              name = registration.name;
              phone = registration.phone;
              address = registration.address;
              icpBalance = 0;
              createdAt = now;
              updatedAt = now;
              isActive = true;
            };

            storage.users.put(userId, user);
            storage.usersByEmail.put(registration.email, userId);
            #ok(user);
          };
        };
      };
    };
  };

  public func getUser(storage : UserStorage, userId : Principal) : ?UserTypes.User {
    storage.users.get(userId);
  };

  public func updateUser(
    storage : UserStorage,
    userId : Principal,
    update : UserTypes.UserUpdate,
  ) : Result.Result<UserTypes.User, UserTypes.UserError> {
    switch (storage.users.get(userId)) {
      case null { #err(#UserNotFound) };
      case (?user) {
        let updatedUser : UserTypes.User = {
          user with
          name = switch (update.name) {
            case (?name) name;
            case null user.name;
          };
          phone = switch (update.phone) {
            case (?phone) ?phone;
            case null user.phone;
          };
          address = switch (update.address) {
            case (?address) ?address;
            case null user.address;
          };
          updatedAt = Time.now();
        };

        storage.users.put(userId, updatedUser);
        #ok(updatedUser);
      };
    };
  };

  public func updateUserBalance(
    storage : UserStorage,
    userId : Principal,
    newBalance : Nat,
  ) : Result.Result<UserTypes.User, UserTypes.UserError> {
    switch (storage.users.get(userId)) {
      case null { #err(#UserNotFound) };
      case (?user) {
        let updatedUser : UserTypes.User = {
          user with
          icpBalance = newBalance;
          updatedAt = Time.now();
        };

        storage.users.put(userId, updatedUser);
        #ok(updatedUser);
      };
    };
  };

  public func getAllUsers(storage : UserStorage) : [UserTypes.User] {
    storage.users.vals() |> Iter.toArray(_);
  };
};
