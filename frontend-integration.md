# Frontend Integration Guide

## Generated TypeScript Declarations

The TypeScript declarations have been generated and are available in:
- `src/declarations/adol-backend/adol-backend.did.d.ts` - All type definitions
- `src/declarations/adol-backend/index.d.ts` - Actor interface
- `src/declarations/adol-backend/index.js` - JavaScript actor factory

## Canister Information

- **Canister ID**: `ujk5g-liaaa-aaaam-aeocq-cai`
- **Network**: IC Mainnet
- **HTTP Gateway**: `https://ujk5g-liaaa-aaaam-aeocq-cai.raw.icp0.io`

## Installation

```bash
npm install @dfinity/agent @dfinity/candid @dfinity/principal
```

## Usage Examples

### 1. Basic Setup

```typescript
import { createActor, canisterId } from './declarations/adol-backend';
import { HttpAgent } from '@dfinity/agent';

// For IC mainnet
const agent = new HttpAgent({
  host: 'https://ic0.app',
});

const actor = createActor(canisterId, {
  agent,
});
```

### 2. Product Operations

```typescript
// Get all products
const products = await actor.getProducts();

// Get specific product by SKU
const product = await actor.getProduct('ELC001');

// Create product (requires authentication)
const productInput = {
  name: 'iPhone 15 Pro',
  description: 'Latest Apple smartphone',
  price: BigInt(99900), // Price in cents
  targetPrice: BigInt(95000),
  minimumPrice: BigInt(90000),
  categoryId: BigInt(1),
  condition: 'Excellent',
  stock: BigInt(1),
  imageUrl: ['https://example.com/image.jpg'],
  keySellingPoints: ['Perfect condition', 'All accessories included'],
  knownFlaws: ['Minor wear on case'],
  reasonForSelling: ['Upgrading to newer model'],
  pickupDeliveryInfo: ['Local pickup available']
};

const result = await actor.createProduct(productInput);
```

### 3. Category Operations

```typescript
// Get all categories
const categories = await actor.getCategories();

// Create category
const categoryInput = {
  name: 'Home & Garden',
  description: 'Home and garden items',
  code: 'HOM'
};

const category = await actor.createCategory(categoryInput);
```

### 4. REST API Endpoints (Direct HTTP)

For simple GET requests, you can use direct HTTP calls:

```typescript
// Get products via REST API
const response = await fetch('https://ujk5g-liaaa-aaaam-aeocq-cai.raw.icp0.io/api/products');
const products = await response.json();

// Get specific product
const productResponse = await fetch('https://ujk5g-liaaa-aaaam-aeocq-cai.raw.icp0.io/api/products/ELC001');
const product = await productResponse.json();

// Get categories
const categoriesResponse = await fetch('https://ujk5g-liaaa-aaaam-aeocq-cai.raw.icp0.io/api/categories');
const categories = await categoriesResponse.json();
```

### 5. React Hook Example

```typescript
import { useState, useEffect } from 'react';
import { createActor } from './declarations/adol-backend';

export const useProducts = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchProducts = async () => {
      try {
        const actor = createActor(process.env.REACT_APP_CANISTER_ID);
        const result = await actor.getProducts();
        setProducts(result);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchProducts();
  }, []);

  return { products, loading, error };
};
```

## Key Features

✅ **SKU-based Product IDs**: Products use meaningful IDs like "ELC001", "FSH001"
✅ **REST API Support**: Direct HTTP access via IC HTTP Gateway
✅ **Comprehensive Product Data**: Includes pricing, condition, selling points, flaws
✅ **Category Management**: Categories with codes for SKU generation
✅ **Type Safety**: Full TypeScript support with generated types
✅ **Buyer/Seller Matching**: Advanced matching system for e-commerce
✅ **Payment Integration**: ICP-based payment system

## Product Data Structure

Products include the following comprehensive fields:
- Basic info: name, description, price
- Pricing strategy: target price, minimum price
- Condition and quality information
- Key selling points and known flaws
- Seller information: reason for selling, pickup/delivery info
- Stock management and category assignment

## Available Endpoints

### Direct HTTP (GET only):
- `GET /api/products` - List all products
- `GET /api/products/{sku}` - Get product by SKU
- `GET /api/categories` - List all categories
- `GET /api/health` - Health check
- `GET /api/info` - Platform information

### Actor Methods (Full CRUD):
- Product management: create, read, update, delete
- Category management
- User management
- Order processing
- Payment handling
- Buyer/seller matching

Copy the `src/declarations` folder to your frontend project to get started!
