import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import ProductTypes "../types/ProductTypes";

module {
    public type ProductStorage = {
        products: HashMap.HashMap<ProductTypes.ProductId, ProductTypes.Product>;
        categories: HashMap.HashMap<ProductTypes.CategoryId, ProductTypes.Category>;
        categoryProductCounts: HashMap.HashMap<ProductTypes.CategoryId, Nat>; // Track product count per category for SKU generation
        var nextCategoryId: Nat;
    };
    
    public func init() : ProductStorage {
        {
            products = HashMap.HashMap<ProductTypes.ProductId, ProductTypes.Product>(0, Text.equal, Text.hash);
            categories = HashMap.HashMap<ProductTypes.CategoryId, ProductTypes.Category>(0, func(a: Nat, b: Nat) : Bool { a == b }, func(x: Nat) : Nat32 { Nat32.fromNat(x % (2**30)) });
            categoryProductCounts = HashMap.HashMap<ProductTypes.CategoryId, Nat>(0, func(a: Nat, b: Nat) : Bool { a == b }, func(x: Nat) : Nat32 { Nat32.fromNat(x % (2**30)) });
            var nextCategoryId = 1;
        }
    };
    
    // Category functions
    public func createCategory(
        storage: ProductStorage,
        input: ProductTypes.CategoryInput
    ) : ProductTypes.Category {
        let categoryId = storage.nextCategoryId;
        storage.nextCategoryId += 1;
        
        let category: ProductTypes.Category = {
            id = categoryId;
            name = input.name;
            code = input.code;
            description = input.description;
            isActive = true;
            createdAt = Time.now();
        };
        
        storage.categories.put(categoryId, category);
        category
    };
    
    public func getCategory(storage: ProductStorage, categoryId: ProductTypes.CategoryId) : ?ProductTypes.Category {
        storage.categories.get(categoryId)
    };
    
    public func getAllCategories(storage: ProductStorage) : [ProductTypes.Category] {
        storage.categories.vals() |> Iter.toArray(_)
    };
    
    // Product functions
    public func createProduct(
        storage: ProductStorage,
        input: ProductTypes.ProductInput,
        createdBy: Principal
    ) : Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
        // Check if category exists
        switch (storage.categories.get(input.categoryId)) {
            case null { #err(#CategoryNotFound) };
            case (?category) {
                if (not category.isActive) {
                    return #err(#CategoryNotFound);
                };
                
                // Generate SKU-based product ID
                let currentCount = switch (storage.categoryProductCounts.get(input.categoryId)) {
                    case null { 0 };
                    case (?count) { count };
                };
                let newCount = currentCount + 1;
                storage.categoryProductCounts.put(input.categoryId, newCount);
                
                // Create SKU: CategoryCode + 3-digit number (e.g., "ELC001")
                let productId = category.code # formatNumber(newCount);
                
                let product: ProductTypes.Product = {
                    id = productId;
                    name = input.name;
                    description = input.description;
                    price = input.price;
                    targetPrice = input.targetPrice;
                    minimumPrice = input.minimumPrice;
                    categoryId = input.categoryId;
                    condition = input.condition;
                    imageBase64 = input.imageBase64;
                    stock = input.stock;
                    isActive = true;
                    createdAt = Time.now();
                    updatedAt = Time.now();
                    createdBy = createdBy;
                    keySellingPoints = input.keySellingPoints;
                    knownFlaws = input.knownFlaws;
                    reasonForSelling = input.reasonForSelling;
                    pickupDeliveryInfo = input.pickupDeliveryInfo;
                };
                
                storage.products.put(productId, product);
                #ok(product)
            };
        };
    };

    // Helper function to format number with leading zeros (e.g., 1 -> "001")
    private func formatNumber(n: Nat) : Text {
        if (n < 10) {
            "00" # Nat.toText(n)
        } else if (n < 100) {
            "0" # Nat.toText(n)
        } else {
            Nat.toText(n)
        }
    };
    
    public func getProduct(storage: ProductStorage, productId: ProductTypes.ProductId) : ?ProductTypes.Product {
        storage.products.get(productId)
    };
    
    public func updateProduct(
        storage: ProductStorage,
        productId: ProductTypes.ProductId,
        update: ProductTypes.ProductUpdate,
        updatedBy: Principal
    ) : Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
        switch (storage.products.get(productId)) {
            case null { #err(#ProductNotFound) };
            case (?product) {
                // Check authorization
                if (product.createdBy != updatedBy) {
                    return #err(#Unauthorized);
                };
                
                // Validate category if being updated
                let newCategoryId = switch (update.categoryId) {
                    case (?catId) {
                        switch (storage.categories.get(catId)) {
                            case null { return #err(#CategoryNotFound); };
                            case (?cat) {
                                if (not cat.isActive) {
                                    return #err(#CategoryNotFound);
                                };
                                catId
                            };
                        };
                    };
                    case null product.categoryId;
                };
                
                let updatedProduct: ProductTypes.Product = {
                    product with
                    name = switch (update.name) { case (?name) name; case null product.name };
                    description = switch (update.description) { case (?desc) desc; case null product.description };
                    price = switch (update.price) { case (?price) price; case null product.price };
                    categoryId = newCategoryId;
                    imageBase64 = switch (update.imageBase64) { case (?img) ?img; case null product.imageBase64 };
                    stock = switch (update.stock) { case (?stock) stock; case null product.stock };
                    isActive = switch (update.isActive) { case (?active) active; case null product.isActive };
                    updatedAt = Time.now();
                };
                
                storage.products.put(productId, updatedProduct);
                #ok(updatedProduct)
            };
        };
    };
    
    public func updateProductStock(
        storage: ProductStorage,
        productId: ProductTypes.ProductId,
        newStock: Nat
    ) : Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
        switch (storage.products.get(productId)) {
            case null { #err(#ProductNotFound) };
            case (?product) {
                let updatedProduct: ProductTypes.Product = {
                    product with
                    stock = newStock;
                    updatedAt = Time.now();
                };
                
                storage.products.put(productId, updatedProduct);
                #ok(updatedProduct)
            };
        };
    };
    
    public func getAllProducts(storage: ProductStorage) : [ProductTypes.Product] {
        storage.products.vals() |> Iter.toArray(_)
    };
    
    public func getActiveProducts(storage: ProductStorage) : [ProductTypes.Product] {
        storage.products.vals() 
        |> Iter.filter(_, func(p: ProductTypes.Product) : Bool { p.isActive })
        |> Iter.toArray(_)
    };
    
    public func getProductsByCategory(storage: ProductStorage, categoryId: ProductTypes.CategoryId) : [ProductTypes.Product] {
        storage.products.vals()
        |> Iter.filter(_, func(p: ProductTypes.Product) : Bool { p.categoryId == categoryId and p.isActive })
        |> Iter.toArray(_)
    };
    
    public func getProductsByUser(storage: ProductStorage, userId: Principal) : [ProductTypes.Product] {
        storage.products.vals()
        |> Iter.filter(_, func(p: ProductTypes.Product) : Bool { p.createdBy == userId })
        |> Iter.toArray(_)
    };
}
