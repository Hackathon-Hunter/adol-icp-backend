import Result "mo:base/Result";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";

// Import types
import UserTypes "./types/UserTypes";
import ProductTypes "./types/ProductTypes";
import OrderTypes "./types/OrderTypes";
import PaymentTypes "./types/PaymentTypes";

// Import storage modules
import UserStorage "./storage/UserStorage";
import ProductStorage "./storage/ProductStorage";
import OrderStorage "./storage/OrderStorage";
import PaymentStorage "./storage/PaymentStorage";

// Import services
import UserService "./services/UserService";
import ProductService "./services/ProductService";
import OrderService "./services/OrderService";
import PaymentService "./services/PaymentService";

persistent actor AdolEcommerce {
    
    // Owner/Platform configuration
    private let OWNER_PRINCIPAL = Principal.fromText("6vkm4-udxft-3dcoj-3efxo-25xih-lnyhl-3y352-yi7ip-6zqjk-nkkbt-fae"); // Your principal
    private let PLATFORM_ACCOUNT = "41041d2ed4424f257c46e127aa61eb45199b56fcf9439c96a4c62e11f8a9d547"; // Your ICP account ID
    private let MINIMUM_TOP_UP_AMOUNT : Nat = 10000; // 0.0001 ICP minimum
    
    // Initialize storage
    private transient var userStorage = UserStorage.init();
    private transient var productStorage = ProductStorage.init();
    private transient var orderStorage = OrderStorage.init();
    private transient var paymentStorage = PaymentStorage.init();
    
    // Initialize services
    private transient let userService = UserService.UserService(userStorage);
    private transient let productService = ProductService.ProductService(productStorage);
    private transient let orderService = OrderService.OrderService(orderStorage, userService, productService);
    private transient let paymentService = PaymentService.PaymentService(paymentStorage, userService);
    
    // User Management
    public shared(msg) func registerUser(registration: UserTypes.UserRegistration) : async Result.Result<UserTypes.User, UserTypes.UserError> {
        userService.registerUser(msg.caller, registration)
    };
    
    public shared(msg) func getProfile() : async Result.Result<UserTypes.User, UserTypes.UserError> {
        userService.getUser(msg.caller)
    };
    
    public shared(msg) func updateProfile(update: UserTypes.UserUpdate) : async Result.Result<UserTypes.User, UserTypes.UserError> {
        userService.updateUser(msg.caller, update)
    };
    
    public shared(msg) func getBalance() : async Result.Result<Nat, UserTypes.UserError> {
        userService.getUserBalance(msg.caller)
    };
    
    // Payment Management
    public shared(msg) func topUpBalance(request: PaymentTypes.TopUpRequest) : async Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {
        await paymentService.processTopUp(msg.caller, request)
    };
    
    // New ICP Top-Up function that sends ICP to owner
    public shared(msg) func topUpBalanceWithICP(request: PaymentTypes.ICPTopUpRequest) : async Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {
        // Validate minimum amount
        if (request.amount < MINIMUM_TOP_UP_AMOUNT) {
            return #err(#InvalidAmount);
        };
        
        // Check if user exists
        switch (userService.getUser(msg.caller)) {
            case (#err(_)) { return #err(#Unauthorized) };
            case (#ok(_)) {
                // Create payment record
                let payment = PaymentStorage.createPayment(
                    paymentStorage,
                    msg.caller,
                    request.amount,
                    #ICP
                );
                
                // For now, simulate the ICP transfer verification
                // In production, you would verify the actual ICP transfer here
                await processICPTopUp(msg.caller, payment, request.amount)
            };
        };
    };
    
    // Get owner's ICP account for top-up instructions
    public func getOwnerICPAccount() : async { 
        account: Text; 
        principal: Text;
        minimumAmount: Nat;
        instructions: Text;
    } {
        {
            account = PLATFORM_ACCOUNT;
            principal = Principal.toText(OWNER_PRINCIPAL);
            minimumAmount = MINIMUM_TOP_UP_AMOUNT;
            instructions = "Send ICP to this account, then call topUpBalanceWithICP with the amount you sent.";
        }
    };
    
    // Private function to process ICP top-up
    private func processICPTopUp(
        userId: Principal,
        payment: PaymentTypes.Payment,
        amount: Nat
    ) : async Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {
        
        // In a real implementation, you would:
        // 1. Verify the ICP transfer to PLATFORM_ACCOUNT
        // 2. Check the transfer amount matches the request
        // 3. Verify the transfer came from the user
        
        // For now, we'll simulate successful verification and add to user balance
        switch (PaymentStorage.updatePaymentStatus(paymentStorage, payment.id, #Completed, ?("icp-transfer-" # Nat.toText(payment.id)))) {
            case (#err(error)) { #err(error) };
            case (#ok(updatedPayment)) {
                // Add balance to user account
                switch (userService.topUpBalance(userId, amount)) {
                    case (#err(_)) {
                        // If balance update fails, mark payment as failed
                        ignore PaymentStorage.updatePaymentStatus(paymentStorage, payment.id, #Failed, null);
                        #err(#PaymentFailed("Failed to update user balance"));
                    };
                    case (#ok(_)) {
                        #ok(updatedPayment)
                    };
                };
            };
        };
    };
    
    public shared(msg) func getPayment(paymentId: PaymentTypes.PaymentId) : async Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {
        paymentService.getPayment(paymentId, msg.caller)
    };
    
    public shared(msg) func getMyPayments() : async [PaymentTypes.Payment] {
        paymentService.getUserPayments(msg.caller)
    };
    
    // Payment Configuration
    public func getPaymentConfig() : async {
        simulationMode: Bool;
        platformAccount: Principal;
        minimumAmount: Nat;
    } {
        paymentService.getPaymentConfig()
    };
    
    public shared(msg) func getMyDepositInfo() : async { 
        platformAccount: Principal; 
        userSubaccount: Text;
        instructions: Text;
    } {
        paymentService.getUserDepositInfo(msg.caller)
    };
    
    // Product Management
    public func getProducts() : async [ProductTypes.Product] {
        productService.getActiveProducts()
    };
    
    public func getProduct(productId: ProductTypes.ProductId) : async Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
        productService.getProduct(productId)
    };
    
    public func getCategories() : async [ProductTypes.Category] {
        productService.getAllCategories()
    };
    
    public func getProductsByCategory(categoryId: ProductTypes.CategoryId) : async [ProductTypes.Product] {
        productService.getProductsByCategory(categoryId)
    };
    
    // Admin Product Management
    public shared(_) func createCategory(input: ProductTypes.CategoryInput) : async ProductTypes.Category {
        productService.createCategory(input)
    };
    
    public shared(msg) func createProduct(input: ProductTypes.ProductInput) : async Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
        productService.createProduct(input, msg.caller)
    };
    
    public shared(msg) func updateProduct(productId: ProductTypes.ProductId, update: ProductTypes.ProductUpdate) : async Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
        productService.updateProduct(productId, update, msg.caller)
    };
    
    // Order Management
    public shared(msg) func createOrder(input: OrderTypes.OrderInput) : async Result.Result<OrderTypes.Order, OrderTypes.OrderError> {
        orderService.createOrder(msg.caller, input)
    };
    
    public shared(msg) func getOrder(orderId: OrderTypes.OrderId) : async Result.Result<OrderTypes.Order, OrderTypes.OrderError> {
        orderService.getOrder(orderId, msg.caller)
    };
    
    public shared(msg) func getMyOrders() : async [OrderTypes.Order] {
        orderService.getUserOrders(msg.caller)
    };
    
    public shared(msg) func cancelOrder(orderId: OrderTypes.OrderId) : async Result.Result<OrderTypes.Order, OrderTypes.OrderError> {
        orderService.cancelOrder(orderId, msg.caller)
    };
    
    // Admin Order Management
    public shared(_) func updateOrderStatus(orderId: OrderTypes.OrderId, status: OrderTypes.OrderStatus) : async Result.Result<OrderTypes.Order, OrderTypes.OrderError> {
        orderService.updateOrderStatus(orderId, status)
    };
    
    public shared(_) func getAllOrders() : async [OrderTypes.Order] {
        orderService.getAllOrders()
    };
    
    public shared(_) func getOrdersByStatus(status: OrderTypes.OrderStatus) : async [OrderTypes.Order] {
        orderService.getOrdersByStatus(status)
    };
    
    // Admin User Management
    public shared(_) func getAllUsers() : async [UserTypes.User] {
        userService.getAllUsers()
    };
    
    public shared(_) func getAllProducts() : async [ProductTypes.Product] {
        productService.getAllProducts()
    };
    
    public shared(_) func getAllPayments() : async [PaymentTypes.Payment] {
        paymentService.getAllPayments()
    };
    
    // System info
    public query func getInfo() : async { 
        name: Text; 
        version: Text; 
        description: Text;
        timestamp: Int;
    } {
        {
            name = "Adol E-commerce Platform";
            version = "1.0.0";
            description = "A decentralized e-commerce platform built on the Internet Computer";
            timestamp = Time.now();
        }
    };
    
    // Health check
    public query func health() : async { status: Text; timestamp: Int } {
        {
            status = "healthy";
            timestamp = Time.now();
        }
    };
}
