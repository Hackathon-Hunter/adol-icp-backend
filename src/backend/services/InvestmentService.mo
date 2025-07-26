import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Int "mo:base/Int";
import InvestmentTypes "../types/InvestmentTypes";
import InvestorTypes "../types/InvestorTypes";
import ProjectTypes "../types/ProjectTypes";
import NFTTypes "../types/NFTTypes";
import DummyICPTypes "../types/DummyICPTypes";
import InvestmentStorage "../storage/InvestmentStorage";

module InvestmentService {

    type Investment = InvestmentTypes.Investment;
    type InvestmentStatus = InvestmentTypes.InvestmentStatus;
    type PurchaseRequest = InvestmentTypes.PurchaseRequest;
    type PurchaseResult = InvestmentTypes.PurchaseResult;
    type InvestmentSummary = InvestmentTypes.InvestmentSummary;
    type TokenId = NFTTypes.TokenId;
    type Investor = InvestorTypes.Investor;
    type Project = ProjectTypes.Project;
    type NFTCollection = NFTTypes.NFTCollection;

    public class InvestmentManager() {

        private let storage = InvestmentStorage.InvestmentStore();

        // System functions for upgrades
        public func preupgrade() : [(Text, Investment)] {
            storage.preupgrade();
        };

        public func postupgrade(entries : [(Text, Investment)]) {
            storage.postupgrade(entries);
        };

        // Create investment record with ICP payment integration
        public func createInvestmentWithICP(
            request : PurchaseRequest,
            investor : Investor,
            project : Project,
            collection : NFTCollection,
            nftManager : {
                purchaseTokensWithICP : (NFTTypes.PurchaseRequest, Principal, Principal) -> Result.Result<{ tokenIds : [TokenId]; paymentDetails : DummyICPTypes.PaymentSuccess; totalSupplyAfter : Nat }, Text>;
            },
            projectService : {
                updateProjectFunding : (Text, Nat) -> Result.Result<(), Text>;
            },
        ) : PurchaseResult {

            // Validate the purchase request
            switch (validatePurchaseRequest(request, investor, project, collection)) {
                case (#err(error)) { return #err(error) };
                case (#ok()) {};
            };

            // Generate investment ID
            let investmentId = "inv-" # project.id # "-" # investor.id # "-" # Int.toText(Time.now());

            // Calculate total cost in USD cents
            let totalCostUSD = collection.pricePerToken * request.quantity;

            // Create NFT purchase request
            let nftPurchaseRequest : NFTTypes.PurchaseRequest = {
                collectionId = request.collectionId;
                quantity = request.quantity;
                paymentAmount = totalCostUSD; // This will be converted to ICP internally
                useICP = ?true;
            };

            // Process the NFT purchase with ICP payment
            switch (
                nftManager.purchaseTokensWithICP(
                    nftPurchaseRequest,
                    investor.principal,
                    project.founderPrincipal // Send funds directly to project founder
                )
            ) {
                case (#err(error)) {
                    return #err("NFT purchase failed: " # error);
                };
                case (#ok(purchaseResult)) {

                    // Update project funding with the USD amount
                    switch (projectService.updateProjectFunding(project.id, totalCostUSD)) {
                        case (#err(error)) {
                            // Note: At this point NFTs are already minted and payment processed
                            // In a production system, you'd want to implement proper rollback
                            return #err("Project funding update failed: " # error);
                        };
                        case (#ok()) {

                            // Create investment record
                            let newInvestment : Investment = {
                                id = investmentId;
                                investorId = investor.id;
                                investorPrincipal = investor.principal;
                                projectId = project.id;
                                founderId = project.founderId;
                                founderPrincipal = project.founderPrincipal;
                                collectionId = request.collectionId;
                                amount = purchaseResult.paymentDetails.amountICP; // Store ICP amount
                                quantity = request.quantity;
                                pricePerToken = collection.pricePerToken; // USD price per token
                                investmentDate = Time.now();
                                status = #Completed;
                                transactionHash = ?Int.toText(purchaseResult.paymentDetails.transactionId);
                                tokenIds = purchaseResult.tokenIds;
                            };

                            // Store investment
                            storage.putInvestment(investmentId, newInvestment);

                            #ok(newInvestment);
                        };
                    };
                };
            };
        };

        // Legacy purchase function (for backward compatibility)
        public func purchaseNFT(
            request : PurchaseRequest,
            investor : Investor,
            project : Project,
            collection : NFTCollection,
        ) : PurchaseResult {

            // Validate the purchase request
            switch (validatePurchaseRequest(request, investor, project, collection)) {
                case (#err(error)) { return #err(error) };
                case (#ok()) {};
            };

            // Generate investment ID
            let investmentId = "inv-" # project.id # "-" # investor.id # "-" # Int.toText(Time.now());

            // Create investment record (simplified version without actual payment processing)
            let newInvestment : Investment = {
                id = investmentId;
                investorId = investor.id;
                investorPrincipal = investor.principal;
                projectId = project.id;
                founderId = project.founderId;
                founderPrincipal = project.founderPrincipal;
                collectionId = request.collectionId;
                amount = request.paymentAmount; // This should now be in ICP e8s
                quantity = request.quantity;
                pricePerToken = collection.pricePerToken;
                investmentDate = Time.now();
                status = #Completed;
                transactionHash = ?("simulated-tx-hash-" # investmentId);
                tokenIds = generateSimulatedTokenIds(request.quantity); // Simulated token IDs
            };

            storage.putInvestment(investmentId, newInvestment);

            #ok(newInvestment);
        };

        // Validate purchase request
        private func validatePurchaseRequest(
            request : PurchaseRequest,
            investor : Investor,
            project : Project,
            collection : NFTCollection,
        ) : Result.Result<(), Text> {

            // Check if investor is verified (optional requirement)
            if (not investor.isVerified) {
                return #err("Investor must be verified to make purchases");
            };

            // Check if project is active
            switch (project.status) {
                case (#Active) {};
                case (_) {
                    return #err("Project is not active for investment");
                };
            };

            // Check if collection is active
            if (not collection.isActive) {
                return #err("NFT collection is not active");
            };

            // Check quantity
            if (request.quantity == 0) {
                return #err("Quantity must be greater than 0");
            };

            // Check if enough NFTs are available
            let remainingSupply = Nat.sub(collection.maxSupply, collection.totalSupply);
            if (request.quantity > remainingSupply) {
                return #err("Not enough NFTs available. Remaining: " # Nat.toText(remainingSupply));
            };

            // Check payment amount (basic validation)
            if (request.paymentAmount == 0) {
                return #err("Payment amount must be greater than 0");
            };

            // Validate minimum investment amount
            let totalCost = collection.pricePerToken * request.quantity;
            if (totalCost < project.minInvestment) {
                return #err("Investment amount below minimum required: $" # Nat.toText(project.minInvestment / 100));
            };

            // Validate maximum investment amount (if set)
            switch (project.maxInvestment) {
                case (?maxInv) {
                    if (totalCost > maxInv) {
                        return #err("Investment amount exceeds maximum allowed: $" # Nat.toText(maxInv / 100));
                    };
                };
                case null {};
            };

            #ok(());
        };

        // Generate simulated token IDs (for legacy compatibility)
        private func generateSimulatedTokenIds(quantity : Nat) : [TokenId] {
            var tokenIds : [TokenId] = [];
            var i = 0;
            while (i < quantity) {
                tokenIds := Array.append<TokenId>(tokenIds, [1000 + i]); // Simulated token IDs
                i += 1;
            };
            tokenIds;
        };

        // Get investment by ID
        public func getInvestment(investmentId : Text) : ?Investment {
            storage.getInvestment(investmentId);
        };

        // Get investments by investor
        public func getInvestmentsByInvestor(investorId : Text) : [Investment] {
            storage.getInvestmentsByInvestor(investorId);
        };

        // Get investments by investor principal
        public func getInvestmentsByInvestorPrincipal(principal : Principal) : [Investment] {
            storage.getInvestmentsByInvestorPrincipal(principal);
        };

        // Get investments by project
        public func getInvestmentsByProject(projectId : Text) : [Investment] {
            storage.getInvestmentsByProject(projectId);
        };

        // Get investments by founder
        public func getInvestmentsByFounder(founderId : Text) : [Investment] {
            storage.getInvestmentsByFounder(founderId);
        };

        // Get investment summaries for investor with current values
        public func getInvestmentSummariesForInvestor(
            investorId : Text,
            projects : [Project],
            icpToken : {
                icpE8sToUSDCents : (Nat) -> Nat;
                getICPToUSDRate : () -> Float;
            },
        ) : [InvestmentSummary] {
            let investments = storage.getInvestmentsByInvestor(investorId);

            Array.mapFilter<Investment, InvestmentSummary>(
                investments,
                func(investment : Investment) : ?InvestmentSummary {
                    // Find project company name
                    let projectTitle = switch (Array.find<Project>(projects, func(p : Project) : Bool { p.id == investment.projectId })) {
                        case (?project) { project.companyName };
                        case null { "Unknown Project" };
                    };

                    // Calculate current USD value of ICP investment
                    let currentUSDValue = icpToken.icpE8sToUSDCents(investment.amount);

                    ?{
                        id = investment.id;
                        projectTitle = projectTitle;
                        amount = investment.amount; // ICP amount in e8s
                        quantity = investment.quantity;
                        investmentDate = investment.investmentDate;
                        status = investment.status;
                        currentValue = ?currentUSDValue; // Current USD value
                    };
                },
            );
        };

        // Get total investment amount by investor (in USD)
        public func getTotalInvestmentByInvestor(
            investorId : Text,
            icpToken : {
                icpE8sToUSDCents : (Nat) -> Nat;
            },
        ) : Nat {
            let investments = storage.getInvestmentsByInvestor(investorId);
            Array.foldLeft<Investment, Nat>(
                investments,
                0,
                func(acc : Nat, investment : Investment) : Nat {
                    acc + icpToken.icpE8sToUSDCents(investment.amount);
                },
            );
        };

        // Get total investment amount by project (in USD)
        public func getTotalInvestmentByProject(
            projectId : Text,
            icpToken : {
                icpE8sToUSDCents : (Nat) -> Nat;
            },
        ) : Nat {
            let investments = storage.getInvestmentsByProject(projectId);
            Array.foldLeft<Investment, Nat>(
                investments,
                0,
                func(acc : Nat, investment : Investment) : Nat {
                    acc + icpToken.icpE8sToUSDCents(investment.amount);
                },
            );
        };

        // Get investment statistics
        public func getInvestmentStats() : {
            totalInvestments : Nat;
            totalInvestors : Nat;
            totalProjects : Nat;
        } {
            let allInvestments = storage.getAllInvestments();
            let uniqueInvestors = Array.foldLeft<Investment, [Text]>(
                allInvestments,
                [],
                func(acc : [Text], investment : Investment) : [Text] {
                    if (Array.find<Text>(acc, func(id : Text) : Bool { id == investment.investorId }) == null) {
                        Array.append<Text>(acc, [investment.investorId]);
                    } else {
                        acc;
                    };
                },
            );
            let uniqueProjects = Array.foldLeft<Investment, [Text]>(
                allInvestments,
                [],
                func(acc : [Text], investment : Investment) : [Text] {
                    if (Array.find<Text>(acc, func(id : Text) : Bool { id == investment.projectId }) == null) {
                        Array.append<Text>(acc, [investment.projectId]);
                    } else {
                        acc;
                    };
                },
            );

            {
                totalInvestments = allInvestments.size();
                totalInvestors = uniqueInvestors.size();
                totalProjects = uniqueProjects.size();
            };
        };
    };
};
