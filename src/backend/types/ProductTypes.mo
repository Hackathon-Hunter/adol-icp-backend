import Time "mo:base/Time";
import Principal "mo:base/Principal";

module {
    public type ProductId = Nat;
    public type CategoryId = Nat;
    
    public type Product = {
        id: ProductId;
        name: Text;
        description: Text;
        price: Nat; // Price in ICP (smallest unit)
        categoryId: CategoryId;
        imageUrl: ?Text;
        stock: Nat;
        isActive: Bool;
        createdAt: Int;
        updatedAt: Int;
        createdBy: Principal;
    };
    
    public type Category = {
        id: CategoryId;
        name: Text;
        description: Text;
        isActive: Bool;
        createdAt: Int;
    };
    
    public type ProductInput = {
        name: Text;
        description: Text;
        price: Nat;
        categoryId: CategoryId;
        imageUrl: ?Text;
        stock: Nat;
    };
    
    public type ProductUpdate = {
        name: ?Text;
        description: ?Text;
        price: ?Nat;
        categoryId: ?CategoryId;
        imageUrl: ?Text;
        stock: ?Nat;
        isActive: ?Bool;
    };
    
    public type CategoryInput = {
        name: Text;
        description: Text;
    };
    
    public type ProductError = {
        #ProductNotFound;
        #CategoryNotFound;
        #InvalidInput: Text;
        #InsufficientStock;
        #Unauthorized;
    };
}
