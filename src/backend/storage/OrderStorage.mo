import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import OrderTypes "../types/OrderTypes";
import UserTypes "../types/UserTypes";

module {
  public type OrderStorage = {
    orders : HashMap.HashMap<OrderTypes.OrderId, OrderTypes.Order>;
    var nextOrderId : Nat;
  };

  public func init() : OrderStorage {
    {
      orders = HashMap.HashMap<OrderTypes.OrderId, OrderTypes.Order>(0, Nat.equal, func(x : Nat) : Hash.Hash { Nat32.fromNat(x) });
      var nextOrderId = 1;
    };
  };

    public func createOrder(
        storage: OrderStorage,
        userId: Principal,
        orderItems: [OrderTypes.OrderItem],
        shippingAddress: UserTypes.Address,
        totalAmount: Nat
    ) : OrderTypes.Order {
        let orderId = storage.nextOrderId;
        storage.nextOrderId += 1;
        
        let order: OrderTypes.Order = {
            id = orderId;
            userId = userId;
            items = orderItems;
            totalAmount = totalAmount;
            status = #Pending;
            shippingAddress = shippingAddress;
            createdAt = Time.now();
            updatedAt = Time.now();
            completedAt = null;
        };
        
        storage.orders.put(orderId, order);
        order
    };  public func getOrder(storage : OrderStorage, orderId : OrderTypes.OrderId) : ?OrderTypes.Order {
    storage.orders.get(orderId);
  };

  public func updateOrderStatus(
    storage : OrderStorage,
    orderId : OrderTypes.OrderId,
    newStatus : OrderTypes.OrderStatus,
  ) : Result.Result<OrderTypes.Order, OrderTypes.OrderError> {
    switch (storage.orders.get(orderId)) {
      case null { #err(#OrderNotFound) };
      case (?order) {
        let completedAt = switch (newStatus) {
          case (#Delivered or #Cancelled or #Refunded) { ?Time.now() };
          case _ { order.completedAt };
        };

        let updatedOrder : OrderTypes.Order = {
          order with
          status = newStatus;
          updatedAt = Time.now();
          completedAt = completedAt;
        };

        storage.orders.put(orderId, updatedOrder);
        #ok(updatedOrder);
      };
    };
  };

  public func getUserOrders(storage : OrderStorage, userId : Principal) : [OrderTypes.Order] {
    storage.orders.vals()
    |> Iter.filter(_, func(order : OrderTypes.Order) : Bool { order.userId == userId })
    |> Iter.toArray(_);
  };

  public func getAllOrders(storage : OrderStorage) : [OrderTypes.Order] {
    storage.orders.vals() |> Iter.toArray(_);
  };

  public func getOrdersByStatus(storage : OrderStorage, status : OrderTypes.OrderStatus) : [OrderTypes.Order] {
    storage.orders.vals()
    |> Iter.filter(_, func(order : OrderTypes.Order) : Bool { order.status == status })
    |> Iter.toArray(_);
  };
};
