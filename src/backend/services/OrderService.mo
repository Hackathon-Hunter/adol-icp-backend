import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Array "mo:base/Array";
import OrderTypes "../types/OrderTypes";
import ProductTypes "../types/ProductTypes";
import OrderStorage "../storage/OrderStorage";
import UserService "./UserService";
import ProductService "./ProductService";

module {
    public class OrderService(
        storage: OrderStorage.OrderStorage,
        userService: UserService.UserService,
        productService: ProductService.ProductService
    ) {
        
        public func createOrder(
            userId: Principal,
            input: OrderTypes.OrderInput
        ) : Result.Result<OrderTypes.Order, OrderTypes.OrderError> {
            
            // Validate input
            if (input.items.size() == 0) {
                return #err(#EmptyCart);
            };
            
            // Check if user exists
            switch (userService.getUser(userId)) {
                case (#err(_)) { return #err(#Unauthorized) };
                case (#ok(user)) {
                    
                    // Validate products and calculate total
                    let productItems = Array.map<OrderTypes.OrderItemInput, { productId: ProductTypes.ProductId; quantity: Nat }>(
                        input.items,
                        func(item) = { productId = item.productId; quantity = item.quantity }
                    );
                    
                    switch (productService.validateProductsAndCalculateTotal(productItems)) {
                        case (#err(productError)) {
                            switch (productError) {
                                case (#ProductNotFound) { #err(#ProductNotFound) };
                                case (#InsufficientStock) { #err(#InsufficientStock) };
                                case (_) { #err(#InvalidInput("Product validation failed")) };
                            }
                        };
                        case (#ok(validation)) {
                            
                            // Check user balance
                            if (user.icpBalance < validation.total) {
                                return #err(#InsufficientBalance);
                            };
                            
                            // Deduct stock for all products
                            for (item in input.items.vals()) {
                                switch (productService.checkAndDeductStock(item.productId, item.quantity)) {
                                    case (#err(_)) {
                                        // Restore previously deducted stock
                                        restoreStockForItems(input.items, item);
                                        return #err(#InsufficientStock);
                                    };
                                    case (#ok(_)) {};
                                };
                            };
                            
                            // Deduct user balance
                            switch (userService.deductBalance(userId, validation.total)) {
                                case (#err(_)) {
                                    // Restore stock if balance deduction fails
                                    restoreStockForAllItems(input.items);
                                    return #err(#InsufficientBalance);
                                };
                                case (#ok(_)) {
                                    
                                    // Convert validated items to order items
                                    let orderItems = Array.map<{ productId: ProductTypes.ProductId; quantity: Nat; price: Nat; totalPrice: Nat }, OrderTypes.OrderItem>(
                                        validation.items,
                                        func(item) = {
                                            productId = item.productId;
                                            quantity = item.quantity;
                                            pricePerUnit = item.price;
                                            totalPrice = item.totalPrice;
                                        }
                                    );
                                    
                                    // Create order
                                    let order = OrderStorage.createOrder(
                                        storage,
                                        userId,
                                        orderItems,
                                        input.shippingAddress,
                                        validation.total
                                    );
                                    
                                    #ok(order)
                                };
                            };
                        };
                    };
                };
            };
        };
        
        public func getOrder(orderId: OrderTypes.OrderId, userId: Principal) : Result.Result<OrderTypes.Order, OrderTypes.OrderError> {
            switch (OrderStorage.getOrder(storage, orderId)) {
                case null { #err(#OrderNotFound) };
                case (?order) {
                    if (order.userId != userId) {
                        return #err(#Unauthorized);
                    };
                    #ok(order)
                };
            }
        };
        
        public func updateOrderStatus(
            orderId: OrderTypes.OrderId,
            newStatus: OrderTypes.OrderStatus
        ) : Result.Result<OrderTypes.Order, OrderTypes.OrderError> {
            OrderStorage.updateOrderStatus(storage, orderId, newStatus)
        };
        
        public func cancelOrder(
            orderId: OrderTypes.OrderId,
            userId: Principal
        ) : Result.Result<OrderTypes.Order, OrderTypes.OrderError> {
            switch (OrderStorage.getOrder(storage, orderId)) {
                case null { #err(#OrderNotFound) };
                case (?order) {
                    if (order.userId != userId) {
                        return #err(#Unauthorized);
                    };
                    
                    // Only allow cancellation for pending or confirmed orders
                    switch (order.status) {
                        case (#Pending or #Confirmed) {
                            // Restore stock
                            for (item in order.items.vals()) {
                                ignore productService.restoreStock(item.productId, item.quantity);
                            };
                            
                            // Refund user balance
                            ignore userService.topUpBalance(userId, order.totalAmount);
                            
                            // Update order status
                            OrderStorage.updateOrderStatus(storage, orderId, #Cancelled)
                        };
                        case (_) { #err(#InvalidOrderStatus) };
                    }
                };
            }
        };
        
        public func getUserOrders(userId: Principal) : [OrderTypes.Order] {
            OrderStorage.getUserOrders(storage, userId)
        };
        
        public func getAllOrders() : [OrderTypes.Order] {
            OrderStorage.getAllOrders(storage)
        };
        
        public func getOrdersByStatus(status: OrderTypes.OrderStatus) : [OrderTypes.Order] {
            OrderStorage.getOrdersByStatus(storage, status)
        };
        
        private func restoreStockForItems(
            items: [OrderTypes.OrderItemInput],
            stopAtItem: OrderTypes.OrderItemInput
        ) {
            for (item in items.vals()) {
                if (item.productId == stopAtItem.productId) {
                    return;
                };
                ignore productService.restoreStock(item.productId, item.quantity);
            };
        };
        
        private func restoreStockForAllItems(items: [OrderTypes.OrderItemInput]) {
            for (item in items.vals()) {
                ignore productService.restoreStock(item.productId, item.quantity);
            };
        };
    }
}
