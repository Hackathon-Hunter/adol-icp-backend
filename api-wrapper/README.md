# Adol E-commerce REST API Wrapper

This is a REST API wrapper for the Adol E-commerce canister deployed on the Internet Computer.

## Canister Information
- **Canister ID**: `ujk5g-liaaa-aaaam-aeocq-cai`
- **Network**: Internet Computer Mainnet

## Setup

1. Install dependencies:
```bash
cd api-wrapper
npm install
```

2. Start the server:
```bash
npm start
```

For development with auto-reload:
```bash
npm run dev
```

## API Endpoints

### Health & System Info
- `GET /health` - Check canister health status
- `GET /info` - Get system information

### Products
- `GET /products` - Get all active products
- `GET /products/:id` - Get specific product by ID
- `GET /categories` - Get all product categories
- `GET /categories/:id/products` - Get products by category ID

### Payment
- `GET /payment/config` - Get payment configuration
- `GET /payment/owner-account` - Get owner ICP account information

## Example Requests

```bash
# Check health
curl http://localhost:3001/health

# Get all products
curl http://localhost:3001/products

# Get categories
curl http://localhost:3001/categories

# Get system info
curl http://localhost:3001/info

# Get payment config
curl http://localhost:3001/payment/config
```

## Response Format

All responses follow this format:
```json
{
  "success": true,
  "data": "..."
}
```

In case of errors:
```json
{
  "error": "Error message",
  "details": "..."
}
```

## Requirements

- Node.js 16+
- dfx CLI installed and configured
- Access to the Internet Computer network
