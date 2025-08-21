# Adol E-commerce Platform

A decentralized e-commerce platform built on the Internet Computer Protocol (ICP) using Motoko.

## Features

### User Management
- User registration and authentication
- Profile management
- ICP balance management with top-up functionality

### Product Management
- Product catalog with categories
- Product CRUD operations
- Stock management
- Image support

### Order Processing
- Shopping cart functionality
- Order creation and management
- Order status tracking
- Order cancellation with automatic refunds

### Payment System
- ICP token integration
- Top-up functionality
- Payment history tracking
- Automatic balance deduction for orders

## Architecture

### Types
- `UserTypes.mo` - User and authentication related types
- `ProductTypes.mo` - Product and category types
- `OrderTypes.mo` - Order and order item types
- `PaymentTypes.mo` - Payment and transaction types

### Storage
- `UserStorage.mo` - User data persistence
- `ProductStorage.mo` - Product and category data
- `OrderStorage.mo` - Order data management
- `PaymentStorage.mo` - Payment transaction records

### Services
- `UserService.mo` - User business logic
- `ProductService.mo` - Product management logic
- `OrderService.mo` - Order processing logic
- `PaymentService.mo` - Payment processing logic

## API Endpoints

### User Management
- `registerUser(registration)` - Register a new user
- `getProfile()` - Get current user profile
- `updateProfile(update)` - Update user profile
- `getBalance()` - Get user's ICP balance

### Payment Management
- `topUpBalance(request)` - Add ICP to user balance
- `getPayment(paymentId)` - Get payment details
- `getMyPayments()` - Get user's payment history

### Product Management
- `getProducts()` - Get all active products
- `getProduct(productId)` - Get specific product
- `getCategories()` - Get all categories
- `getProductsByCategory(categoryId)` - Get products by category

### Order Management
- `createOrder(input)` - Create a new order
- `getOrder(orderId)` - Get order details
- `getMyOrders()` - Get user's orders
- `cancelOrder(orderId)` - Cancel an order

### Admin Functions
- `createCategory(input)` - Create product category
- `createProduct(input)` - Create new product
- `updateProduct(productId, update)` - Update product
- `updateOrderStatus(orderId, status)` - Update order status
- `getAllUsers()` - Get all users (admin)
- `getAllOrders()` - Get all orders (admin)
- `getAllProducts()` - Get all products (admin)
- `getAllPayments()` - Get all payments (admin)

### System Functions
- `getInfo()` - Get platform information
- `health()` - Health check endpoint

## Getting Started

1. Install DFX (IC SDK)
2. Clone this repository
3. Start local IC replica: `dfx start`
4. Deploy the canister: `dfx deploy`

## Usage Example

```motoko
// Register a new user
let registration = {
    email = "user@example.com";
    name = "John Doe";
    phone = ?"123-456-7890";
    address = ?{
        street = "123 Main St";
        city = "Anytown";
        state = "CA";
        zipCode = "12345";
        country = "USA";
    };
};

let userResult = await platform.registerUser(registration);

// Top up balance
let topUpRequest = { amount = 1000000 }; // 0.01 ICP
let paymentResult = await platform.topUpBalance(topUpRequest);

// Create an order
let orderInput = {
    items = [{
        productId = 1;
        quantity = 2;
    }];
    shippingAddress = {
        street = "123 Main St";
        city = "Anytown";
        state = "CA";
        zipCode = "12345";
        country = "USA";
    };
};

let orderResult = await platform.createOrder(orderInput);
```

## Error Handling

The platform includes comprehensive error handling for:
- User authentication and authorization
- Insufficient balances
- Stock management
- Invalid inputs
- Order state management

## Security Features

- Principal-based authentication
- User authorization for sensitive operations
- Balance verification before transactions
- Stock validation before order processing
- Proper error messages without sensitive data exposure

## Development

### Prerequisites
- DFX SDK
- Motoko compiler
- Internet Computer local replica

### Building
```bash
dfx build adol-backend
```

### Testing
```bash
dfx deploy adol-backend
dfx canister call adol-backend health
```

## License

This project is licensed under the MIT License.
