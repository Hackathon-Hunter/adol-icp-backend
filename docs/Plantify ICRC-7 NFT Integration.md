# Plantify ICRC-7 NFT Integration with Supply & Pricing

This enhancement adds ICRC-7 compliant NFT functionality to the Plantify platform with **default supply management** and **automatic ICP price calculation** based on investment needs.

## Overview

The NFT integration consists of three main components:

1. **ICRC7Types.mo** - Type definitions for ICRC-7 standard compliance with supply & pricing
2. **ICRC7Storage.mo** - Storage management for NFT data including collections
3. **ICRC7Service.mo** - Business logic for NFT operations, pricing, and purchasing

## 🚀 Key Features

### 🎨 NFT Supply & Pricing

- **Default Supply**: Each investment project gets 100 NFTs by default (customizable)
- **Automatic Pricing**: NFT prices calculated based on funding requirements in ICP
- **Collection Management**: Each investment creates an NFT collection with supply tracking
- **Purchase System**: Investors can buy NFTs from available supply

### 💰 Price Calculation

- **USD to ICP Conversion**: Uses configurable exchange rate (default: $10/ICP)
- **Per-NFT Pricing**: `Total Funding Required ÷ NFT Supply = Price per NFT`
- **Minimum Price**: 0.01 ICP minimum per NFT
- **E8s Format**: Prices stored in e8s (1 ICP = 100,000,000 e8s)

### 📋 Enhanced NFT Metadata

Each Farm NFT now contains:

- Investment project details
- **Total supply** and **available supply**
- **NFT price in ICP e8s**
- **Sold count** and **remaining available**
- Crop type, location, expected yield
- Project status and timeline

## 💡 How It Works

### 1. Investment Approval & NFT Creation

```
Investment Approved → NFT Collection Created → Default 100 NFTs → Price Calculated
```

**Example Calculation:**

- Investment needs: $5,000 USD
- ICP price: $10 USD
- Required ICP: 500 ICP
- NFT supply: 100
- **Price per NFT: 5 ICP**

### 2. NFT Collection Structure

```motoko
{
  investmentId = 1;
  totalSupply = 100;        // Default or custom
  nftPrice = 500_000_000;   // 5 ICP in e8s
  availableSupply = 100;    // Decreases with sales
  soldSupply = 0;           // Increases with sales
  tokenIds = [];            // IDs of minted tokens
}
```

## 🔧 Main Functions

### For Admins

#### Mint NFT Collection with Custom Supply

```motoko
public shared (msg) func mintFarmNFT(
  investmentId : InvestmentTypes.InvestmentId,
  customSupply : ?Nat // Optional: defaults to 100
) : async ICRC7Types.MintResult
```

#### Approve Investment and Auto-mint Collection

```motoko
public shared (msg) func approveInvestmentAndMintNFT(
  investmentId : InvestmentTypes.InvestmentId,
  notes : ?Text,
  customSupply : ?Nat,
) : async Result.Result<ICRC7Types.TokenId, Text>
```

#### Calculate NFT Price

```motoko
public query func calculateNFTPrice(
  fundingRequiredUSD : Nat,
  totalSupply : Nat
) : async Nat
```

### For Investors

#### Purchase NFTs

```motoko
public shared (msg) func purchaseNFT(
  request : ICRC7Types.PurchaseNFTRequest
) : async ICRC7Types.PurchaseNFTResult
```

Purchase Request Structure:

```motoko
{
  investmentId : Nat;
  quantity : Nat;           // How many NFTs to buy
  paymentAmount : Nat;      // Payment in ICP e8s
}
```

#### Get Collection Info

```motoko
public query func getNFTCollection(
  investmentId : Nat
) : async ?ICRC7Types.NFTCollection
```

#### Get Pricing Information

```motoko
public query func getPricingInfo(
  investmentId : Nat
) : async ?{
  nftPrice : Nat;          // Price in e8s
  totalSupply : Nat;       // Total NFTs
  availableSupply : Nat;   // Available to buy
  soldSupply : Nat;        // Already sold
  fundingRequired : Nat;   // Total funding needed
  priceInICP : Float;      // Price in ICP (human readable)
}
```

## 💻 Usage Examples

### Admin creating NFT collection:

```bash
# Default 100 NFTs
dfx canister call plantify-backend approveInvestmentAndMintNFT '(1, opt "Approved for farming", null)'

# Custom 50 NFTs
dfx canister call plantify-backend approveInvestmentAndMintNFT '(1, opt "Approved for farming", opt 50)'
```

### Calculate pricing:

```bash
# $5000 funding, 100 NFTs = 5 ICP per NFT
dfx canister call plantify-backend calculateNFTPrice '(5000, 100)'
# Returns: 500_000_000 (5 ICP in e8s)
```

### Investor purchasing NFTs:

```bash
dfx canister call plantify-backend purchaseNFT '(
  record {
    investmentId = 1;
    quantity = 5;
    paymentAmount = 2_500_000_000; // 25 ICP in e8s for 5 NFTs
  }
)'
```

### Check collection status:

```bash
dfx canister call plantify-backend getNFTCollection '(1)'
# Returns collection info with current supply status
```

### Get pricing info:

```bash
dfx canister call plantify-backend getPricingInfo '(1)'
# Returns detailed pricing and supply information
```

## 📊 Pricing Examples

| Funding Required | NFT Supply | ICP Price | Price per NFT |
| ---------------- | ---------- | --------- | ------------- |
| $1,000 USD       | 100 NFTs   | $10/ICP   | 1 ICP         |
| $5,000 USD       | 100 NFTs   | $10/ICP   | 5 ICP         |
| $10,000 USD      | 200 NFTs   | $10/ICP   | 5 ICP         |
| $500 USD         | 100 NFTs   | $10/ICP   | 0.5 ICP       |
| $50 USD          | 100 NFTs   | $10/ICP   | 0.01 ICP\*    |

\*Minimum price of 0.01 ICP enforced

## 🔄 Enhanced Workflow

### 1. Investment Creation

```
Farmer creates project → Specifies funding needs → Project pending
```

### 2. Admin Approval & Collection Creation

```
Admin approves → NFT collection created → Supply: 100 → Price calculated → Ready for investors
```

### 3. Investor Participation

```
Investor views collection → Checks price/supply → Purchases NFTs → Owns project shares
```

### 4. Supply Management

```
Available supply decreases → Sold count increases → Real-time tracking
```

## 🔧 Configuration

### Default Settings

- **Default NFT Supply**: 100 per investment
- **ICP Exchange Rate**: $10 USD per ICP (configurable)
- **Minimum NFT Price**: 0.01 ICP
- **Price Format**: e8s (1 ICP = 100,000,000 e8s)

### Customization Options

- Custom NFT supply per project
- Future: Dynamic ICP pricing via oracles
- Future: Variable platform fees
- Future: Tiered pricing models

## 🚀 Future Enhancements

- **Oracle Integration**: Real-time ICP/USD pricing
- **Secondary Market**: NFT trading between investors
- **Fractional Ownership**: More granular investment amounts
- **Profit Distribution**: Automatic payouts to NFT holders
- **Yield Tracking**: ROI calculations based on harvest results
- **Governance**: NFT holder voting on farm decisions

## 🔒 Security & Validation

- **Payment Validation**: Ensures sufficient payment for NFT purchases
- **Supply Limits**: Prevents overselling of NFTs
- **Admin Controls**: Only admins can create collections
- **Transfer Validation**: Proper ownership verification
- **Price Minimums**: Prevents zero or negative pricing

## 🔒 Security & Validation

- **Payment Validation**: Ensures sufficient payment for NFT purchases
- **Supply Limits**: Prevents overselling of NFTs
- **Admin Controls**: Only admins can create collections
- **Transfer Validation**: Proper ownership verification
- **Price Minimums**: Prevents zero or negative pricing

## 📁 File Structure

```
src/backend/
├── types/
│   ├── ICRC7Types.mo          # NFT types with supply & pricing
│   ├── FarmerTypes.mo         # Farmer registration types
│   └── InvestmentTypes.mo     # Investment project types
├── storage/
│   ├── ICRC7Storage.mo        # NFT storage with collections
│   ├── FarmerStorage.mo       # Farmer data storage
│   └── InvestmentStorage.mo   # Investment data storage
├── services/
│   ├── ICRC7Service.mo        # NFT business logic
│   ├── FarmerService.mo       # Farmer operations
│   └── InvestmentService.mo   # Investment operations
└── main.mo                    # Enhanced main backend
```

## 🔧 Deployment

1. Replace your existing backend files with the enhanced versions
2. Update your `dfx.json` if needed
3. Deploy the enhanced backend:
   ```bash
   dfx deploy plantify-backend
   ```

## 🧪 Testing Scenarios

### Scenario 1: Create Investment with Custom Supply

```bash
# Create 50 NFTs at 10 ICP each for $5000 project
dfx canister call plantify-backend approveInvestmentAndMintNFT '(1, opt "Approved", opt 50)'
```

### Scenario 2: Purchase Multiple NFTs

```bash
# Buy 5 NFTs (50 ICP total)
dfx canister call plantify-backend purchaseNFT '(
  record {
    investmentId = 1;
    quantity = 5;
    paymentAmount = 5_000_000_000; // 50 ICP in e8s
  }
)'
```

### Scenario 3: Check Collection Status

```bash
# View current supply and pricing
dfx canister call plantify-backend getPricingInfo '(1)'
```

## 🎯 Key Benefits

1. **Automated Pricing**: No manual price setting required
2. **Supply Management**: Built-in scarcity and tracking
3. **Investor-Friendly**: Clear pricing and availability
4. **Scalable**: Supports multiple investment projects
5. **Standard Compliant**: Full ICRC-7 compatibility
6. **Real-time Tracking**: Live supply and sales data

The enhanced NFT system transforms Plantify into a complete agricultural investment platform with automated pricing, supply management, and seamless investor onboarding! 🌱💰🚀NFTs '()'

````

### Getting NFT metadata:
```bash
dfx canister call plantify-backend getFarmNFTMetadata '(1)'
````

### Transferring NFT:

```bash
dfx canister call plantify-backend icrc7_transfer '(
  vec {
    record {
      from_subaccount = null;
      to = record { owner = principal "rdmx6-jaaaa-aaaah-qcaiq-cai"; subaccount = null };
      token_id = 1;
      memo = null;
      created_at_time = null;
    }
  }
)'
```

## Integration Notes

### Simple Design Principles

- **Minimal complexity**: Focus on core NFT functionality
- **Admin control**: NFTs can only be minted by admins for approved projects
- **Farmer ownership**: NFTs are automatically assigned to farmers
- **Standard compliance**: Implements essential ICRC-7 functions

### Future Enhancements

- Secondary marketplace integration
- Fractional ownership through multiple NFTs per project
- Profit distribution tied to NFT ownership
- Enhanced metadata with farm photos and progress updates
- Investor dashboard integration

### Security Considerations

- Admin-only minting prevents unauthorized NFT creation
- Transfer validation ensures proper ownership
- Metadata immutability for core project data
- Stable storage ensures NFT persistence across upgrades

## Deployment

1. Add the new files to your backend project
2. Update your `dfx.json` if needed
3. Deploy the enhanced backend:
   ```bash
   dfx deploy plantify-backend
   ```

The NFT functionality is now integrated and ready to use! 🌱
