import ProductTypes "./ProductTypes";
import UserTypes "./UserTypes";

module {
    public type OrderId = Nat;
    
    public type OrderStatus = {
        #Pending;
        #Confirmed;
        #Processing;
        #Shipped;
        #Delivered;
        #Cancelled;
        #Refunded;
    };
    
    public type OrderItem = {
        productId: ProductTypes.ProductId;
        quantity: Nat;
        pricePerUnit: Nat;
        totalPrice: Nat;
    };
    
    public type Order = {
        id: OrderId;
        userId: UserTypes.UserId;
        items: [OrderItem];
        totalAmount: Nat;
        status: OrderStatus;
        shippingAddress: UserTypes.Address;
        createdAt: Int;
        updatedAt: Int;
        completedAt: ?Int;
    };
    
    public type OrderInput = {
        items: [OrderItemInput];
        shippingAddress: UserTypes.Address;
    };
    
    public type OrderItemInput = {
        productId: ProductTypes.ProductId;
        quantity: Nat;
    };
    
    public type OrderError = {
        #OrderNotFound;
        #InvalidOrderStatus;
        #InsufficientBalance;
        #InsufficientStock;
        #InvalidInput: Text;
        #Unauthorized;
        #ProductNotFound;
        #EmptyCart;
    };
}
