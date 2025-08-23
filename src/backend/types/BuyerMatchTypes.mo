import Principal "mo:base/Principal";
import UserTypes "UserTypes";
import ProductTypes "ProductTypes";

module {
  public type BuyerId = Principal;
  public type SellerId = Principal;
  public type MatchId = Nat;

  // Buyer Profile for matching
  public type BuyerProfile = {
    id : BuyerId;
    name : Text;
    email : Text;
    phone : ?Text;
    location : ?UserTypes.Address;
    budget : Nat; // Simple total budget
    purchaseHistory : [PurchaseRecord];
    createdAt : Int;
    updatedAt : Int;
    isActive : Bool;
  };

  // Simplified buyer preferences
  public type BuyerPreferences = {
    maxBudget : Nat;
    preferredLocation : ?UserTypes.Address;
  };

  public type PriceRange = {
    min : Nat;
    max : Nat;
  };

  public type DeliveryPreference = {
    #FastDelivery;
    #StandardDelivery;
    #EconomyDelivery;
    #LocalPickup;
  };

  // Simplified seller profile
  public type SellerProfile = {
    id : SellerId;
    businessName : Text;
    description : Text;
    location : ?UserTypes.Address;
    contactEmail : Text;
    contactPhone : ?Text;
    rating : Float;
    totalSales : Nat;
    createdAt : Int;
    isVerified : Bool;
  };

  public type PurchaseRecord = {
    productId : ProductTypes.ProductId;
    sellerId : SellerId;
    amount : Nat;
    purchaseDate : Int;
    rating : ?Nat; // 1-5 rating
  };

  // Potential buyer-seller-product match
  public type PotentialMatch = {
    id : MatchId;
    buyerId : BuyerId;
    sellerId : SellerId;
    productId : ProductTypes.ProductId;
    matchScore : Float; // 0.0 to 1.0
    matchReasons : [MatchReason];
    estimatedInterest : InterestLevel;
    recommendedAction : RecommendedAction;
    createdAt : Int;
    isViewed : Bool;
    isInterested : ?Bool; // null = not responded, true = interested, false = not interested
  };

  public type MatchReason = {
    #CategoryMatch;
    #PriceMatch;
    #LocationMatch;
    #PreviousPurchase;
    #SimilarBuyers;
    #HighRatedSeller;
    #PopularProduct;
    #KeywordMatch;
    #BudgetMatch;
  };

  public type InterestLevel = {
    #VeryHigh; // 0.8-1.0
    #High; // 0.6-0.8
    #Medium; // 0.4-0.6
    #Low; // 0.2-0.4
    #VeryLow; // 0.0-0.2
  };

  public type RecommendedAction = {
    #ImmediateContact;
    #SendSample;
    #SpecialOffer;
    #WatchAndWait;
    #PriceAlert;
  };

  // Input types
  public type BuyerProfileInput = {
    name : Text;
    email : Text;
    phone : ?Text;
    location : ?UserTypes.Address;
    budget : Nat;
  };

  public type BuyerProfileUpdate = {
    name : ?Text;
    email : ?Text;
    phone : ?Text;
    location : ?UserTypes.Address;
    budget : ?Nat;
  };

  public type SellerProfileInput = {
    businessName : Text;
    description : Text;
    location : ?UserTypes.Address;
    contactEmail : Text;
    contactPhone : ?Text;
  };

  public type SellerProfileUpdate = {
    businessName : ?Text;
    description : ?Text;
    location : ?UserTypes.Address;
    contactEmail : ?Text;
    contactPhone : ?Text;
  };

  public type MatchingCriteria = {
    maxMatches : Nat;
    minScore : Float;
    maxPrice : ?Nat;
    categoryId : ?ProductTypes.CategoryId;
  };

  // Errors
  public type BuyerMatchError = {
    #BuyerNotFound;
    #SellerNotFound;
    #ProductNotFound;
    #InvalidInput : Text;
    #MatchNotFound;
    #Unauthorized;
    #InsufficientData;
  };
};
