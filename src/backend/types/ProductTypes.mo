import Time "mo:base/Time";
import Principal "mo:base/Principal";

module {
    public type ProductId = Text;  // Changed from Nat to Text for SKU
    public type CategoryId = Nat;
    
    public type Product = {
        id: ProductId;  // Now Text-based SKU
        name: Text;  // item_name
        description: Text;
        price: Nat; // listing_price in smallest unit
        targetPrice: ?Nat; // suggested_target_price
        minimumPrice: ?Nat; // suggested_minimum_price
        categoryId: CategoryId;
        condition: Text; // product condition
        imageBase64: ?Text; // Base64 encoded image data (data:image/jpeg;base64,...)
        stock: Nat;
        isActive: Bool;
        createdAt: Int;
        updatedAt: Int;
        createdBy: Principal;
        keySellingPoints: [Text]; // key_selling_points
        knownFlaws: Text; // known_flaws or potential_flaws
        reasonForSelling: Text; // reason_for_selling
        pickupDeliveryInfo: Text; // pickup_delivery_info
    };
    
    public type Category = {
        id: CategoryId;
        name: Text;
        code: Text;  // Short code for SKU generation like "ELC", "FSH", "HOM"
        description: Text;
        isActive: Bool;
        createdAt: Int;
    };
    
    public type ProductInput = {
        name: Text; // item_name
        description: Text;
        price: Nat; // listing_price
        targetPrice: ?Nat; // suggested_target_price
        minimumPrice: ?Nat; // suggested_minimum_price
        categoryId: CategoryId;
        condition: Text; // product condition
        imageBase64: ?Text; // Base64 encoded image data (data:image/jpeg;base64,...)
        stock: Nat;
        keySellingPoints: [Text]; // key_selling_points
        knownFlaws: Text; // known_flaws
        reasonForSelling: Text; // reason_for_selling
        pickupDeliveryInfo: Text; // pickup_delivery_info
    };
    
    public type ProductUpdate = {
        name: ?Text;
        description: ?Text;
        price: ?Nat;
        targetPrice: ?Nat;
        minimumPrice: ?Nat;
        categoryId: ?CategoryId;
        condition: ?Text;
        imageBase64: ?Text; // Base64 encoded image data
        stock: ?Nat;
        isActive: ?Bool;
        keySellingPoints: ?[Text];
        knownFlaws: ?Text;
        reasonForSelling: ?Text;
        pickupDeliveryInfo: ?Text;
    };
    
    public type CategoryInput = {
        name: Text;
        code: Text;  // Short code like "ELC", "FSH", "HOM"
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
