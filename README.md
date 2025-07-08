# 🌱 Plantify ICP Backend

**Plantify** is a decentralized agricultural investment platform built on the Internet Computer Protocol (ICP) using Motoko. It connects farmers with investors through NFT-based profit sharing, enabling transparent and secure agricultural investments.

## 📋 Table of Contents

- [Features](#features)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Deployment](#deployment)
- [API Reference](#api-reference)
- [Usage Examples](#usage-examples)
- [Testing](#testing)
- [Contributing](#contributing)

## 🎯 Features

### 👨‍🌾 **Farmer Registration & Verification**

- Complete farmer registration with KYC
- Document upload (Government ID, Selfie photos)
- Multi-step verification process
- Profile management

### 🚀 **Investment Project Setup**

- 5-step investment project creation
- Comprehensive farm information collection
- Budget allocation with validation
- Document management system
- Real-time verification tracking

### 📊 **Analytics & Management**

- Platform statistics and insights
- Search and filtering capabilities
- Project status management
- Progress tracking

## 📁 Project Structure

```
src/plantify_backend/
├── main.mo                          # Main actor (API entry point)
├── types/
│   ├── FarmerTypes.mo              # Farmer registration types
│   └── InvestmentTypes.mo          # Investment setup types
├── utils/
│   ├── Validation.mo               # Farmer validation functions
│   └── InvestmentValidation.mo     # Investment validation functions
├── storage/
│   ├── FarmerStorage.mo            # Farmer data storage
│   └── InvestmentStorage.mo        # Investment data storage
└── services/
    ├── FarmerService.mo            # Farmer business logic
    └── InvestmentService.mo        # Investment business logic
```

## 🛠️ Installation

### Prerequisites

1. **Install DFINITY SDK (dfx)**

   ```bash
   sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"
   ```

2. **Verify installation**

   ```bash
   dfx --version
   ```

3. **Install Node.js** (for frontend integration)
   ```bash
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   nvm install node
   ```

### Setup Project

1. **Clone the repository**

   ```bash
   git clone <your-repo-url>
   cd plantify-backend
   ```

2. **Create the project structure**

   ```bash
   mkdir -p src/plantify_backend/{types,utils,storage,services}
   ```

3. **Copy all the Motoko files** to their respective directories as shown in the project structure above.

## 🚀 Deployment

### Local Deployment

1. **Start local replica**

   ```bash
   dfx start --clean --background
   ```

2. **Deploy the canister**

   ```bash
   dfx deploy plantify_backend
   ```

3. **Check health**
   ```bash
   dfx canister call plantify_backend healthCheck
   ```

### Mainnet Deployment

1. **Deploy to mainnet**
   ```bash
   dfx deploy --network ic plantify_backend
   ```

## 📖 API Reference

### 🏥 Health Check

- `healthCheck()` - Returns health status

### 👨‍🌾 Farmer Registration

- `registerFarmer(request)` - Register new farmer
- `uploadDocument(request)` - Upload verification documents
- `getFarmerProfile(farmerId)` - Get farmer profile
- `getMyFarmerProfile()` - Get own farmer profile
- `updateFarmerProfile(...)` - Update farmer information
- `isFarmerVerified(farmerId)` - Check verification status

### 🚀 Investment Projects

- `createInvestmentProject(request)` - Create new investment project
- `getInvestmentProject(id)` - Get project by ID
- `getMyInvestmentProjects()` - Get own projects
- `addInvestmentDocument(id, document)` - Add document to project
- `getVerificationTracker(id)` - Get verification progress
- `searchInvestmentProjects(...)` - Search projects by criteria

### 🔐 Admin Functions

- `updateFarmerVerificationStatus(...)` - Update farmer verification
- `updateInvestmentProjectStatus(...)` - Update project status
- `getAllFarmers()` - Get all farmers
- `getAllInvestmentProjects()` - Get all projects

## 💻 Usage Examples

### 🌱 Complete Farmer Journey

#### 1. **Farmer Registration**

```bash
# Register new farmer
dfx canister call plantify_backend registerFarmer '(record {
  fullName = "Ahmad Rizki";
  email = "ahmad@example.com";
  phoneNumber = "+628123456789";
  governmentId = "ID123456789"
})'

# Expected response: (variant { Success = principal "rdmx6-jaaaa-aaaah-qcaiq-cai" })
```

#### 2. **Upload Verification Documents**

```bash
# Upload government ID
dfx canister call plantify_backend uploadDocument '(record {
  documentType = variant { GovernmentID };
  fileName = "government_id.jpg";
  fileHash = "abc123hash456def"
})'

# Upload selfie photo
dfx canister call plantify_backend uploadDocument '(record {
  documentType = variant { SelfiePhoto };
  fileName = "selfie.jpg";
  fileHash = "xyz789hash123abc"
})'

# Expected response: (variant { ok })
```

#### 3. **Check Farmer Profile**

```bash
# Get own profile
dfx canister call plantify_backend getMyFarmerProfile

# Check verification status
dfx canister call plantify_backend isFarmerVerified '(principal "farmer-principal-id")'
```

#### 4. **Admin: Approve Farmer**

```bash
# Admin approves farmer
dfx canister call plantify_backend updateFarmerVerificationStatus '(
  principal "farmer-principal-id",
  variant { Approved }
)'
```

### 🚀 Investment Project Creation

#### 1. **Create Complete Investment Project**

```bash
dfx canister call plantify_backend createInvestmentProject '(record {
  farmInfo = record {
    cropType = variant { Rice };
    country = "Indonesia";
    stateProvince = "East Java";
    cityDistrict = "Batu, Malang";
    gpsCoordinates = opt "-7.8753, 112.5286";
    farmSize = "2.5 hectares";
    landOwnership = variant { Owned };
    waterSource = "Natural spring irrigation system with modern drip technology";
    accessRoads = variant { Good };
    fundingRequired = 350000
  };
  experience = record {
    farmingExperience = variant { Experienced };
    harvestTimeline = variant { Medium };
    expectedYield = "12 tons of premium organic rice";
    cultivationMethod = variant { Organic };
    marketDistribution = [
      variant { LocalMarkets };
      variant { DirectToConsumer };
      variant { ExportBuyers }
    ];
    investmentDescription = "Premium organic rice farming project in fertile highlands of East Java. Focusing on sustainable practices, traditional Indonesian rice varieties, and direct-to-consumer sales for maximum profit margins. Expected to serve both local premium markets and international organic food exporters."
  };
  budget = record {
    budgetAllocation = record {
      seeds = 15;
      fertilizers = 20;
      labor = 30;
      equipment = 15;
      operational = 10;
      infrastructure = 5;
      insurance = 5
    };
    hasBusinessBankAccount = true;
    previousFarmingLoans = opt true;
    emergencyContactName = "Siti Ahmad";
    emergencyContactPhone = "+628123456790";
    expectedMinROI = 15;
    expectedMaxROI = 25
  };
  documents = [
    record {
      documentType = variant { LandCertificate };
      fileName = "land_certificate.pdf";
      fileHash = "land123hash456def";
      uploadedAt = 1704067200000000000;
      isRequired = true
    };
    record {
      documentType = variant { FarmPhoto };
      fileName = "farm_photo1.jpg";
      fileHash = "photo123hash789abc";
      uploadedAt = 1704067200000000000;
      isRequired = true
    };
    record {
      documentType = variant { GovernmentPermit };
      fileName = "farming_permit.pdf";
      fileHash = "permit456hash123xyz";
      uploadedAt = 1704067200000000000;
      isRequired = false
    }
  ];
  agreements = [true; true; true; true; true]
})'

# Expected response: (variant { Success = 1 : nat })
```

#### 2. **Track Verification Progress**

```bash
# Get verification tracker
dfx canister call plantify_backend getVerificationTracker '(1 : nat)'

# Expected response shows step-by-step progress:
# (
#   opt record {
#     investmentId = 1 : nat;
#     overallProgress = 0 : nat;
#     currentStep = "Document Review";
#     steps = vec {
#       record {
#         stepName = "Document Review";
#         description = "Reviewing submitted documents and application forms";
#         status = variant { Pending };
#         estimatedTime = "6-12 hours";
#         completedAt = null;
#         notes = null
#       };
#       // ... other steps
#     };
#     lastUpdated = 1704067200000000000 : int
#   }
# )
```

#### 3. **Admin: Update Project Status**

```bash
# Admin moves project to verification
dfx canister call plantify_backend updateInvestmentProjectStatus '(
  1 : nat,
  variant { InVerification },
  opt "Documents approved, moving to agricultural assessment phase"
)'

# Admin approves project
dfx canister call plantify_backend updateInvestmentProjectStatus '(
  1 : nat,
  variant { Approved },
  opt "Project approved for marketplace listing. All verification criteria met."
)'
```

### 📊 Search & Analytics

#### 1. **Search Investment Projects**

```bash
# Search by crop type
dfx canister call plantify_backend searchInvestmentProjects '(
  opt variant { Rice },
  null,
  null,
  null,
  null
)'

# Search by location and funding range
dfx canister call plantify_backend searchInvestmentProjects '(
  null,
  opt "Indonesia",
  opt 100000 : nat,
  opt 500000 : nat,
  opt variant { Approved }
)'

# Search approved coffee projects in specific funding range
dfx canister call plantify_backend searchInvestmentProjects '(
  opt variant { Coffee },
  opt "Indonesia",
  opt 200000 : nat,
  opt 800000 : nat,
  opt variant { Approved }
)'
```

#### 2. **Get Platform Statistics**

```bash
# Get farmer registration stats
dfx canister call plantify_backend getFarmerRegistrationStats

# Get investment project stats
dfx canister call plantify_backend getInvestmentStats

# Get complete platform overview
dfx canister call plantify_backend getPlatformOverview

# Expected response:
# (
#   record {
#     farmers = record {
#       totalFarmers = 25 : nat;
#       pendingVerification = 3 : nat;
#       approvedFarmers = 20 : nat;
#       rejectedFarmers = 2 : nat
#     };
#     investments = record {
#       totalProjects = 12 : nat;
#       pendingVerification = 2 : nat;
#       approvedProjects = 8 : nat;
#       rejectedProjects = 1 : nat;
#       activeProjects = 6 : nat;
#       completedProjects = 1 : nat
#     }
#   }
# )
```

#### 3. **Project Management**

```bash
# Get farmer's own projects
dfx canister call plantify_backend getMyInvestmentProjects

# Get projects by status
dfx canister call plantify_backend getInvestmentProjectsByStatus '(variant { Approved })'

# Get farmers by verification status
dfx canister call plantify_backend getFarmersByStatus '(variant { Pending })'

# Add document to existing project
dfx canister call plantify_backend addInvestmentDocument '(
  1 : nat,
  record {
    documentType = variant { SoilTestResult };
    fileName = "soil_analysis_report.pdf";
    fileHash = "soil456hash789def";
    uploadedAt = 1704067200000000000;
    isRequired = false
  }
)'
```

## 🧪 Testing

### Basic Functionality Tests

```bash
# 1. Health check
dfx canister call plantify_backend healthCheck

# 2. Test farmer registration flow
dfx canister call plantify_backend registerFarmer '(record {
  fullName = "Test Farmer";
  email = "test@plantify.com";
  phoneNumber = "+1234567890";
  governmentId = "TEST123"
})'

# 3. Test document upload
dfx canister call plantify_backend uploadDocument '(record {
  documentType = variant { GovernmentID };
  fileName = "test_id.jpg";
  fileHash = "testhash123"
})'

# 4. Check profile
dfx canister call plantify_backend getMyFarmerProfile

# 5. Test validation errors
dfx canister call plantify_backend registerFarmer '(record {
  fullName = "A";
  email = "invalid-email";
  phoneNumber = "123";
  governmentId = "X"
})'
# Should return validation errors
```

### Error Handling Examples

```bash
# Test duplicate registration
dfx canister call plantify_backend registerFarmer '(record {
  fullName = "Test Farmer";
  email = "test@plantify.com";
  phoneNumber = "+1234567890";
  governmentId = "TEST123"
})'
# Expected: (variant { AlreadyRegistered = principal "..." })

# Test investment creation without farmer verification
dfx canister call plantify_backend createInvestmentProject '(record {
  farmInfo = record { /* ... */ };
  experience = record { /* ... */ };
  budget = record { /* ... */ };
  documents = [];
  agreements = [true; true; true; true; true]
})'
# Expected: (variant { FarmerNotVerified })
```

## 🔧 Integration with Frontend

### TypeScript Example

```typescript
import { Actor, HttpAgent } from "@dfinity/agent";
import { idlFactory } from "./declarations/plantify_backend";

// Initialize actor
const agent = new HttpAgent();
const plantifyBackend = Actor.createActor(idlFactory, {
  agent,
  canisterId: process.env.CANISTER_ID_PLANTIFY_BACKEND,
});

// Register farmer
async function registerFarmer(formData) {
  try {
    const result = await plantifyBackend.registerFarmer({
      fullName: formData.fullName,
      email: formData.email,
      phoneNumber: formData.phoneNumber,
      governmentId: formData.governmentId,
    });

    if ("Success" in result) {
      console.log("Farmer registered:", result.Success);
      return result.Success;
    } else {
      throw new Error(result.InvalidData || "Registration failed");
    }
  } catch (error) {
    console.error("Registration error:", error);
    throw error;
  }
}

// Create investment project
async function createProject(projectData) {
  try {
    const result = await plantifyBackend.createInvestmentProject(projectData);

    if ("Success" in result) {
      console.log("Project created:", result.Success);
      return result.Success;
    } else {
      throw new Error(result.InvalidData || "Project creation failed");
    }
  } catch (error) {
    console.error("Project creation error:", error);
    throw error;
  }
}
```

## 📝 Data Types Reference

### Farmer Registration Types

```motoko
type RegisterFarmerRequest = {
  fullName: Text;
  email: Text;
  phoneNumber: Text;
  governmentId: Text;
};

type VerificationStatus = {
  #Pending; #InReview; #Approved; #Rejected;
};
```

### Investment Project Types

```motoko
type CropType = {
  #Rice; #Corn; #Vegetables; #Fruits; #Coffee; #Other: Text;
};

type InvestmentStatus = {
  #Draft; #PendingVerification; #InVerification;
  #Approved; #Rejected; #Active; #Completed; #Cancelled;
};
```

## 🚨 Common Issues & Solutions

### 1. **Hash Function Error**

```bash
# Error: field hash does not exist in module
# Solution: Make sure to import Hash module in storage files
import Hash "mo:base/Hash";
```

### 2. **Array Function Error**

```bash
# Error: Array.mapEntries doesn't exist
# Solution: Use Array.tabulate instead
Array.tabulate<Type>(array.size(), func(i) { array[i] })
```

### 3. **Principal Conversion**

```bash
# Convert text to principal for testing
dfx canister call plantify_backend getFarmerProfile '(principal "rdmx6-jaaaa-aaaah-qcaiq-cai")'
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Roadmap

- [ ] NFT marketplace integration
- [ ] Profit distribution system
- [ ] IoT sensor integration
- [ ] Mobile app development
- [ ] Multi-language support

## 📞 Support

For support, email support@plantify.com or join our Discord community.

---

**Built with ❤️ on Internet Computer Protocol**
