import Result "mo:base/Result";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Float "mo:base/Float";

// Import types
import UserTypes "./types/UserTypes";
import ProductTypes "./types/ProductTypes";
import OrderTypes "./types/OrderTypes";
import PaymentTypes "./types/PaymentTypes";
import BuyerMatchTypes "./types/BuyerMatchTypes";

// Import storage modules
import UserStorage "./storage/UserStorage";
import ProductStorage "./storage/ProductStorage";
import OrderStorage "./storage/OrderStorage";
import PaymentStorage "./storage/PaymentStorage";
import BuyerMatchStorage "./storage/BuyerMatchStorage";

// Import services
import UserService "./services/UserService";
import ProductService "./services/ProductService";
import OrderService "./services/OrderService";
import PaymentService "./services/PaymentService";
import BuyerMatchService "./services/BuyerMatchService";

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
  private transient var buyerMatchStorage = BuyerMatchStorage.init();

  // Initialize services
  private transient let userService = UserService.UserService(userStorage);
  private transient let productService = ProductService.ProductService(productStorage);
  private transient let orderService = OrderService.OrderService(orderStorage, userService, productService);
  private transient let paymentService = PaymentService.PaymentService(paymentStorage, userService);
  private transient let buyerMatchService = BuyerMatchService.BuyerMatchService(buyerMatchStorage);

  // Initialize with default data
  private func initializeDefaults() : () {
    // Create default category if none exist
    if (productService.getAllCategories().size() == 0) {
      let defaultCategory : ProductTypes.CategoryInput = {
        name = "Electronics";
        description = "Electronic devices and accessories";
        code = "ELC"; // 3-letter code for SKU generation
      };
      ignore productService.createCategory(defaultCategory);
    };
  };

  // Call initialization on startup
  initializeDefaults();

  // User Management
  public shared (msg) func registerUser(registration : UserTypes.UserRegistration) : async Result.Result<UserTypes.User, UserTypes.UserError> {
    userService.registerUser(msg.caller, registration);
  };

  public shared (msg) func getProfile() : async Result.Result<UserTypes.User, UserTypes.UserError> {
    userService.getUser(msg.caller);
  };

  public shared (msg) func updateProfile(update : UserTypes.UserUpdate) : async Result.Result<UserTypes.User, UserTypes.UserError> {
    userService.updateUser(msg.caller, update);
  };

  public shared (msg) func getBalance() : async Result.Result<Nat, UserTypes.UserError> {
    userService.getUserBalance(msg.caller);
  };

  // Payment Management
  public shared (msg) func topUpBalance(request : PaymentTypes.TopUpRequest) : async Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {
    await paymentService.processTopUp(msg.caller, request);
  };

  // New ICP Top-Up function that sends ICP to owner
  public shared (msg) func topUpBalanceWithICP(request : PaymentTypes.ICPTopUpRequest) : async Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {
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
          #ICP,
        );

        // For now, simulate the ICP transfer verification
        // In production, you would verify the actual ICP transfer here
        await processICPTopUp(msg.caller, payment, request.amount);
      };
    };
  };

  // Get owner's ICP account for top-up instructions
  public query func getOwnerICPAccount() : async {
    account : Text;
    principal : Text;
    minimumAmount : Nat;
    instructions : Text;
  } {
    {
      account = PLATFORM_ACCOUNT;
      principal = Principal.toText(OWNER_PRINCIPAL);
      minimumAmount = MINIMUM_TOP_UP_AMOUNT;
      instructions = "Send ICP to this account, then call topUpBalanceWithICP with the amount you sent.";
    };
  };

  // Private function to process ICP top-up
  private func processICPTopUp(
    userId : Principal,
    payment : PaymentTypes.Payment,
    amount : Nat,
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
            #ok(updatedPayment);
          };
        };
      };
    };
  };

  public shared (msg) func getPayment(paymentId : PaymentTypes.PaymentId) : async Result.Result<PaymentTypes.Payment, PaymentTypes.PaymentError> {
    paymentService.getPayment(paymentId, msg.caller);
  };

  public shared (msg) func getMyPayments() : async [PaymentTypes.Payment] {
    paymentService.getUserPayments(msg.caller);
  };

  // Payment Configuration
  public query func getPaymentConfig() : async {
    simulationMode : Bool;
    platformAccount : Principal;
    minimumAmount : Nat;
  } {
    paymentService.getPaymentConfig();
  };

  public shared (msg) func getMyDepositInfo() : async {
    platformAccount : Principal;
    userSubaccount : Text;
    instructions : Text;
  } {
    paymentService.getUserDepositInfo(msg.caller);
  };

  // Product Management
  public query func getProducts() : async [ProductTypes.Product] {
    productService.getActiveProducts();
  };

  public query func getAllProducts() : async [ProductTypes.Product] {
    productService.getAllProducts();
  };

  public query func getDraftProducts() : async [ProductTypes.Product] {
    productService.getDraftProducts();
  };

  public query func getSoldProducts() : async [ProductTypes.Product] {
    productService.getSoldProducts();
  };

  public query func getProductsByStatus(status : ProductTypes.ProductStatus) : async [ProductTypes.Product] {
    productService.getProductsByStatus(status);
  };

  public query func getProduct(productId : ProductTypes.ProductId) : async Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
    productService.getProduct(productId);
  };

  public query func getCategories() : async [ProductTypes.Category] {
    productService.getAllCategories();
  };

  public query func getProductsByCategory(categoryId : ProductTypes.CategoryId) : async [ProductTypes.Product] {
    productService.getProductsByCategory(categoryId);
  };

  // Get products created by the logged-in user
  public shared (msg) func getMyProducts() : async [ProductTypes.Product] {
    productService.getProductsByUser(msg.caller);
  };

  // Admin Product Management
  public shared (_) func createCategory(input : ProductTypes.CategoryInput) : async ProductTypes.Category {
    productService.createCategory(input);
  };

  public shared (msg) func createProduct(input : ProductTypes.ProductInput) : async Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
    productService.createProduct(input, msg.caller);
  };

  public shared (msg) func updateProduct(productId : ProductTypes.ProductId, update : ProductTypes.ProductUpdate) : async Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
    productService.updateProduct(productId, update, msg.caller);
  };

  // Mark product as sold
  public shared (msg) func markProductAsSold(productId : ProductTypes.ProductId) : async Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
    let update : ProductTypes.ProductUpdate = {
      name = null;
      description = null;
      price = null;
      targetPrice = null;
      minimumPrice = null;
      categoryId = null;
      condition = null;
      imageBase64 = null;
      stock = null;
      status = ?#sold;
      keySellingPoints = null;
      knownFlaws = null;
      reasonForSelling = null;
      pickupDeliveryInfo = null;
    };
    productService.updateProduct(productId, update, msg.caller);
  };

  // Publish draft product (make it active)
  public shared (msg) func publishProduct(productId : ProductTypes.ProductId) : async Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
    let update : ProductTypes.ProductUpdate = {
      name = null;
      description = null;
      price = null;
      targetPrice = null;
      minimumPrice = null;
      categoryId = null;
      condition = null;
      imageBase64 = null;
      stock = null;
      status = ?#active;
      keySellingPoints = null;
      knownFlaws = null;
      reasonForSelling = null;
      pickupDeliveryInfo = null;
    };
    productService.updateProduct(productId, update, msg.caller);
  };

  // Mark product as draft (unpublish)
  public shared (msg) func markProductAsDraft(productId : ProductTypes.ProductId) : async Result.Result<ProductTypes.Product, ProductTypes.ProductError> {
    let update : ProductTypes.ProductUpdate = {
      name = null;
      description = null;
      price = null;
      targetPrice = null;
      minimumPrice = null;
      categoryId = null;
      condition = null;
      imageBase64 = null;
      stock = null;
      status = ?#draft;
      keySellingPoints = null;
      knownFlaws = null;
      reasonForSelling = null;
      pickupDeliveryInfo = null;
    };
    productService.updateProduct(productId, update, msg.caller);
  };

  // Buyer Matching System
  public shared (msg) func createBuyerProfile(input : BuyerMatchTypes.BuyerProfileInput) : async BuyerMatchTypes.BuyerProfile {
    buyerMatchService.createBuyerProfile(msg.caller, input);
  };

  public shared (msg) func getBuyerProfile() : async Result.Result<BuyerMatchTypes.BuyerProfile, BuyerMatchTypes.BuyerMatchError> {
    buyerMatchService.getBuyerProfile(msg.caller);
  };

  public shared (_) func getBuyerProfileById(buyerId : BuyerMatchTypes.BuyerId) : async Result.Result<BuyerMatchTypes.BuyerProfile, BuyerMatchTypes.BuyerMatchError> {
    buyerMatchService.getBuyerProfileById(buyerId);
  };

  public shared (msg) func updateBuyerProfile(update : BuyerMatchTypes.BuyerProfileUpdate) : async Result.Result<BuyerMatchTypes.BuyerProfile, BuyerMatchTypes.BuyerMatchError> {
    buyerMatchService.updateBuyerProfile(msg.caller, update);
  };

  public shared (msg) func createSellerProfile(input : BuyerMatchTypes.SellerProfileInput) : async BuyerMatchTypes.SellerProfile {
    buyerMatchService.createSellerProfile(msg.caller, input);
  };

  public shared (msg) func getSellerProfile() : async Result.Result<BuyerMatchTypes.SellerProfile, BuyerMatchTypes.BuyerMatchError> {
    buyerMatchService.getSellerProfile(msg.caller);
  };

  public shared (_) func getSellerProfileById(sellerId : BuyerMatchTypes.SellerId) : async Result.Result<BuyerMatchTypes.SellerProfile, BuyerMatchTypes.BuyerMatchError> {
    buyerMatchService.getSellerProfileById(sellerId);
  };

  public shared (msg) func updateSellerProfile(update : BuyerMatchTypes.SellerProfileUpdate) : async Result.Result<BuyerMatchTypes.SellerProfile, BuyerMatchTypes.BuyerMatchError> {
    buyerMatchService.updateSellerProfile(msg.caller, update);
  };

  public shared (msg) func findPotentialMatches(criteria : BuyerMatchTypes.MatchingCriteria) : async Result.Result<[BuyerMatchTypes.PotentialMatch], BuyerMatchTypes.BuyerMatchError> {
    let products = productService.getActiveProducts();
    buyerMatchService.findPotentialMatches(msg.caller, products, criteria);
  };

  public shared (msg) func getMyMatches() : async [BuyerMatchTypes.PotentialMatch] {
    buyerMatchService.getBuyerMatches(msg.caller);
  };

  public shared (msg) func getMatchesForSeller() : async [BuyerMatchTypes.PotentialMatch] {
    buyerMatchService.getSellerMatches(msg.caller);
  };

  public shared (_) func markMatchAsViewed(matchId : Nat) : async Result.Result<BuyerMatchTypes.PotentialMatch, BuyerMatchTypes.BuyerMatchError> {
    buyerMatchService.markMatchAsViewed(matchId);
  };

  public shared (_) func setMatchInterest(matchId : Nat, isInterested : Bool) : async Result.Result<BuyerMatchTypes.PotentialMatch, BuyerMatchTypes.BuyerMatchError> {
    buyerMatchService.setMatchInterest(matchId, isInterested);
  };

  public shared (msg) func addPurchaseRecord(record : BuyerMatchTypes.PurchaseRecord) : async Result.Result<BuyerMatchTypes.BuyerProfile, BuyerMatchTypes.BuyerMatchError> {
    buyerMatchService.addPurchaseRecord(msg.caller, record);
  };

  // Order Management
  public shared (msg) func createOrder(input : OrderTypes.OrderInput) : async Result.Result<OrderTypes.Order, OrderTypes.OrderError> {
    orderService.createOrder(msg.caller, input);
  };

  public shared (msg) func getOrder(orderId : OrderTypes.OrderId) : async Result.Result<OrderTypes.Order, OrderTypes.OrderError> {
    orderService.getOrder(orderId, msg.caller);
  };

  public shared (msg) func getMyOrders() : async [OrderTypes.Order] {
    orderService.getUserOrders(msg.caller);
  };

  public shared (msg) func cancelOrder(orderId : OrderTypes.OrderId) : async Result.Result<OrderTypes.Order, OrderTypes.OrderError> {
    orderService.cancelOrder(orderId, msg.caller);
  };

  // Admin Order Management
  public shared (_) func updateOrderStatus(orderId : OrderTypes.OrderId, status : OrderTypes.OrderStatus) : async Result.Result<OrderTypes.Order, OrderTypes.OrderError> {
    orderService.updateOrderStatus(orderId, status);
  };

  public shared (_) func getAllOrders() : async [OrderTypes.Order] {
    orderService.getAllOrders();
  };

  public shared (_) func getOrdersByStatus(status : OrderTypes.OrderStatus) : async [OrderTypes.Order] {
    orderService.getOrdersByStatus(status);
  };

  // Admin User Management
  public shared (_) func getAllUsers() : async [UserTypes.User] {
    userService.getAllUsers();
  };

  public shared (_) func getAllPayments() : async [PaymentTypes.Payment] {
    paymentService.getAllPayments();
  };

  // Admin Buyer Matching Management
  public shared (_) func getAllBuyerProfiles() : async [BuyerMatchTypes.BuyerProfile] {
    buyerMatchService.getAllBuyerProfiles();
  };

  public shared (_) func getAllSellerProfiles() : async [BuyerMatchTypes.SellerProfile] {
    buyerMatchService.getAllSellerProfiles();
  };

  public shared (_) func getAllMatches() : async [BuyerMatchTypes.PotentialMatch] {
    buyerMatchService.getAllMatches();
  };

  // System info
  public query func getInfo() : async {
    name : Text;
    version : Text;
    description : Text;
    timestamp : Int;
  } {
    {
      name = "Adol E-commerce Platform";
      version = "1.0.0";
      description = "A decentralized e-commerce platform built on the Internet Computer";
      timestamp = Time.now();
    };
  };

  // Health check
  public query func health() : async { status : Text; timestamp : Int } {
    {
      status = "healthy";
      timestamp = Time.now();
    };
  };

  // HTTP Gateway Support
  public type HeaderField = (Text, Text);
  public type Request = {
    body : Blob;
    headers : [HeaderField];
    method : Text;
    url : Text;
  };

  public type Response = {
    body : Blob;
    headers : [HeaderField];
    status_code : Nat16;
    streaming_strategy : ?StreamingStrategy;
  };

  public type StreamingStrategy = {
    #Callback : {
      token : StreamingToken;
      callback : StreamingCallback;
    };
  };

  public type StreamingToken = {
    arbitrary_data : Text;
  };

  public type StreamingCallback = query (StreamingToken) -> async (?StreamingCallbackResponse);

  public type StreamingCallbackResponse = {
    token : ?StreamingToken;
    body : Blob;
  };

  // Helper function to create JSON response
  private func jsonResponse(json : Text) : Response {
    {
      body = Text.encodeUtf8(json);
      headers = [("Content-Type", "application/json"), ("Access-Control-Allow-Origin", "*")];
      status_code = 200;
      streaming_strategy = null;
    };
  };

  // Helper function to create error response
  private func errorResponse(message : Text) : Response {
    {
      body = Text.encodeUtf8("{\"error\":\"" # message # "\"}");
      headers = [("Content-Type", "application/json"), ("Access-Control-Allow-Origin", "*")];
      status_code = 404;
      streaming_strategy = null;
    };
  };

  // Helper function to serialize products to JSON
  private func productsToJson(products : [ProductTypes.Product]) : Text {
    var json = "[";
    let size = products.size();
    if (size > 0) {
      for (i in Iter.range(0, size - 1)) {
        let product = products[i];
        json #= "{";
        json #= "\"id\":\"" # product.id # "\",";
        json #= "\"name\":\"" # product.name # "\",";
        json #= "\"description\":\"" # product.description # "\",";
        json #= "\"price\":" # Nat.toText(product.price) # ",";

        // Include targetPrice and minimumPrice
        switch (product.targetPrice) {
          case null { json #= "\"targetPrice\":null," };
          case (?price) { json #= "\"targetPrice\":" # Nat.toText(price) # "," };
        };
        switch (product.minimumPrice) {
          case null { json #= "\"minimumPrice\":null," };
          case (?price) {
            json #= "\"minimumPrice\":" # Nat.toText(price) # ",";
          };
        };

        json #= "\"categoryId\":" # Nat.toText(product.categoryId) # ",";
        json #= "\"condition\":\"" # product.condition # "\",";

        json #= "\"stock\":" # Nat.toText(product.stock) # ",";
        json #= "\"status\":\"" # (switch (product.status) { case (#active) "active"; case (#draft) "draft"; case (#sold) "sold" }) # "\",";
        json #= "\"createdAt\":" # Int.toText(product.createdAt) # ",";
        json #= "\"updatedAt\":" # Int.toText(product.updatedAt) # ",";
        json #= "\"createdBy\":\"" # Principal.toText(product.createdBy) # "\",";

        // Include keySellingPoints array
        json #= "\"keySellingPoints\":[";
        for (j in product.keySellingPoints.keys()) {
          if (j > 0) { json #= "," };
          json #= "\"" # product.keySellingPoints[j] # "\"";
        };
        json #= "],";

        json #= "\"knownFlaws\":\"" # product.knownFlaws # "\",";
        json #= "\"reasonForSelling\":\"" # product.reasonForSelling # "\",";
        json #= "\"pickupDeliveryInfo\":\"" # product.pickupDeliveryInfo # "\"";

        json #= "}";
        if (i + 1 < size) {
          json #= ",";
        };
      };
    };
    json #= "]";
    json;
  };

  // Helper function to serialize categories to JSON
  private func categoriesToJson(categories : [ProductTypes.Category]) : Text {
    var json = "[";
    let size = categories.size();
    if (size > 0) {
      for (i in Iter.range(0, size - 1)) {
        let category = categories[i];
        json #= "{";
        json #= "\"id\":" # Nat.toText(category.id) # ",";
        json #= "\"name\":\"" # category.name # "\",";
        json #= "\"description\":\"" # category.description # "\"";
        json #= "}";
        if (i + 1 < size) {
          json #= ",";
        };
      };
    };
    json #= "]";
    json;
  };

  // Helper function to serialize buyer profiles to JSON
  private func buyerProfilesToJson(profiles : [BuyerMatchTypes.BuyerProfile]) : Text {
    var json = "[";
    let size = profiles.size();
    if (size > 0) {
      for (i in Iter.range(0, size - 1)) {
        let profile = profiles[i];
        json #= "{";
        json #= "\"id\":\"" # Principal.toText(profile.id) # "\",";
        json #= "\"name\":\"" # profile.name # "\",";
        json #= "\"email\":\"" # profile.email # "\",";
        json #= "\"budget\":" # Nat.toText(profile.budget) # ",";
        json #= "\"isActive\":" # (if (profile.isActive) "true" else "false") # ",";
        json #= "\"createdAt\":" # Int.toText(profile.createdAt);
        json #= "}";
        if (i + 1 < size) {
          json #= ",";
        };
      };
    };
    json #= "]";
    json;
  };

  // Helper function to serialize seller profiles to JSON
  private func sellerProfilesToJson(profiles : [BuyerMatchTypes.SellerProfile]) : Text {
    var json = "[";
    let size = profiles.size();
    if (size > 0) {
      for (i in Iter.range(0, size - 1)) {
        let profile = profiles[i];
        json #= "{";
        json #= "\"id\":\"" # Principal.toText(profile.id) # "\",";
        json #= "\"businessName\":\"" # profile.businessName # "\",";
        json #= "\"description\":\"" # profile.description # "\",";
        json #= "\"contactEmail\":\"" # profile.contactEmail # "\",";
        json #= "\"rating\":" # Float.toText(profile.rating) # ",";
        json #= "\"totalSales\":" # Nat.toText(profile.totalSales) # ",";
        json #= "\"isVerified\":" # (if (profile.isVerified) "true" else "false") # ",";
        json #= "\"createdAt\":" # Int.toText(profile.createdAt);
        json #= "}";
        if (i + 1 < size) {
          json #= ",";
        };
      };
    };
    json #= "]";
    json;
  };

  // Helper function to serialize matches to JSON
  private func matchesToJson(matches : [BuyerMatchTypes.PotentialMatch]) : Text {
    var json = "[";
    let size = matches.size();
    if (size > 0) {
      for (i in Iter.range(0, size - 1)) {
        let match = matches[i];
        json #= "{";
        json #= "\"id\":" # Nat.toText(match.id) # ",";
        json #= "\"buyerId\":\"" # Principal.toText(match.buyerId) # "\",";
        json #= "\"sellerId\":\"" # Principal.toText(match.sellerId) # "\",";
        json #= "\"productId\":\"" # match.productId # "\",";
        json #= "\"matchScore\":" # Float.toText(match.matchScore) # ",";
        json #= "\"isViewed\":" # (if (match.isViewed) "true" else "false") # ",";
        json #= "\"createdAt\":" # Int.toText(match.createdAt);
        json #= "}";
        if (i + 1 < size) {
          json #= ",";
        };
      };
    };
    json #= "]";
    json;
  };

  // Helper function to serialize single product to JSON
  private func productToJson(product : ProductTypes.Product) : Text {
    var json = "{";
    json #= "\"id\":\"" # product.id # "\",";
    json #= "\"name\":\"" # product.name # "\",";
    json #= "\"description\":\"" # product.description # "\",";
    json #= "\"price\":" # Nat.toText(product.price) # ",";
    switch (product.targetPrice) {
      case null { json #= "\"targetPrice\":null," };
      case (?price) { json #= "\"targetPrice\":" # Nat.toText(price) # "," };
    };
    switch (product.minimumPrice) {
      case null { json #= "\"minimumPrice\":null," };
      case (?price) { json #= "\"minimumPrice\":" # Nat.toText(price) # "," };
    };
    json #= "\"categoryId\":" # Nat.toText(product.categoryId) # ",";
    json #= "\"condition\":\"" # product.condition # "\",";
    json #= "\"createdBy\":\"" # Principal.toText(product.createdBy) # "\",";
    json #= "\"stock\":" # Nat.toText(product.stock) # ",";
    json #= "\"status\":\"" # (switch (product.status) { case (#active) "active"; case (#draft) "draft"; case (#sold) "sold" }) # "\",";
    json #= "\"createdAt\":" # Int.toText(product.createdAt) # ",";
    json #= "\"updatedAt\":" # Int.toText(product.updatedAt) # ",";

    // Serialize keySellingPoints array
    json #= "\"keySellingPoints\":[";
    for (i in product.keySellingPoints.keys()) {
      if (i > 0) { json #= "," };
      json #= "\"" # product.keySellingPoints[i] # "\"";
    };
    json #= "],";

    json #= "\"knownFlaws\":\"" # product.knownFlaws # "\",";
    json #= "\"reasonForSelling\":\"" # product.reasonForSelling # "\",";
    json #= "\"pickupDeliveryInfo\":\"" # product.pickupDeliveryInfo # "\",";

    // Add mock seller information
    json #= "\"seller\":{";
    json #= "\"id\":\"seller_123\",";
    json #= "\"name\":\"Devin\",";
    json #= "\"phone\":\"083878719726\",";
    json #= "\"location\":\"Jakarta, Indonesia\",";
    json #= "\"email\":\"devin@example.com\"";
    json #= "}";
    json #= "}";
    json;
  };

  // Helper function to extract product ID from URL path
  private func extractProductId(path : Text) : ?Text {
    // Handle paths like "/api/products/ELC001" or "/products/ELC001"
    if (Text.startsWith(path, #text "/api/products/")) {
      let idText = Text.trimStart(path, #text "/api/products/");
      if (idText.size() > 0) { ?idText } else { null };
    } else if (Text.startsWith(path, #text "/products/")) {
      let idText = Text.trimStart(path, #text "/products/");
      if (idText.size() > 0) { ?idText } else { null };
    } else {
      null;
    };
  };

  // Helper function to extract product ID from URL path

  // Main HTTP request handler
  public query func http_request(request : Request) : async Response {
    let path = request.url;
    let method = request.method;

    // Handle POST requests (redirect to http_request_update)
    if (method == "POST") {
      {
        status_code = 200;
        headers = [("content-type", "application/json"), ("Access-Control-Allow-Origin", "*"), ("Access-Control-Allow-Methods", "GET, POST, OPTIONS"), ("Access-Control-Allow-Headers", "Content-Type")];
        body = Text.encodeUtf8("{\"message\":\"Use http_request_update for POST requests\"}");
        streaming_strategy = null;
      };
    } else if (path == "/api/products" or path == "/products") {
      let products = productService.getActiveProducts();
      jsonResponse(productsToJson(products));
    } else if (path == "/api/products/draft" or path == "/products/draft") {
      let products = productService.getDraftProducts();
      jsonResponse(productsToJson(products));
    } else if (path == "/api/products/sold" or path == "/products/sold") {
      let products = productService.getSoldProducts();
      jsonResponse(productsToJson(products));
    } else if (path == "/api/products/all" or path == "/products/all") {
      let products = productService.getAllProducts();
      jsonResponse(productsToJson(products));
    } else if (Text.startsWith(path, #text "/api/products/") or Text.startsWith(path, #text "/products/")) {
      // Handle product detail endpoint like /api/products/123
      switch (extractProductId(path)) {
        case null {
          errorResponse("Invalid product ID");
        };
        case (?productId) {
          switch (productService.getProduct(productId)) {
            case (#err(_)) {
              errorResponse("Product not found");
            };
            case (#ok(product)) {
              jsonResponse(productToJson(product));
            };
          };
        };
      };
    } else if (path == "/api/categories" or path == "/categories") {
      let categories = productService.getAllCategories();
      jsonResponse(categoriesToJson(categories));
    } else if (path == "/api/my-products" or path == "/my-products") {
      // Note: This endpoint cannot authenticate users via HTTP Gateway
      // Users must call getMyProducts() directly via the canister interface
      errorResponse("Authentication required. Use getMyProducts() canister method directly.");
    } else if (path == "/api/health" or path == "/health") {
      jsonResponse("{\"status\":\"healthy\",\"timestamp\":" # Int.toText(Time.now()) # "}");
    } else if (path == "/api/info" or path == "/info") {
      jsonResponse("{\"name\":\"Adol E-commerce Platform\",\"version\":\"1.0.0\",\"description\":\"A decentralized e-commerce platform built on the Internet Computer\",\"timestamp\":" # Int.toText(Time.now()) # "}");
    } else if (path == "/api/payment-config" or path == "/payment-config") {
      let config = paymentService.getPaymentConfig();
      jsonResponse("{\"simulationMode\":" # (if (config.simulationMode) "true" else "false") # ",\"platformAccount\":\"" # Principal.toText(config.platformAccount) # "\",\"minimumAmount\":" # Nat.toText(config.minimumAmount) # "}");
    } else if (path == "/api/owner-account" or path == "/owner-account") {
      jsonResponse("{\"account\":\"" # PLATFORM_ACCOUNT # "\",\"principal\":\"" # Principal.toText(OWNER_PRINCIPAL) # "\",\"minimumAmount\":" # Nat.toText(MINIMUM_TOP_UP_AMOUNT) # ",\"instructions\":\"Send ICP to this account, then call topUpBalanceWithICP with the amount you sent.\"}");
    } else if (path == "/api/buyer-profiles" or path == "/buyer-profiles") {
      let profiles = buyerMatchService.getAllBuyerProfiles();
      jsonResponse(buyerProfilesToJson(profiles));
    } else if (path == "/api/seller-profiles" or path == "/seller-profiles") {
      let profiles = buyerMatchService.getAllSellerProfiles();
      jsonResponse(sellerProfilesToJson(profiles));
    } else if (path == "/api/matches" or path == "/matches") {
      let matches = buyerMatchService.getAllMatches();
      jsonResponse(matchesToJson(matches));
    } else if (path == "/" or path == "") {
      jsonResponse("{\"message\":\"Adol E-commerce API\",\"version\":\"1.0.0\",\"endpoints\":[\"/api/products\",\"/api/products/{id}\",\"/api/categories\",\"/api/health\",\"/api/info\",\"/api/payment-config\",\"/api/owner-account\",\"/api/buyer-profiles\",\"/api/seller-profiles\",\"/api/matches\"]}");
    } else {
      errorResponse("Endpoint not found");
    };
  };

  // Helper function to parse product creation JSON
  private func parseCreateProductJson(body : Blob) : ?{
    name : Text;
    description : Text;
    price : Nat;
    categoryId : Nat;
    stock : Nat;
    imageBase64 : ?Text;
  } {
    // Simple JSON parsing for product creation
    // In a real implementation, you'd use a proper JSON parser
    let bodyText = switch (Text.decodeUtf8(body)) {
      case null { return null };
      case (?text) { text };
    };

    // For now, return null - we'll implement proper JSON parsing later
    // This is a placeholder for basic functionality
    null;
  };

  // HTTP request handler for POST/PUT/DELETE operations (update function)
  public func http_request_update(request : Request) : async Response {
    let path = request.url;
    let method = request.method;

    if (method == "POST" and (path == "/api/products" or path == "/products")) {
      // Handle product creation
      // For this MVP, we'll create a sample product
      // In a production system, you'd parse the JSON from request.body
      let createRequest : ProductTypes.ProductInput = {
        name = "Vintage Camera";
        description = "Classic film camera in excellent condition, perfect for photography enthusiasts";
        price = 15000; // 150.00 in cents
        targetPrice = ?12000; // 120.00 target price
        minimumPrice = ?10000; // 100.00 minimum acceptable price
        categoryId = 1; // Electronics category
        condition = "Excellent";
        stock = 1;
        status = ?#active; // Set as active product
        imageBase64 = ?"data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k=";
        keySellingPoints = ["Excellent condition", "Comes with original case", "All functions working", "Rare vintage model"];
        knownFlaws = "Minor scratches on body, does not affect functionality";
        reasonForSelling = "Upgrading to digital camera";
        pickupDeliveryInfo = "Available for pickup in downtown area, shipping available";
      };

      // Use anonymous principal for API calls - in production you'd extract from auth headers
      let caller = Principal.fromText("2vxsx-fae");

      switch (productService.createProduct(createRequest, caller)) {
        case (#err(error)) {
          switch (error) {
            case (#CategoryNotFound) { errorResponse("Category not found") };
            case (#InvalidInput(msg)) { errorResponse("Invalid input: " # msg) };
            case (#Unauthorized) { errorResponse("Unauthorized") };
            case (#ProductNotFound) { errorResponse("Product not found") };
            case (#InsufficientStock) { errorResponse("Insufficient stock") };
          };
        };
        case (#ok(product)) {
          {
            status_code = 201; // Created
            headers = [("content-type", "application/json"), ("Access-Control-Allow-Origin", "*"), ("Access-Control-Allow-Methods", "GET, POST, OPTIONS"), ("Access-Control-Allow-Headers", "Content-Type")];
            body = Text.encodeUtf8(productToJson(product));
            streaming_strategy = null;
          };
        };
      };
    } else if (method == "OPTIONS") {
      // Handle CORS preflight
      {
        status_code = 200;
        headers = [("Access-Control-Allow-Origin", "*"), ("Access-Control-Allow-Methods", "GET, POST, OPTIONS"), ("Access-Control-Allow-Headers", "Content-Type")];
        body = Text.encodeUtf8("");
        streaming_strategy = null;
      };
    } else {
      errorResponse("Method not allowed or endpoint not found");
    };
  };
};
