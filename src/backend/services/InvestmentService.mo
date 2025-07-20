import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import InvestmentTypes "../types/InvestmentTypes";
import ProjectTypes "../types/ProjectTypes";
import InvestorTypes "../types/InvestorTypes";
import FounderTypes "../types/FounderTypes";
import NFTTypes "../types/NFTTypes";
import InvestmentStorage "../storage/InvestmentStorage";

module InvestmentService {

    type Investment = InvestmentTypes.Investment;
    type PurchaseRequest = InvestmentTypes.PurchaseRequest;
    type PurchaseResult = InvestmentTypes.PurchaseResult;
    type InvestmentStatus = InvestmentTypes.InvestmentStatus;
    type InvestmentSummary = InvestmentTypes.InvestmentSummary;
    type ICPTransferRequest = InvestmentTypes.ICPTransferRequest;
    type TransferResult = InvestmentTypes.TransferResult;

    // Dependencies (these would be injected in a real implementation)
    type Project = ProjectTypes.Project;
    type Investor = InvestorTypes.Investor;
    type Founder = FounderTypes.Founder;
    type NFTCollection = NFTTypes.NFTCollection;
    type TokenId = NFTTypes.TokenId;

    public class InvestmentManager() {

        private let storage = InvestmentStorage.InvestmentStore();

        // System functions for upgrades
        public func preupgrade() : [(Text, Investment)] {
            storage.preupgrade();
        };

        public func postupgrade(entries : [(Text, Investment)]) {
            storage.postupgrade(entries);
        };

        // Purchase NFTs from a project
        public func purchaseNFTs(
            request : PurchaseRequest,
            investor : Investor,
            project : Project,
            founder : Founder,
            collection : NFTCollection,
            _callerPrincipal : Principal,
        ) : async PurchaseResult {

            // Validate purchase request
            switch (validatePurchaseRequest(request, investor, project, collection)) {
                case (#err(error)) { return #err(error) };
                case (#ok(())) {};
            };

            // Calculate total cost
            let totalCost = collection.pricePerToken * request.quantity;

            // Check if payment amount is sufficient
            if (request.paymentAmount < totalCost) {
                return #err("Insufficient payment. Required: " # Nat.toText(totalCost) # " ICP");
            };

            // Create investment record
            let investmentId = storage.generateInvestmentId();
            let currentTime = Time.now();

            let newInvestment : Investment = {
                id = investmentId;
                investorId = investor.id;
                investorPrincipal = investor.principal;
                projectId = project.id;
                founderId = founder.id;
                founderPrincipal = founder.principal;
                collectionId = collection.id;
                amount = totalCost;
                quantity = request.quantity;
                pricePerToken = collection.pricePerToken;
                investmentDate = currentTime;
                status = #Processing;
                transactionHash = null; // Will be set after transfer
                tokenIds = []; // Will be set after NFT minting
            };

            // Store investment
            storage.putInvestment(investmentId, newInvestment);

            // TODO: In a real implementation, you would:
            // 1. Transfer ICP from investor to founder
            // 2. Mint NFTs to investor
            // 3. Update investment status based on results

            // For this simple implementation, we'll simulate success
            let updatedInvestment : Investment = {
                id = newInvestment.id;
                investorId = newInvestment.investorId;
                investorPrincipal = newInvestment.investorPrincipal;
                projectId = newInvestment.projectId;
                founderId = newInvestment.founderId;
                founderPrincipal = newInvestment.founderPrincipal;
                collectionId = newInvestment.collectionId;
                amount = newInvestment.amount;
                quantity = newInvestment.quantity;
                pricePerToken = newInvestment.pricePerToken;
                investmentDate = newInvestment.investmentDate;
                status = #Completed;
                transactionHash = ?("simulated-tx-hash-" # investmentId);
                tokenIds = generateSimulatedTokenIds(request.quantity); // Simulated token IDs
            };

            ignore storage.updateInvestment(investmentId, updatedInvestment);

            #ok(updatedInvestment);
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

            // Check payment amount
            if (request.paymentAmount == 0) {
                return #err("Payment amount must be greater than 0");
            };

            #ok(());
        };

        // Generate simulated token IDs (in real implementation, this would come from NFT service)
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

        // Get investment summaries for investor
        public func getInvestmentSummariesForInvestor(investorId : Text, projects : [Project]) : [InvestmentSummary] {
            let investments = storage.getInvestmentsByInvestor(investorId);

            Array.mapFilter<Investment, InvestmentSummary>(
                investments,
                func(investment : Investment) : ?InvestmentSummary {
                    // Find project title
                    let projectTitle = switch (Array.find<Project>(projects, func(p : Project) : Bool { p.id == investment.projectId })) {
                        case (?project) { project.title };
                        case null { "Unknown Project" };
                    };

                    ?{
                        id = investment.id;
                        projectTitle = projectTitle;
                        amount = investment.amount;
                        quantity = investment.quantity;
                        investmentDate = investment.investmentDate;
                        status = investment.status;
                        currentValue = ?investment.amount; // Simplified - same as invested amount
                    };
                },
            );
        };

        // Get investment statistics
        public func getInvestmentStats() : {
            totalInvestments : Nat;
            totalAmount : Nat;
            completedInvestments : Nat;
            pendingInvestments : Nat;
        } {
            let allInvestments = storage.getAllInvestments();
            var totalAmount : Nat = 0;
            var completedCount : Nat = 0;
            var pendingCount : Nat = 0;

            for (investment in allInvestments.vals()) {
                switch (investment.status) {
                    case (#Completed) {
                        completedCount += 1;
                        totalAmount += investment.amount;
                    };
                    case (#Pending or #Processing) {
                        pendingCount += 1;
                    };
                    case (_) {};
                };
            };

            {
                totalInvestments = allInvestments.size();
                totalAmount = totalAmount;
                completedInvestments = completedCount;
                pendingInvestments = pendingCount;
            };
        };

        // Get total funding raised for a project
        public func getTotalFundingForProject(projectId : Text) : Nat {
            storage.getTotalInvestmentForProject(projectId);
        };

        // Get investor count for a project
        public func getInvestorCountForProject(projectId : Text) : Nat {
            storage.getInvestorCountForProject(projectId);
        };

        // Update investment status (admin function)
        public func updateInvestmentStatus(investmentId : Text, newStatus : InvestmentStatus) : Result.Result<(), Text> {
            switch (storage.getInvestment(investmentId)) {
                case null { #err("Investment not found") };
                case (?investment) {
                    let updatedInvestment : Investment = {
                        id = investment.id;
                        investorId = investment.investorId;
                        investorPrincipal = investment.investorPrincipal;
                        projectId = investment.projectId;
                        founderId = investment.founderId;
                        founderPrincipal = investment.founderPrincipal;
                        collectionId = investment.collectionId;
                        amount = investment.amount;
                        quantity = investment.quantity;
                        pricePerToken = investment.pricePerToken;
                        investmentDate = investment.investmentDate;
                        status = newStatus;
                        transactionHash = investment.transactionHash;
                        tokenIds = investment.tokenIds;
                    };

                    if (storage.updateInvestment(investmentId, updatedInvestment)) {
                        #ok(());
                    } else {
                        #err("Failed to update investment status");
                    };
                };
            };
        };
    };
};
