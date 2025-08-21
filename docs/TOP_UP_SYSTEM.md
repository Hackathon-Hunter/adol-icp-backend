# 🏦 **Sistem Top-Up Adol E-commerce Platform**

## **Overview**
Sistem top-up memungkinkan user untuk menambah saldo ICP mereka di platform Adol untuk melakukan pembelian.

## **🔄 Cara Kerja Sistem Top-Up**

### **1. Sistem Simulasi (Development)**
Saat ini platform menggunakan sistem simulasi untuk development:
```motoko
// Langkah-langkah:
1. User memanggil topUpBalance(amount)
2. Sistem membuat payment record
3. Sistem langsung approve payment (simulasi)
4. Balance user ditambah
5. Payment status = Completed
```

### **2. Sistem Real ICP Integration**

#### **Metode A: Transfer ke Platform Account**
```motoko
// Flow:
1. User transfer ICP ke platform account
2. User memanggil topUpBalance(amount)
3. Sistem verify transfer di ICP Ledger
4. Jika valid, balance user ditambah
5. Payment status = Completed
```

#### **Metode B: Transfer dengan Block Index**
```motoko
// Flow:
1. User transfer ICP ke platform account
2. User dapat block index dari transfer
3. User memanggil topUpBalanceWithBlock(amount, blockIndex)
4. Sistem verify transaction di block tersebut
5. Balance user ditambah sesuai verification
```

## **🛠️ Implementasi**

### **Setup ICP Ledger Integration**

1. **Update dfx.json** untuk menambah ICP Ledger dependency:
```json
{
  "canisters": {
    "adol-backend": {
      "main": "src/backend/main.mo",
      "type": "motoko"
    },
    "ledger": {
      "type": "custom",
      "candid": "https://raw.githubusercontent.com/dfinity/ic/master/rs/ledger_suite/icp/ledger.did",
      "wasm": "https://download.dfinity.systems/ic/xxxxxx/canisters/ledger-canister.wasm.gz",
      "remote": {
        "candid": "rrkah-fqaaa-aaaaa-aaaaq-cai",
        "id": {
          "ic": "rrkah-fqaaa-aaaaa-aaaaq-cai"
        }
      }
    }
  }
}
```

### **Platform Account Setup**
```motoko
// Generate platform account
private let PLATFORM_ACCOUNT = Principal.fromText("your-platform-principal");

// Get user-specific subaccount
public func getUserDepositAccount(userId: Principal) : Account {
    {
        owner = PLATFORM_ACCOUNT;
        subaccount = ?Principal.toLedgerAccount(userId);
    }
}
```

## **📱 User Experience Flow**

### **Frontend Integration Example:**
```javascript
// 1. Get platform deposit account
const depositAccount = await actor.getUserDepositAccount();

// 2. Show QR code atau copy address untuk transfer
const qrData = `icp:${depositAccount.owner}?amount=${amount}`;

// 3. User transfer ICP menggunakan wallet (Plug, Stoic, etc)

// 4. Setelah transfer, call top-up function
const result = await actor.topUpBalance({
    amount: amount_in_e8s
});

// 5. Monitor payment status
const payment = await actor.getPayment(result.ok.id);
```

## **💡 Metode Top-Up yang Direkomendasikan**

### **Untuk Development:**
- Gunakan sistem simulasi yang sudah ada
- Testing mudah dan cepat

### **Untuk Production:**
1. **QR Code Method**: Generate QR code dengan format ICP URI
2. **Wallet Integration**: Direct integration dengan ICP wallets
3. **Manual Transfer**: User transfer manual + verify via block index

## **🔐 Security Considerations**

1. **Amount Validation**: Minimum amount untuk mencegah spam
2. **Transfer Verification**: Always verify di ICP Ledger
3. **Timeout Handling**: Set timeout untuk pending payments
4. **Double Spending Prevention**: Check payment uniqueness

## **📊 Monitoring & Analytics**

```motoko
// Track payment metrics
public func getPaymentStats() : PaymentStats {
    {
        totalTopUps = getAllPayments().size();
        totalAmount = calculateTotalAmount();
        successRate = calculateSuccessRate();
        avgAmount = calculateAverageAmount();
    }
}
```

## **🧪 Testing Commands**

```bash
# Test simulasi top-up
dfx canister call adol-backend topUpBalance '(record { amount = 1000000 })'

# Check balance
dfx canister call adol-backend getBalance

# Get payment history
dfx canister call adol-backend getMyPayments

# Platform info
dfx canister call adol-backend getInfo
```

## **💰 Conversion Rates**

- **1 ICP = 100,000,000 e8s**
- **0.01 ICP = 1,000,000 e8s**
- **0.001 ICP = 100,000 e8s**
- **Minimum top-up = 0.0001 ICP = 10,000 e8s**

## **🔄 Error Handling**

- `InvalidAmount`: Amount terlalu kecil atau 0
- `Unauthorized`: User tidak ditemukan
- `PaymentFailed`: Transfer verification gagal
- `InsufficientFunds`: Balance tidak cukup di ICP wallet
- `TransferNotFound`: Transfer tidak ditemukan di ledger

## **🚀 Next Steps untuk Production**

1. Setup ICP Ledger canister dependency
2. Configure platform ICP account
3. Implement wallet integration di frontend
4. Add payment monitoring dashboard
5. Setup automatic reconciliation
6. Add payment webhooks/notifications
