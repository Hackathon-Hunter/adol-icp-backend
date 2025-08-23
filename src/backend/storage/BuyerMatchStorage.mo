import Map "mo:base/HashMap";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Nat32 "mo:base/Nat32";
import BuyerMatchTypes "../types/BuyerMatchTypes";
import ProductTypes "../types/ProductTypes";

module {
    public type BuyerProfile = BuyerMatchTypes.BuyerProfile;
    public type SellerProfile = BuyerMatchTypes.SellerProfile;
    public type PotentialMatch = BuyerMatchTypes.PotentialMatch;
    public type BuyerMatchError = BuyerMatchTypes.BuyerMatchError;
    
    public class BuyerMatchStorage() {
        private var buyerProfiles = Map.HashMap<Principal, BuyerProfile>(10, Principal.equal, Principal.hash);
        private var sellerProfiles = Map.HashMap<Principal, SellerProfile>(10, Principal.equal, Principal.hash);
        private var potentialMatches = Map.HashMap<BuyerMatchTypes.MatchId, PotentialMatch>(50, func(a: Nat, b: Nat) : Bool { a == b }, func(a: Nat) : Nat32 { Nat32.fromNat(a % (2**30)) });
        private var nextMatchId: Nat = 1;
        
        // Buyer Profile Operations
        public func createBuyerProfile(
            buyerId: Principal,
            input: BuyerMatchTypes.BuyerProfileInput
        ) : BuyerProfile {
            let profile: BuyerProfile = {
                id = buyerId;
                name = input.name;
                email = input.email;
                phone = input.phone;
                location = input.location;
                budget = input.budget;
                purchaseHistory = [];
                createdAt = Time.now();
                updatedAt = Time.now();
                isActive = true;
            };
            buyerProfiles.put(buyerId, profile);
            profile
        };
        
        public func getBuyerProfile(buyerId: Principal) : ?BuyerProfile {
            buyerProfiles.get(buyerId)
        };

        public func getBuyerProfileById(buyerId: BuyerMatchTypes.BuyerId) : ?BuyerProfile {
            buyerProfiles.get(buyerId)
        };
        
        public func updateBuyerProfile(
            buyerId: Principal,
            update: BuyerMatchTypes.BuyerProfileUpdate
        ) : Result.Result<BuyerProfile, BuyerMatchError> {
            switch (buyerProfiles.get(buyerId)) {
                case null { #err(#BuyerNotFound) };
                case (?profile) {
                    let updatedProfile: BuyerProfile = {
                        id = profile.id;
                        name = switch (update.name) { case null profile.name; case (?n) n };
                        email = switch (update.email) { case null profile.email; case (?e) e };
                        phone = switch (update.phone) { case null profile.phone; case (?p) ?p };
                        location = update.location;
                        budget = switch (update.budget) { case null profile.budget; case (?b) b };
                        purchaseHistory = profile.purchaseHistory;
                        createdAt = profile.createdAt;
                        updatedAt = Time.now();
                        isActive = profile.isActive;
                    };
                    buyerProfiles.put(buyerId, updatedProfile);
                    #ok(updatedProfile)
                };
            }
        };
        
        public func addPurchaseRecord(
            buyerId: Principal,
            record: BuyerMatchTypes.PurchaseRecord
        ) : Result.Result<BuyerProfile, BuyerMatchError> {
            switch (buyerProfiles.get(buyerId)) {
                case null { #err(#BuyerNotFound) };
                case (?profile) {
                    let updatedHistory = Array.append(profile.purchaseHistory, [record]);
                    let updatedProfile: BuyerProfile = {
                        id = profile.id;
                        name = profile.name;
                        email = profile.email;
                        phone = profile.phone;
                        location = profile.location;
                        budget = profile.budget;
                        purchaseHistory = updatedHistory;
                        createdAt = profile.createdAt;
                        updatedAt = Time.now();
                        isActive = profile.isActive;
                    };
                    buyerProfiles.put(buyerId, updatedProfile);
                    #ok(updatedProfile)
                };
            }
        };
        
        // Seller Profile Operations
        public func createSellerProfile(
            sellerId: Principal,
            input: BuyerMatchTypes.SellerProfileInput
        ) : SellerProfile {
            let profile: SellerProfile = {
                id = sellerId;
                businessName = input.businessName;
                description = input.description;
                location = input.location;
                contactEmail = input.contactEmail;
                contactPhone = input.contactPhone;
                rating = 0.0;
                totalSales = 0;
                createdAt = Time.now();
                isVerified = false;
            };
            sellerProfiles.put(sellerId, profile);
            profile
        };
        
        public func getSellerProfile(sellerId: Principal) : ?SellerProfile {
            sellerProfiles.get(sellerId)
        };

        public func getSellerProfileById(sellerId: BuyerMatchTypes.SellerId) : ?SellerProfile {
            sellerProfiles.get(sellerId)
        };
        
        public func updateSellerProfile(
            sellerId: Principal,
            update: BuyerMatchTypes.SellerProfileUpdate
        ) : Result.Result<SellerProfile, BuyerMatchError> {
            switch (sellerProfiles.get(sellerId)) {
                case null { #err(#SellerNotFound) };
                case (?profile) {
                    let updatedProfile: SellerProfile = {
                        id = profile.id;
                        businessName = switch (update.businessName) { case null profile.businessName; case (?n) n };
                        description = switch (update.description) { case null profile.description; case (?d) d };
                        location = update.location;
                        contactEmail = switch (update.contactEmail) { case null profile.contactEmail; case (?e) e };
                        contactPhone = switch (update.contactPhone) { case null profile.contactPhone; case (?p) ?p };
                        rating = profile.rating;
                        totalSales = profile.totalSales;
                        createdAt = profile.createdAt;
                        isVerified = profile.isVerified;
                    };
                    sellerProfiles.put(sellerId, updatedProfile);
                    #ok(updatedProfile)
                };
            }
        };
        
        // Match Operations
        public func createPotentialMatch(
            buyerId: Principal,
            sellerId: Principal,
            productId: ProductTypes.ProductId,
            matchScore: Float,
            matchReasons: [BuyerMatchTypes.MatchReason],
            estimatedInterest: BuyerMatchTypes.InterestLevel,
            recommendedAction: BuyerMatchTypes.RecommendedAction
        ) : PotentialMatch {
            let matchId = nextMatchId;
            nextMatchId += 1;
            
            let match: PotentialMatch = {
                id = matchId;
                buyerId = buyerId;
                sellerId = sellerId;
                productId = productId;
                matchScore = matchScore;
                matchReasons = matchReasons;
                estimatedInterest = estimatedInterest;
                recommendedAction = recommendedAction;
                createdAt = Time.now();
                isViewed = false;
                isInterested = null;
            };
            
            potentialMatches.put(matchId, match);
            match
        };
        
        public func getPotentialMatch(matchId: BuyerMatchTypes.MatchId) : ?PotentialMatch {
            potentialMatches.get(matchId)
        };
        
        public func getBuyerMatches(buyerId: Principal) : [PotentialMatch] {
            let matches = Array.filter<PotentialMatch>(
                Iter.toArray(potentialMatches.vals()),
                func(match: PotentialMatch) : Bool {
                    match.buyerId == buyerId
                }
            );
            // Sort by match score (highest first)
            Array.sort<PotentialMatch>(matches, func(a: PotentialMatch, b: PotentialMatch) : {#less; #equal; #greater} {
                if (a.matchScore > b.matchScore) { #less }
                else if (a.matchScore < b.matchScore) { #greater }
                else { #equal }
            })
        };
        
        public func getSellerMatches(sellerId: Principal) : [PotentialMatch] {
            Array.filter<PotentialMatch>(
                Iter.toArray(potentialMatches.vals()),
                func(match: PotentialMatch) : Bool {
                    match.sellerId == sellerId
                }
            )
        };
        
        public func markMatchAsViewed(matchId: BuyerMatchTypes.MatchId) : Result.Result<PotentialMatch, BuyerMatchError> {
            switch (potentialMatches.get(matchId)) {
                case null { #err(#MatchNotFound) };
                case (?match) {
                    let updatedMatch: PotentialMatch = {
                        id = match.id;
                        buyerId = match.buyerId;
                        sellerId = match.sellerId;
                        productId = match.productId;
                        matchScore = match.matchScore;
                        matchReasons = match.matchReasons;
                        estimatedInterest = match.estimatedInterest;
                        recommendedAction = match.recommendedAction;
                        createdAt = match.createdAt;
                        isViewed = true;
                        isInterested = match.isInterested;
                    };
                    potentialMatches.put(matchId, updatedMatch);
                    #ok(updatedMatch)
                };
            }
        };
        
        public func setMatchInterest(
            matchId: BuyerMatchTypes.MatchId,
            isInterested: Bool
        ) : Result.Result<PotentialMatch, BuyerMatchError> {
            switch (potentialMatches.get(matchId)) {
                case null { #err(#MatchNotFound) };
                case (?match) {
                    let updatedMatch: PotentialMatch = {
                        id = match.id;
                        buyerId = match.buyerId;
                        sellerId = match.sellerId;
                        productId = match.productId;
                        matchScore = match.matchScore;
                        matchReasons = match.matchReasons;
                        estimatedInterest = match.estimatedInterest;
                        recommendedAction = match.recommendedAction;
                        createdAt = match.createdAt;
                        isViewed = match.isViewed;
                        isInterested = ?isInterested;
                    };
                    potentialMatches.put(matchId, updatedMatch);
                    #ok(updatedMatch)
                };
            }
        };
        
        // Get all profiles
        public func getAllBuyerProfiles() : [BuyerProfile] {
            Iter.toArray(buyerProfiles.vals())
        };
        
        public func getAllSellerProfiles() : [SellerProfile] {
            Iter.toArray(sellerProfiles.vals())
        };
        
        public func getAllMatches() : [PotentialMatch] {
            Iter.toArray(potentialMatches.vals())
        };
    };
    
    public func init() : BuyerMatchStorage {
        BuyerMatchStorage()
    };
}
