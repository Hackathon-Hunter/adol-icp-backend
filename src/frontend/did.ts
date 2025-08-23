import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

// Basic Types
export type ProductId = string; // SKU-based ID like "ELC001"
export type CategoryId = bigint;
export type UserId = Principal;
export type OrderId = bigint;
export type PaymentId = bigint;
export type BuyerId = Principal;
export type SellerId = Principal;
export type MatchId = bigint;

// Product Types
export interface Product {
  id: ProductId;
  name: string;
  description: string;
  price: bigint; // Price in smallest unit (e.g., cents)
  targetPrice: bigint;
  minimumPrice: bigint;
  categoryId: CategoryId;
  condition: string;
  imageUrl: [] | [string];
  keySellingPoints: Array<string>;
  knownFlaws: string;
  reasonForSelling: string;
  pickupDeliveryInfo: string;
  stock: bigint;
  isActive: boolean;
  createdAt: bigint;
  updatedAt: bigint;
  createdBy: Principal;
}

export interface ProductInput {
  name: string;
  description: string;
  price: bigint;
  targetPrice: bigint;
  minimumPrice: bigint;
  categoryId: CategoryId;
  condition: string;
  imageUrl: [] | [string];
  keySellingPoints: Array<string>;
  knownFlaws: string;
  reasonForSelling: string;
  pickupDeliveryInfo: string;
  stock: bigint;
}

export interface ProductUpdate {
  name: [] | [string];
  description: [] | [string];
  price: [] | [bigint];
  targetPrice: [] | [bigint];
  minimumPrice: [] | [bigint];
  categoryId: [] | [CategoryId];
  condition: [] | [string];
  imageUrl: [] | [string];
  keySellingPoints: [] | [Array<string>];
  knownFlaws: [] | [string];
  reasonForSelling: [] | [string];
  pickupDeliveryInfo: [] | [string];
  stock: [] | [bigint];
  isActive: [] | [boolean];
}

export interface Category {
  id: CategoryId;
  name: string;
  code: string; // 3-letter code for SKU generation
  description: string;
  isActive: boolean;
  createdAt: bigint;
}

export interface CategoryInput {
  name: string;
  code: string;
  description: string;
}

// User Types
export interface User {
  id: UserId;
  username: string;
  email: string;
  phone: [] | [string];
  address: [] | [Address];
  balance: bigint;
  isActive: boolean;
  createdAt: bigint;
  updatedAt: bigint;
}

export interface UserRegistration {
  username: string;
  email: string;
  phone: [] | [string];
  address: [] | [Address];
}

export interface UserUpdate {
  username: [] | [string];
  email: [] | [string];
  phone: [] | [string];
  address: [] | [Address];
}

export interface Address {
  street: string;
  city: string;
  state: string;
  country: string;
  postalCode: string;
}

// Order Types
export interface Order {
  id: OrderId;
  buyerId: UserId;
  items: Array<OrderItem>;
  totalAmount: bigint;
  status: OrderStatus;
  shippingAddress: Address;
  createdAt: bigint;
  updatedAt: bigint;
}

export interface OrderItem {
  productId: ProductId;
  quantity: bigint;
  price: bigint;
}

export interface CreateOrderRequest {
  items: Array<OrderItem>;
  shippingAddress: Address;
}

export type OrderStatus = 
  | { 'Pending': null }
  | { 'Confirmed': null }
  | { 'Shipped': null }
  | { 'Delivered': null }
  | { 'Cancelled': null };

// Payment Types
export interface Payment {
  id: PaymentId;
  orderId: OrderId;
  userId: UserId;
  amount: bigint;
  status: PaymentStatus;
  method: PaymentMethod;
  transactionId: [] | [string];
  createdAt: bigint;
  updatedAt: bigint;
}

export type PaymentStatus = 
  | { 'Pending': null }
  | { 'Completed': null }
  | { 'Failed': null }
  | { 'Refunded': null };

export type PaymentMethod = 
  | { 'ICP': null }
  | { 'CKBTC': null }
  | { 'CreditCard': null };

export interface PaymentConfig {
  simulationMode: boolean;
  platformAccount: Principal;
  minimumAmount: bigint;
}

// Buyer Match Types
export interface BuyerProfile {
  id: BuyerId;
  name: string;
  email: string;
  phone: [] | [string];
  location: [] | [Address];
  budget: bigint;
  purchaseHistory: Array<PurchaseRecord>;
  createdAt: bigint;
  updatedAt: bigint;
  isActive: boolean;
}

export interface SellerProfile {
  id: SellerId;
  businessName: string;
  description: string;
  location: [] | [Address];
  contactEmail: string;
  contactPhone: [] | [string];
  rating: number;
  totalSales: bigint;
  products: Array<ProductId>;
  createdAt: bigint;
  updatedAt: bigint;
  isActive: boolean;
}

export interface PurchaseRecord {
  productId: ProductId;
  categoryId: CategoryId;
  price: bigint;
  purchaseDate: bigint;
}

export interface PotentialMatch {
  id: MatchId;
  buyerId: BuyerId;
  sellerId: SellerId;
  productId: ProductId;
  matchScore: number;
  matchReasons: Array<MatchReason>;
  estimatedInterest: InterestLevel;
  recommendedAction: RecommendedAction;
  createdAt: bigint;
  isViewed: boolean;
  isInterested: [] | [boolean];
}

export type MatchReason = 
  | { 'BudgetMatch': null }
  | { 'LocationMatch': null }
  | { 'CategoryPreference': null }
  | { 'PricePoint': null }
  | { 'PastPurchase': null };

export type InterestLevel = 
  | { 'High': null }
  | { 'Medium': null }
  | { 'Low': null };

export type RecommendedAction = 
  | { 'ContactImmediately': null }
  | { 'SendOffer': null }
  | { 'Monitor': null }
  | { 'NoAction': null };

// Error Types
export type UserError = 
  | { 'UserNotFound': null }
  | { 'UserAlreadyExists': null }
  | { 'InvalidInput': string }
  | { 'InsufficientBalance': null }
  | { 'Unauthorized': null };

export type ProductError = 
  | { 'ProductNotFound': null }
  | { 'CategoryNotFound': null }
  | { 'InvalidInput': string }
  | { 'InsufficientStock': null }
  | { 'Unauthorized': null };

export type OrderError = 
  | { 'OrderNotFound': null }
  | { 'ProductNotFound': null }
  | { 'InsufficientStock': null }
  | { 'InvalidInput': string }
  | { 'InsufficientBalance': null }
  | { 'Unauthorized': null };

export type PaymentError = 
  | { 'PaymentNotFound': null }
  | { 'InsufficientBalance': null }
  | { 'InvalidAmount': null }
  | { 'TransferFailed': string }
  | { 'Unauthorized': null };

// Result Types
export type Result<T, E> = { 'ok': T } | { 'err': E };

// HTTP Types for Gateway
export interface HeaderField {
  0: string;
  1: string;
}

export interface HttpRequest {
  body: Uint8Array | number[];
  headers: Array<HeaderField>;
  method: string;
  url: string;
}

export interface HttpResponse {
  body: Uint8Array | number[];
  headers: Array<HeaderField>;
  status_code: number;
  streaming_strategy: [] | [any];
}

// Main Actor Interface
export interface _SERVICE {
  // User Management
  'registerUser': ActorMethod<[UserRegistration], Result<User, UserError>>;
  'getProfile': ActorMethod<[], Result<User, UserError>>;
  'updateProfile': ActorMethod<[UserUpdate], Result<User, UserError>>;
  'getBalance': ActorMethod<[], Result<bigint, UserError>>;
  'topUpBalance': ActorMethod<[bigint], Result<bigint, UserError>>;
  'topUpBalanceWithICP': ActorMethod<[bigint], Result<bigint, UserError>>;
  'getOwnerICPAccount': ActorMethod<[], {
    account: string;
    principal: Principal;
    minimumAmount: bigint;
    instructions: string;
  }>;

  // Product Management
  'getProducts': ActorMethod<[], Array<Product>>;
  'getProduct': ActorMethod<[ProductId], Result<Product, ProductError>>;
  'createProduct': ActorMethod<[ProductInput], Result<Product, ProductError>>;
  'updateProduct': ActorMethod<[ProductId, ProductUpdate], Result<Product, ProductError>>;
  'deleteProduct': ActorMethod<[ProductId], Result<boolean, ProductError>>;
  'getProductsByCategory': ActorMethod<[CategoryId], Array<Product>>;

  // Category Management
  'getCategories': ActorMethod<[], Array<Category>>;
  'getCategory': ActorMethod<[CategoryId], Result<Category, ProductError>>;
  'createCategory': ActorMethod<[CategoryInput], Category>;

  // Order Management
  'createOrder': ActorMethod<[CreateOrderRequest], Result<Order, OrderError>>;
  'getOrder': ActorMethod<[OrderId], Result<Order, OrderError>>;
  'getMyOrders': ActorMethod<[], Array<Order>>;
  'updateOrderStatus': ActorMethod<[OrderId, OrderStatus], Result<Order, OrderError>>;

  // Payment Management
  'createPayment': ActorMethod<[OrderId, PaymentMethod], Result<Payment, PaymentError>>;
  'getPayment': ActorMethod<[PaymentId], Result<Payment, PaymentError>>;
  'getMyPayments': ActorMethod<[], Array<Payment>>;
  'getPaymentConfig': ActorMethod<[], PaymentConfig>;
  'getMyDepositInfo': ActorMethod<[], {
    balance: bigint;
    pendingDeposits: Array<any>;
    minimumTopUp: bigint;
  }>;

  // Buyer Matching System
  'createBuyerProfile': ActorMethod<[string, string, [] | [string], [] | [Address], bigint], Result<BuyerProfile, string>>;
  'updateBuyerProfile': ActorMethod<[string, [] | [string], [] | [Address], [] | [bigint]], Result<BuyerProfile, string>>;
  'getBuyerProfile': ActorMethod<[BuyerId], Result<BuyerProfile, string>>;
  'getAllBuyerProfiles': ActorMethod<[], Array<BuyerProfile>>;
  'createSellerProfile': ActorMethod<[string, string, [] | [Address], string, [] | [string]], Result<SellerProfile, string>>;
  'updateSellerProfile': ActorMethod<[string, [] | [string], [] | [Address], [] | [string], [] | [string]], Result<SellerProfile, string>>;
  'getSellerProfile': ActorMethod<[SellerId], Result<SellerProfile, string>>;
  'getAllSellerProfiles': ActorMethod<[], Array<SellerProfile>>;
  'addPurchaseRecord': ActorMethod<[PurchaseRecord], Result<BuyerProfile, string>>;
  'findMatches': ActorMethod<[ProductId], Array<PotentialMatch>>;
  'getAllMatches': ActorMethod<[], Array<PotentialMatch>>;
  'markMatchAsViewed': ActorMethod<[MatchId], Result<PotentialMatch, string>>;
  'markMatchInterest': ActorMethod<[MatchId, boolean], Result<PotentialMatch, string>>;

  // HTTP Gateway
  'http_request': ActorMethod<[HttpRequest], HttpResponse>;
  'http_request_update': ActorMethod<[HttpRequest], HttpResponse>;

  // System Information
  'getSystemInfo': ActorMethod<[], {
    version: string;
    totalUsers: bigint;
    totalProducts: bigint;
    totalOrders: bigint;
    totalPayments: bigint;
  }>;
}

// Actor Factory
export const idlFactory: IDL.InterfaceFactory = ({ IDL }) => {
  // Define all the IDL types here
  const ProductId = IDL.Text;
  const CategoryId = IDL.Nat;
  const UserId = IDL.Principal;
  
  // ... (IDL definitions would continue here)
  
  return IDL.Service({
    'registerUser': IDL.Func([IDL.Record({
      username: IDL.Text,
      email: IDL.Text,
      phone: IDL.Opt(IDL.Text),
      address: IDL.Opt(IDL.Record({
        street: IDL.Text,
        city: IDL.Text,
        state: IDL.Text,
        country: IDL.Text,
        postalCode: IDL.Text,
      })),
    })], [IDL.Variant({
      ok: IDL.Record({
        id: UserId,
        username: IDL.Text,
        email: IDL.Text,
        phone: IDL.Opt(IDL.Text),
        address: IDL.Opt(IDL.Record({
          street: IDL.Text,
          city: IDL.Text,
          state: IDL.Text,
          country: IDL.Text,
          postalCode: IDL.Text,
        })),
        balance: IDL.Nat,
        isActive: IDL.Bool,
        createdAt: IDL.Int,
        updatedAt: IDL.Int,
      }),
      err: IDL.Variant({
        UserNotFound: IDL.Null,
        UserAlreadyExists: IDL.Null,
        InvalidInput: IDL.Text,
        InsufficientBalance: IDL.Null,
        Unauthorized: IDL.Null,
      }),
    })], []),
    
    'getProducts': IDL.Func([], [IDL.Vec(IDL.Record({
      id: ProductId,
      name: IDL.Text,
      description: IDL.Text,
      price: IDL.Nat,
      targetPrice: IDL.Nat,
      minimumPrice: IDL.Nat,
      categoryId: CategoryId,
      condition: IDL.Text,
      imageUrl: IDL.Opt(IDL.Text),
      keySellingPoints: IDL.Vec(IDL.Text),
      knownFlaws: IDL.Text,
      reasonForSelling: IDL.Text,
      pickupDeliveryInfo: IDL.Text,
      stock: IDL.Nat,
      isActive: IDL.Bool,
      createdAt: IDL.Int,
      updatedAt: IDL.Int,
      createdBy: IDL.Principal,
    }))], ['query']),
    
    'http_request': IDL.Func([IDL.Record({
      body: IDL.Vec(IDL.Nat8),
      headers: IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text)),
      method: IDL.Text,
      url: IDL.Text,
    })], [IDL.Record({
      body: IDL.Vec(IDL.Nat8),
      headers: IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text)),
      status_code: IDL.Nat16,
      streaming_strategy: IDL.Opt(IDL.Null),
    })], ['query']),
    
    'http_request_update': IDL.Func([IDL.Record({
      body: IDL.Vec(IDL.Nat8),
      headers: IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text)),
      method: IDL.Text,
      url: IDL.Text,
    })], [IDL.Record({
      body: IDL.Vec(IDL.Nat8),
      headers: IDL.Vec(IDL.Tuple(IDL.Text, IDL.Text)),
      status_code: IDL.Nat16,
      streaming_strategy: IDL.Opt(IDL.Null),
    })], []),
    
    // Add more function definitions as needed...
  });
};

// Canister ID
export const canisterId = process.env.CANISTER_ID_ADOL_BACKEND || 'ujk5g-liaaa-aaaam-aeocq-cai';

// Default export for easy importing
export default { idlFactory, canisterId };
