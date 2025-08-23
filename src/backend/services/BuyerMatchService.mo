import Result "mo:base/Result";
import Array "mo:base/Array";
import Float "mo:base/Float";
import BuyerMatchTypes "../types/BuyerMatchTypes";
import BuyerMatchStorage "../storage/BuyerMatchStorage";
import ProductTypes "../types/ProductTypes";

module {
    public type BuyerProfile = BuyerMatchTypes.BuyerProfile;
    public type SellerProfile = BuyerMatchTypes.SellerProfile;
    public type PotentialMatch = BuyerMatchTypes.PotentialMatch;
    public type BuyerMatchError = BuyerMatchTypes.BuyerMatchError;
    
    public class BuyerMatchService(storage: BuyerMatchStorage.BuyerMatchStorage) {
        
        // Create and manage buyer profiles
        public func createBuyerProfile(
            buyerId: Principal,
            input: BuyerMatchTypes.BuyerProfileInput
        ) : BuyerProfile {
            storage.createBuyerProfile(buyerId, input)
        };
        
        public func getBuyerProfile(buyerId: Principal) : Result.Result<BuyerProfile, BuyerMatchError> {
            switch (storage.getBuyerProfile(buyerId)) {
                case null { #err(#BuyerNotFound) };
                case (?profile) { #ok(profile) };
            }
        };

        public func getBuyerProfileById(buyerId: BuyerMatchTypes.BuyerId) : Result.Result<BuyerProfile, BuyerMatchError> {
            switch (storage.getBuyerProfileById(buyerId)) {
                case null { #err(#BuyerNotFound) };
                case (?profile) { #ok(profile) };
            }
        };
        
        public func updateBuyerProfile(
            buyerId: Principal,
            update: BuyerMatchTypes.BuyerProfileUpdate
        ) : Result.Result<BuyerProfile, BuyerMatchError> {
            storage.updateBuyerProfile(buyerId, update)
        };
        
        // Create and manage seller profiles
        public func createSellerProfile(
            sellerId: Principal,
            input: BuyerMatchTypes.SellerProfileInput
        ) : SellerProfile {
            storage.createSellerProfile(sellerId, input)
        };
        
        public func getSellerProfile(sellerId: Principal) : Result.Result<SellerProfile, BuyerMatchError> {
            switch (storage.getSellerProfile(sellerId)) {
                case null { #err(#SellerNotFound) };
                case (?profile) { #ok(profile) };
            }
        };

        public func getSellerProfileById(sellerId: BuyerMatchTypes.SellerId) : Result.Result<SellerProfile, BuyerMatchError> {
            switch (storage.getSellerProfileById(sellerId)) {
                case null { #err(#SellerNotFound) };
                case (?profile) { #ok(profile) };
            }
        };
        
        public func updateSellerProfile(
            sellerId: Principal,
            update: BuyerMatchTypes.SellerProfileUpdate
        ) : Result.Result<SellerProfile, BuyerMatchError> {
            storage.updateSellerProfile(sellerId, update)
        };
        
        // Find potential matches
        public func findPotentialMatches(
            buyerId: Principal,
            products: [ProductTypes.Product],
            criteria: BuyerMatchTypes.MatchingCriteria
        ) : Result.Result<[PotentialMatch], BuyerMatchError> {
            switch (storage.getBuyerProfile(buyerId)) {
                case null { #err(#BuyerNotFound) };
                case (?buyerProfile) {
                    let matches = Array.mapFilter<ProductTypes.Product, PotentialMatch>(
                        products,
                        func(product: ProductTypes.Product) : ?PotentialMatch {
                            calculateMatch(buyerProfile, product, criteria)
                        }
                    );
                    
                    // Sort by match score and limit results
                    let sortedMatches = Array.sort<PotentialMatch>(matches, func(a: PotentialMatch, b: PotentialMatch) : {#less; #equal; #greater} {
                        if (a.matchScore > b.matchScore) { #less }
                        else if (a.matchScore < b.matchScore) { #greater }
                        else { #equal }
                    });
                    
                    let limitedMatches = if (sortedMatches.size() > criteria.maxMatches) {
                        Array.tabulate<PotentialMatch>(criteria.maxMatches, func(i) = sortedMatches[i])
                    } else {
                        sortedMatches
                    };
                    
                    #ok(limitedMatches)
                };
            }
        };
        
        // Calculate match score between buyer and product
        private func calculateMatch(
            buyerProfile: BuyerProfile,
            product: ProductTypes.Product,
            criteria: BuyerMatchTypes.MatchingCriteria
        ) : ?PotentialMatch {
            var score: Float = 0.0;
            var reasons: [BuyerMatchTypes.MatchReason] = [];
            
            // Check minimum score threshold first
            let preliminaryScore = calculatePreliminaryScore(buyerProfile, product);
            if (preliminaryScore < criteria.minScore) {
                return null;
            };
            
            // Budget compatibility (40% weight)
            if (product.price <= buyerProfile.budget) {
                score += 0.4;
                reasons := Array.append(reasons, [#BudgetMatch]);
            };
            
            // Price check against criteria (30% weight)
            switch (criteria.maxPrice) {
                case (?maxPrice) {
                    if (product.price <= maxPrice) {
                        score += 0.3;
                        reasons := Array.append(reasons, [#PriceMatch]);
                    };
                };
                case null {
                    score += 0.3; // No price limit specified
                };
            };
            
            // Category match (20% weight)
            switch (criteria.categoryId) {
                case (?categoryId) {
                    if (product.categoryId == categoryId) {
                        score += 0.2;
                        reasons := Array.append(reasons, [#CategoryMatch]);
                    };
                };
                case null {
                    score += 0.2; // No category filter
                };
            };
            
            // Previous purchase history (10% weight)
            let historyMatch = checkPurchaseHistory(buyerProfile, product);
            score += historyMatch * 0.1;
            if (historyMatch > 0.0) {
                reasons := Array.append(reasons, [#PreviousPurchase]);
            };
            
            // Determine interest level and recommended action
            let interestLevel = determineInterestLevel(score);
            let recommendedAction = determineRecommendedAction(score, buyerProfile, product);
            
            let match = storage.createPotentialMatch(
                buyerProfile.id,
                product.createdBy,
                product.id,
                score,
                reasons,
                interestLevel,
                recommendedAction
            );
            
            ?match
        };
        
        private func calculatePreliminaryScore(
            buyerProfile: BuyerProfile,
            product: ProductTypes.Product
        ) : Float {
            var score: Float = 0.0;
            
            // Basic compatibility checks
            if (product.price <= buyerProfile.budget) {
                score += 0.6;
            };
            
            if (product.isActive) {
                score += 0.4;
            };
            
            score
        };
        
        private func checkPurchaseHistory(
            buyerProfile: BuyerProfile,
            product: ProductTypes.Product
        ) : Float {
            // Check if buyer has purchased from this seller before
            let sellerPurchases = Array.filter<BuyerMatchTypes.PurchaseRecord>(
                buyerProfile.purchaseHistory,
                func(record) = record.sellerId == product.createdBy
            );
            
            if (sellerPurchases.size() > 0) {
                0.8 // High score for previous seller
            } else {
                // Check for similar category purchases - simplified for now
                if (buyerProfile.purchaseHistory.size() > 0) {
                    0.4 // Medium score for category familiarity
                } else {
                    0.0
                }
            }
        };
        
        private func determineInterestLevel(score: Float) : BuyerMatchTypes.InterestLevel {
            if (score >= 0.8) { #VeryHigh }
            else if (score >= 0.6) { #High }
            else if (score >= 0.4) { #Medium }
            else if (score >= 0.2) { #Low }
            else { #VeryLow }
        };
        
        private func determineRecommendedAction(
            score: Float,
            buyerProfile: BuyerProfile,
            product: ProductTypes.Product
        ) : BuyerMatchTypes.RecommendedAction {
            if (score >= 0.8) { 
                #ImmediateContact 
            } else if (score >= 0.6) { 
                #SendSample 
            } else if (score >= 0.4) { 
                #SpecialOffer 
            } else if (product.price > buyerProfile.budget) {
                #PriceAlert
            } else { 
                #WatchAndWait 
            }
        };
        
        // Get matches for buyer
        public func getBuyerMatches(buyerId: Principal) : [PotentialMatch] {
            storage.getBuyerMatches(buyerId)
        };
        
        // Get matches for seller
        public func getSellerMatches(sellerId: Principal) : [PotentialMatch] {
            storage.getSellerMatches(sellerId)
        };
        
        // Mark match as viewed
        public func markMatchAsViewed(matchId: Nat) : Result.Result<PotentialMatch, BuyerMatchError> {
            storage.markMatchAsViewed(matchId)
        };
        
        // Set buyer interest in match
        public func setMatchInterest(
            matchId: Nat,
            isInterested: Bool
        ) : Result.Result<PotentialMatch, BuyerMatchError> {
            storage.setMatchInterest(matchId, isInterested)
        };
        
        // Add purchase record
        public func addPurchaseRecord(
            buyerId: Principal,
            record: BuyerMatchTypes.PurchaseRecord
        ) : Result.Result<BuyerProfile, BuyerMatchError> {
            storage.addPurchaseRecord(buyerId, record)
        };
        
        // Get all profiles (admin functions)
        public func getAllBuyerProfiles() : [BuyerProfile] {
            storage.getAllBuyerProfiles()
        };
        
        public func getAllSellerProfiles() : [SellerProfile] {
            storage.getAllSellerProfiles()
        };
        
        public func getAllMatches() : [PotentialMatch] {
            storage.getAllMatches()
        };
    };
}
