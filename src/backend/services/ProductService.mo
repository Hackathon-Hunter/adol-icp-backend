import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Int "mo:base/Int";
import ProductTypes "../types/ProductTypes";
import ProductStorage "../storage/ProductStorage";

module {
    public class ProductService(storage: ProductStorage.ProductStorage) {
        
        public func createCategory(
            input: ProductTypes.CategoryInput
        ) : ProductTypes.Category {
            ProductStorage.createCategory(storage, input)
        };
        
        public func getCategory(categoryId: ProductTypes.CategoryId) : Result.Result<ProductTypes.Category, ProductTypes.ProductError> {
            switch (ProductStorage.getCategory(storage, categoryId)) {
                case null { #err(#CategoryNotFound) };
                case (?category) { #ok(category) };
            }
        };
        
        public func getAllCategories() : [ProductTypes.Category] {
            ProductStorage.getAllCategories(storage)
        };
        
        public func createProduct(
            input: ProductTypes.ProductInput,
            createdBy: Principal
        ) : Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
            // Validate input
            if (input.name == "" or input.description == "") {
                return #err(#InvalidInput("Name and description are required"));
            };
            
            if (input.price == 0) {
                return #err(#InvalidInput("Price must be greater than 0"));
            };
            
            ProductStorage.createProduct(storage, input, createdBy)
        };
        
        public func getProduct(productId: ProductTypes.ProductId) : Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
            switch (ProductStorage.getProduct(storage, productId)) {
                case null { #err(#ProductNotFound) };
                case (?product) { #ok(product) };
            }
        };
        
        public func updateProduct(
            productId: ProductTypes.ProductId,
            update: ProductTypes.ProductUpdate,
            updatedBy: Principal
        ) : Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
            ProductStorage.updateProduct(storage, productId, update, updatedBy)
        };
        
        public func updateProductStock(
            productId: ProductTypes.ProductId,
            newStock: Nat
        ) : Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
            ProductStorage.updateProductStock(storage, productId, newStock)
        };
        
        public func checkAndDeductStock(
            productId: ProductTypes.ProductId,
            quantity: Nat
        ) : Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
            switch (ProductStorage.getProduct(storage, productId)) {
                case null { #err(#ProductNotFound) };
                case (?product) {
                    if (product.status != #active) {
                        return #err(#ProductNotFound);
                    };
                    
                    if (product.stock < quantity) {
                        return #err(#InsufficientStock);
                    };
                    
                    let newStock = Int.abs(product.stock - quantity);
                    ProductStorage.updateProductStock(storage, productId, newStock)
                };
            }
        };
        
        public func restoreStock(
            productId: ProductTypes.ProductId,
            quantity: Nat
        ) : Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
            switch (ProductStorage.getProduct(storage, productId)) {
                case null { #err(#ProductNotFound) };
                case (?product) {
                    let newStock = product.stock + quantity;
                    ProductStorage.updateProductStock(storage, productId, newStock)
                };
            }
        };
        
        public func getAllProducts() : [ProductTypes.Product] {
            ProductStorage.getAllProducts(storage)
        };
        
        public func getActiveProducts() : [ProductTypes.Product] {
            ProductStorage.getActiveProducts(storage)
        };
        
        public func getDraftProducts() : [ProductTypes.Product] {
            ProductStorage.getDraftProducts(storage)
        };
        
        public func getSoldProducts() : [ProductTypes.Product] {
            ProductStorage.getSoldProducts(storage)
        };
        
        public func getProductsByStatus(status: ProductTypes.ProductStatus) : [ProductTypes.Product] {
            ProductStorage.getProductsByStatus(storage, status)
        };
        
        public func getProductsByCategory(categoryId: ProductTypes.CategoryId) : [ProductTypes.Product] {
            ProductStorage.getProductsByCategory(storage, categoryId)
        };
        
        public func getProductsByUser(userId: Principal) : [ProductTypes.Product] {
            ProductStorage.getProductsByUser(storage, userId)
        };
        
        public func validateProductsAndCalculateTotal(
            items: [{ productId: ProductTypes.ProductId; quantity: Nat }]
        ) : Result.Result<{ total: Nat; items: [{ productId: ProductTypes.ProductId; quantity: Nat; price: Nat; totalPrice: Nat }] }, ProductTypes.ProductError> {
            var total: Nat = 0;
            var validatedItems: [{ productId: ProductTypes.ProductId; quantity: Nat; price: Nat; totalPrice: Nat }] = [];
            
            for (item in items.vals()) {
                switch (ProductStorage.getProduct(storage, item.productId)) {
                    case null { return #err(#ProductNotFound) };
                    case (?product) {
                        if (product.status != #active) {
                            return #err(#ProductNotFound);
                        };
                        
                        if (product.stock < item.quantity) {
                            return #err(#InsufficientStock);
                        };
                        
                        let itemTotal = product.price * item.quantity;
                        total += itemTotal;
                        
                        let validatedItem = {
                            productId = item.productId;
                            quantity = item.quantity;
                            price = product.price;
                            totalPrice = itemTotal;
                        };
                        
                        validatedItems := Array.append(validatedItems, [validatedItem]);
                    };
                };
            };
            
            #ok({ total = total; items = validatedItems })
        };
    }
}
