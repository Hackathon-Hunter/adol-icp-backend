# Adol E-commerce Platform

A decentralized e-commerce platform built on the Internet Computer Protocol (ICP) using Motoko.

## 🚀 Features

### User Management
- User registration and authentication via ICP Principal
- Profile management with contact details and addresses
- ICP balance management with top-up functionality
- Payment history tracking

### Product Management
- **Product Status System**: `active`, `draft`, `sold`
- Product catalog with categories
- Complete product CRUD operations
- Stock management with automatic deduction
- Rich product details (condition, selling points, flaws, pickup info)
- Incremental product IDs (`product_1`, `product_2`, etc.)

### Order Processing
- Shopping cart functionality
- Order creation with multiple items
- Order status tracking (`pending`, `confirmed`, `shipped`, `delivered`, `cancelled`)
- Order cancellation with automatic refunds
- Inventory management integration

### Payment System
- ICP token integration
- Multiple top-up methods (simulation mode & real ICP transfers)
- Automatic balance deduction for orders
- Payment transaction records
- Balance verification and validation

### HTTP API Endpoints
- RESTful API accessible via HTTP Gateway
- JSON responses for easy frontend integration
- CORS support for web applications
- Comprehensive error handling

## 🏗️ Architecture

```
src/
├── backend/
│   ├── main.mo              # Main canister with HTTP handlers
│   ├── types/               # Type definitions
│   │   ├── UserTypes.mo
│   │   ├── ProductTypes.mo
│   │   ├── OrderTypes.mo
│   │   └── PaymentTypes.mo
│   ├── storage/             # Data persistence layer
│   │   ├── UserStorage.mo
│   │   ├── ProductStorage.mo
│   │   ├── OrderStorage.mo
│   │   └── PaymentStorage.mo
│   └── services/            # Business logic layer
│       ├── UserService.mo
│       ├── ProductService.mo
│       ├── OrderService.mo
│       └── PaymentService.mo
├── declarations/            # Generated type definitions
└── frontend/                # Frontend type definitions
```

## 🛠️ Local Development Setup

### Prerequisites

1. **Install DFX (Internet Computer SDK)**
   ```bash
   sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"
   ```

2. **Install Mops (Motoko Package Manager)**
   ```bash
   npm install -g mops
   ```

3. **Verify Installation**
   ```bash
   dfx --version
   mops --version
   ```

### 🚀 Quick Start

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd plantify-icp-backend
   ```

2. **Install Dependencies**
   ```bash
   mops install
   ```

3. **Start Local IC Replica**
   ```bash
   dfx start --clean --background
   ```

4. **Deploy Canister Locally**
   ```bash
   dfx deploy adol-backend --mode install
   ```

5. **Test the Deployment**
   ```bash
   dfx canister call adol-backend health
   ```

### 🔧 Development Commands

#### Build Only
```bash
dfx build adol-backend
```

#### Deploy with Upgrade (preserves state)
```bash
dfx deploy adol-backend --mode upgrade
```

#### Deploy with Reinstall (resets state)
```bash
dfx deploy adol-backend --mode install
```

#### Generate Type Declarations
```bash
dfx generate adol-backend
```

#### Stop Local Replica
```bash
dfx stop
```

### 🌐 Local URLs

After successful deployment, access your canister at:

- **Candid UI**: `http://localhost:4943/?canisterId={canister-id}&id={adol-backend-id}`
- **HTTP Gateway**: `http://{canister-id}.localhost:4943/`

Get your canister ID:
```bash
dfx canister id adol-backend
```

## 📚 API Reference

### Product Status Management

```bash
# Create active product
dfx canister call adol-backend createProduct '(record {
  name = "Coffee Grinder";
  description = "High-quality grinder";
  price = 1500000;
  categoryId = 1;
  condition = "Excellent";
  stock = 1;
  status = opt variant { active };
  keySellingPoints = vec {"Durable build"};
  knownFlaws = "None";
  reasonForSelling = "Upgrade";
  pickupDeliveryInfo = "Pickup available"
})'

# Get products by status
dfx canister call adol-backend getProducts        # Active only
dfx canister call adol-backend getDraftProducts   # Draft only
dfx canister call adol-backend getSoldProducts    # Sold only
dfx canister call adol-backend getAllProducts     # All products

# Change product status
dfx canister call adol-backend markProductAsSold '("product_1")'
dfx canister call adol-backend publishProduct '("product_1")'
dfx canister call adol-backend markProductAsDraft '("product_1")'
```

### HTTP API Examples

```bash
# Get all active products
curl http://{canister-id}.localhost:4943/api/products

# Get specific product (without imageBase64)
curl http://{canister-id}.localhost:4943/api/products/product_1

# Get draft products
curl http://{canister-id}.localhost:4943/api/products/draft

# Get sold products
curl http://{canister-id}.localhost:4943/api/products/sold

# Get all products
curl http://{canister-id}.localhost:4943/api/products/all

# Get categories
curl http://{canister-id}.localhost:4943/api/categories

# Health check
curl http://{canister-id}.localhost:4943/api/health
```

### User Management

```bash
# Register user
dfx canister call adol-backend registerUser '(record {
  email = "user@example.com";
  name = "John Doe";
  phone = opt "123-456-7890";
  address = opt record {
    street = "123 Main St";
    city = "Jakarta";
    state = "DKI";
    zipCode = "12345";
    country = "Indonesia"
  }
})'

# Get user profile
dfx canister call adol-backend getProfile

# Check balance
dfx canister call adol-backend getBalance
```

### Order Management

```bash
# Create order
dfx canister call adol-backend createOrder '(record {
  items = vec {
    record { productId = "product_1"; quantity = 1 }
  };
  shippingAddress = record {
    street = "123 Main St";
    city = "Jakarta";
    state = "DKI";
    zipCode = "12345";
    country = "Indonesia"
  }
})'

# Get user orders
dfx canister call adol-backend getMyOrders
```

## 🧪 Testing

### Create Test Data

```bash
# Create category
dfx canister call adol-backend createCategory '(record {
  name = "Electronics";
  code = "ELC";
  description = "Electronic devices"
})'

# Create test products
dfx canister call adol-backend createProduct '(record {
  name = "Laptop";
  description = "Gaming laptop";
  price = 15000000;
  targetPrice = opt 14000000;
  minimumPrice = opt 13000000;
  categoryId = 1;
  condition = "Excellent";
  stock = 5;
  status = opt variant { active };
  keySellingPoints = vec {"Fast processor"; "Good graphics"};
  knownFlaws = "Minor wear";
  reasonForSelling = "Upgrade";
  pickupDeliveryInfo = "Jakarta area"
})'
```

### Test Product Status Flow

```bash
# 1. Create draft product
dfx canister call adol-backend createProduct '(..., status = opt variant { draft })'

# 2. Publish draft (make active)
dfx canister call adol-backend publishProduct '("product_1")'

# 3. Mark as sold
dfx canister call adol-backend markProductAsSold '("product_1")'

# 4. Verify status changes
dfx canister call adol-backend getDraftProducts
dfx canister call adol-backend getProducts
dfx canister call adol-backend getSoldProducts
```

## 🌍 Deployment to IC Mainnet

1. **Get Cycles** (required for mainnet deployment)
   ```bash
   dfx ledger account-id
   dfx ledger --network ic balance
   ```

2. **Deploy to Mainnet**
   ```bash
   dfx deploy adol-backend --network ic --no-wallet
   ```

3. **Access Mainnet Canister**
   - Candid UI: `https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.icp0.io/?id={your-canister-id}`
   - HTTP API: `https://{your-canister-id}.raw.icp0.io/api/products`

## 🐛 Troubleshooting

### Common Issues

1. **"Cannot fetch Candid interface" Error**
   ```bash
   dfx generate adol-backend
   ```

2. **"Canister not found" Error**
   ```bash
   dfx canister create adol-backend
   dfx deploy adol-backend
   ```

3. **Build Failures**
   ```bash
   dfx start --clean
   mops install
   dfx build adol-backend
   ```

4. **Out of Cycles (Mainnet)**
   - Check balance: `dfx ledger --network ic balance`
   - Top up: `dfx ledger --network ic top-up {canister-id} --amount {amount}`

### Debug Mode

```bash
# Start with verbose logging
dfx start --verbose

# Check canister logs
dfx canister logs adol-backend
```

## 📝 API Wrapper (Optional)

The project includes an Express.js API wrapper in `/api-wrapper/` for easier HTTP integration:

```bash
cd api-wrapper
npm install
npm start
```

This provides RESTful endpoints at `http://localhost:3001/products`, etc.

## 🔐 Security Notes

- All sensitive operations require user authentication via ICP Principal
- Balance verification before any transaction
- Stock validation to prevent overselling
- Proper error handling without sensitive data exposure
- CORS configuration for secure web integration

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with `dfx start` and `dfx deploy`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.
