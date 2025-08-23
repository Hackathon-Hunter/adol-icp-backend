// Simplified TypeScript interfaces for frontend integration
// Install required packages: npm install @dfinity/agent @dfinity/principal @dfinity/candid

// ==========================================
// BASIC TYPES
// ==========================================

export type ProductId = string; // SKU-based ID like "ELC001", "FSH001"
export type CategoryId = number;
export type UserId = string; // Principal as string
export type OrderId = number;
export type PaymentId = number;
export type BuyerId = string; // Principal as string
export type SellerId = string; // Principal as string
export type MatchId = number;

// ==========================================
// PRODUCT TYPES
// ==========================================

export interface Product {
  id: ProductId;
  name: string;
  description: string;
  price: number; // Price in smallest unit (e.g., cents)
  targetPrice: number;
  minimumPrice: number;
  categoryId: CategoryId;
  condition: string;
  imageBase64?: string; // Base64 encoded image (data:image/jpeg;base64,...)
  keySellingPoints: string[];
  knownFlaws: string;
  reasonForSelling: string;
  pickupDeliveryInfo: string;
  stock: number;
  isActive: boolean;
  createdAt: number;
  updatedAt: number;
  createdBy: string;
}

export interface CreateProductRequest {
  name: string;
  description: string;
  price: number;
  targetPrice: number;
  minimumPrice: number;
  categoryId: CategoryId;
  condition: string;
  imageBase64?: string; // Base64 encoded image data
  keySellingPoints: string[];
  knownFlaws: string;
  reasonForSelling: string;
  pickupDeliveryInfo: string;
  stock: number;
}

export interface UpdateProductRequest {
  name?: string;
  description?: string;
  price?: number;
  targetPrice?: number;
  minimumPrice?: number;
  categoryId?: CategoryId;
  condition?: string;
  imageBase64?: string; // Base64 encoded image data
  keySellingPoints?: string[];
  knownFlaws?: string;
  reasonForSelling?: string;
  pickupDeliveryInfo?: string;
  stock?: number;
  isActive?: boolean;
}

export interface Category {
  id: CategoryId;
  name: string;
  code: string; // 3-letter code for SKU generation (e.g., "ELC", "FSH", "HOM")
  description: string;
  isActive: boolean;
  createdAt: number;
}

export interface CreateCategoryRequest {
  name: string;
  code: string; // Must be 3 letters
  description: string;
}

// ==========================================
// USER TYPES
// ==========================================

export interface User {
  id: UserId;
  username: string;
  email: string;
  phone?: string;
  address?: Address;
  balance: number;
  isActive: boolean;
  createdAt: number;
  updatedAt: number;
}

export interface UserRegistration {
  username: string;
  email: string;
  phone?: string;
  address?: Address;
}

export interface UserUpdate {
  username?: string;
  email?: string;
  phone?: string;
  address?: Address;
}

export interface Address {
  street: string;
  city: string;
  state: string;
  country: string;
  postalCode: string;
}

// ==========================================
// ORDER TYPES
// ==========================================

export interface Order {
  id: OrderId;
  buyerId: UserId;
  items: OrderItem[];
  totalAmount: number;
  status: OrderStatus;
  shippingAddress: Address;
  createdAt: number;
  updatedAt: number;
}

export interface OrderItem {
  productId: ProductId;
  quantity: number;
  price: number;
}

export interface CreateOrderRequest {
  items: OrderItem[];
  shippingAddress: Address;
}

export type OrderStatus = 
  | 'Pending'
  | 'Confirmed'
  | 'Shipped'
  | 'Delivered'
  | 'Cancelled';

// ==========================================
// PAYMENT TYPES
// ==========================================

export interface Payment {
  id: PaymentId;
  orderId: OrderId;
  userId: UserId;
  amount: number;
  status: PaymentStatus;
  method: PaymentMethod;
  transactionId?: string;
  createdAt: number;
  updatedAt: number;
}

export type PaymentStatus = 
  | 'Pending'
  | 'Completed'
  | 'Failed'
  | 'Refunded';

export type PaymentMethod = 
  | 'ICP'
  | 'CKBTC'
  | 'CreditCard';

export interface PaymentConfig {
  simulationMode: boolean;
  platformAccount: string;
  minimumAmount: number;
}

// ==========================================
// BUYER MATCHING TYPES
// ==========================================

export interface BuyerProfile {
  id: BuyerId;
  name: string;
  email: string;
  phone?: string;
  location?: Address;
  budget: number;
  purchaseHistory: PurchaseRecord[];
  createdAt: number;
  updatedAt: number;
  isActive: boolean;
}

export interface SellerProfile {
  id: SellerId;
  businessName: string;
  description: string;
  location?: Address;
  contactEmail: string;
  contactPhone?: string;
  rating: number;
  totalSales: number;
  products: ProductId[];
  createdAt: number;
  updatedAt: number;
  isActive: boolean;
}

export interface PurchaseRecord {
  productId: ProductId;
  categoryId: CategoryId;
  price: number;
  purchaseDate: number;
}

export interface PotentialMatch {
  id: MatchId;
  buyerId: BuyerId;
  sellerId: SellerId;
  productId: ProductId;
  matchScore: number;
  matchReasons: MatchReason[];
  estimatedInterest: InterestLevel;
  recommendedAction: RecommendedAction;
  createdAt: number;
  isViewed: boolean;
  isInterested?: boolean;
}

export type MatchReason = 
  | 'BudgetMatch'
  | 'LocationMatch'
  | 'CategoryPreference'
  | 'PricePoint'
  | 'PastPurchase';

export type InterestLevel = 
  | 'High'
  | 'Medium'
  | 'Low';

export type RecommendedAction = 
  | 'ContactImmediately'
  | 'SendOffer'
  | 'Monitor'
  | 'NoAction';

// ==========================================
// API RESPONSE TYPES
// ==========================================

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  hasMore: boolean;
}

// ==========================================
// HTTP CLIENT CONFIGURATION
// ==========================================

export const CANISTER_CONFIG = {
  canisterId: 'ujk5g-liaaa-aaaam-aeocq-cai',
  host: 'https://icp0.io',
  gatewayUrl: 'https://ujk5g-liaaa-aaaam-aeocq-cai.raw.icp0.io'
} as const;

// ==========================================
// REST API ENDPOINTS
// ==========================================

export const API_ENDPOINTS = {
  // Products
  products: '/api/products',
  productDetail: (id: ProductId) => `/api/products/${id}`,
  
  // Categories
  categories: '/api/categories',
  categoryDetail: (id: CategoryId) => `/api/categories/${id}`,
  
  // System
  health: '/api/health',
  info: '/api/info',
  
  // Payment
  paymentConfig: '/api/payment-config',
  ownerAccount: '/api/owner-account',
  
  // Buyer Matching
  buyerProfiles: '/api/buyer-profiles',
  sellerProfiles: '/api/seller-profiles',
  matches: '/api/matches',
  
  // Root
  root: '/'
} as const;

// ==========================================
// HELPER FUNCTIONS
// ==========================================

export class AdolApiClient {
  private baseUrl: string;
  
  constructor(baseUrl: string = CANISTER_CONFIG.gatewayUrl) {
    this.baseUrl = baseUrl;
  }
  
  // GET requests (work with HTTP Gateway)
  async getProducts(): Promise<Product[]> {
    const response = await fetch(`${this.baseUrl}${API_ENDPOINTS.products}`);
    return response.json();
  }
  
  async getProduct(id: ProductId): Promise<Product> {
    const response = await fetch(`${this.baseUrl}${API_ENDPOINTS.productDetail(id)}`);
    return response.json();
  }
  
  async getCategories(): Promise<Category[]> {
    const response = await fetch(`${this.baseUrl}${API_ENDPOINTS.categories}`);
    return response.json();
  }
  
  async getBuyerProfiles(): Promise<BuyerProfile[]> {
    const response = await fetch(`${this.baseUrl}${API_ENDPOINTS.buyerProfiles}`);
    return response.json();
  }
  
  async getSellerProfiles(): Promise<SellerProfile[]> {
    const response = await fetch(`${this.baseUrl}${API_ENDPOINTS.sellerProfiles}`);
    return response.json();
  }
  
  async getMatches(): Promise<PotentialMatch[]> {
    const response = await fetch(`${this.baseUrl}${API_ENDPOINTS.matches}`);
    return response.json();
  }
  
  async getSystemInfo(): Promise<any> {
    const response = await fetch(`${this.baseUrl}${API_ENDPOINTS.info}`);
    return response.json();
  }
  
  async getHealth(): Promise<any> {
    const response = await fetch(`${this.baseUrl}${API_ENDPOINTS.health}`);
    return response.json();
  }
  
  // For POST/PUT/DELETE operations, you'll need to use the dfx canister call method
  // or implement proper IC agent integration
}

// ==========================================
// EXAMPLE USAGE
// ==========================================

/*
// Example usage in your React/Vue/Angular frontend:

import { AdolApiClient, Product, Category } from './types';

const api = new AdolApiClient();

// Get all products
const products: Product[] = await api.getProducts();

// Get specific product by SKU
const product: Product = await api.getProduct('ELC001');

// Get all categories
const categories: Category[] = await api.getCategories();

// For product creation (requires dfx or IC agent):
// dfx canister call adol-backend --network ic http_request_update '(record{
//   url="/api/products"; 
//   method="POST"; 
//   headers=vec{record{"Content-Type"; "application/json"}}; 
//   body=blob""
// })'

// Example product data structure matching your analysis:
const sampleProduct: CreateProductRequest = {
  name: "iPhone 14 Pro Max",
  description: "Excellent condition smartphone with all original accessories",
  price: 75000, // $750.00 in cents
  targetPrice: 70000, // $700.00 in cents  
  minimumPrice: 65000, // $650.00 in cents
  categoryId: 1, // Electronics
  condition: "Excellent",
  stock: 1,
  imageUrl: "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ...",
  keySellingPoints: [
    "Perfect working condition",
    "All original accessories included", 
    "No scratches or dents",
    "Battery health 95%"
  ],
  knownFlaws: "Minor wear on charging port, does not affect functionality",
  reasonForSelling: "Upgrading to newer model",
  pickupDeliveryInfo: "Available for local pickup or nationwide shipping"
};
*/

export default AdolApiClient;
