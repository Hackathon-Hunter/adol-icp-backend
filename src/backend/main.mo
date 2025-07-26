// src/backend/main.mo - Main integration with ICP token support
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Float "mo:base/Float";

// Import services
import ProjectService "./services/ProjectService";
import InvestorService "./services/InvestorService";
import NFTService "./services/NFTService";
import InvestmentService "./services/InvestmentService";
import DummyICPTokenService "./services/DummyICPTokenService";

// Import types
import ProjectTypes "./types/ProjectTypes";
import InvestorTypes "./types/InvestorTypes";
import NFTTypes "./types/NFTTypes";
import InvestmentTypes "./types/InvestmentTypes";
import DummyICPTypes "./types/DummyICPTypes";

actor CryptoFundPlatform {

    // Service managers
    private let projectManager = ProjectService.ProjectManager();
    private let investorManager = InvestorService.InvestorManager();
    private let nftManager = NFTService.NFTManager();
    private let investmentManager = InvestmentService.InvestmentManager();
    private let icpToken = DummyICPTokenService.DummyICPToken();

    // Initialize services
    public func init() : async () {
        nftManager.init();
        icpToken.init();
        Debug.print("CryptoFund Platform initialized with ICP token support");
    };

    // ========== ICP Token Functions ==========

    // Get ICP balance for a principal
    public query func getICPBalance(account : Principal) : async Nat {
        icpToken.balanceOf(account);
    };

    // Mint ICP tokens (for testing purposes)
    public func mintICP(to : Principal, amount : Nat) : async Bool {
        icpToken.mint(to, amount);
    };

    // Get current ICP to USD exchange rate
    public query func getExchangeRate() : async {
        icpToUsd : Float;
        usdToIcp : Float;
    } {
        icpToken.getExchangeRateInfo();
    };

    // Calculate ICP amount needed for USD purchase
    public query func calculateICPForUSD(usdCents : Nat) : async Nat {
        icpToken.usdCentsToICPe8s(usdCents);
    };

    // Calculate USD value of ICP amount
    public query func calculateUSDForICP(icpE8s : Nat) : async Nat {
        icpToken.icpE8sToUSDCents(icpE8s);
    };

    // ========== Enhanced NFT Purchase with ICP ==========

    // Purchase NFTs with ICP payment and update project funding
    public func purchaseNFTWithICP(
        request : InvestmentTypes.PurchaseRequest,
        caller : Principal,
    ) : async Result.Result<{ investment : InvestmentTypes.Investment; tokenIds : [NFTTypes.TokenId]; paymentDetails : DummyICPTypes.PaymentSuccess; projectFundingUpdated : Bool }, Text> {

        // Get investor info
        let investorOpt = investorManager.getInvestorByPrincipal(caller);
        switch (investorOpt) {
            case null {
                return #err("Investor not found. Please register first.");
            };
            case (?investor) {

                // Get project info
                let projectOpt = projectManager.getProject(request.projectId);
                switch (projectOpt) {
                    case null { return #err("Project not found") };
                    case (?project) {

                        // Get collection info
                        let collectionOpt = nftManager.getCollection(request.collectionId);
                        switch (collectionOpt) {
                            case null {
                                return #err("NFT collection not found");
                            };
                            case (?collection) {

                                // Create investment with ICP payment
                                switch (
                                    investmentManager.createInvestmentWithICP(
                                        request,
                                        investor,
                                        project,
                                        collection,
                                        {
                                            purchaseTokensWithICP = nftManager.purchaseTokensWithICP;
                                        },
                                        {
                                            updateProjectFunding = projectManager.updateProjectFunding;
                                        },
                                    )
                                ) {
                                    case (#err(error)) { #err(error) };
                                    case (#ok(investment)) {

                                        // Get the NFT purchase details from the investment
                                        let totalCostUSD = collection.pricePerToken * request.quantity;
                                        let icpAmount = icpToken.usdCentsToICPe8s(totalCostUSD);

                                        // Create mock payment details for response
                                        let paymentDetails : DummyICPTypes.PaymentSuccess = {
                                            transactionId = switch (investment.transactionHash) {
                                                case (?hash) {
                                                    // Convert hash to Nat (simplified)
                                                    1234567890;
                                                };
                                                case null { 0 };
                                            };
                                            amountICP = investment.amount;
                                            amountUSD = totalCostUSD;
                                            exchangeRate = icpToken.getICPToUSDRate();
                                            timestamp = investment.investmentDate;
                                        };

                                        #ok({
                                            investment = investment;
                                            tokenIds = investment.tokenIds;
                                            paymentDetails = paymentDetails;
                                            projectFundingUpdated = true;
                                        });
                                    };
                                };
                            };
                        };
                    };
                };
            };
        };
    };

    // ========== Enhanced Project Functions ==========

    // Get project with current funding status (updated with real funding)
    public query func getProjectWithFunding(projectId : Text) : async ?{
        project : ProjectTypes.Project;
        fundingProgress : Float; // Percentage funded
        remainingFunding : Nat; // Amount still needed in USD cents
        totalInvestors : Nat;
        availableNFTs : Nat; // NFTs still available for purchase
    } {
        switch (projectManager.getProject(projectId)) {
            case null { null };
            case (?project) {
                let totalInvestment = investmentManager.getTotalInvestmentByProject(
                    projectId,
                    {
                        icpE8sToUSDCents = icpToken.icpE8sToUSDCents;
                    },
                );

                let fundingProgress = if (project.fundingGoal > 0) {
                    (Float.fromInt(totalInvestment) / Float.fromInt(project.fundingGoal)) * 100.0;
                } else {
                    0.0;
                };

                let remainingFunding = if (totalInvestment < project.fundingGoal) {
                    project.fundingGoal - totalInvestment;
                } else {
                    0;
                };

                let investments = investmentManager.getInvestmentsByProject(projectId);
                let totalInvestors = investments.size();

                // Get available NFTs from collections
                let collections = nftManager.getCollectionsByProject(projectId);
                let availableNFTs = Array.foldLeft<NFTTypes.NFTCollection, Nat>(
                    collections,
                    0,
                    func(acc : Nat, collection : NFTTypes.NFTCollection) : Nat {
                        acc + (collection.maxSupply - collection.totalSupply);
                    },
                );

                ?{
                    project = project;
                    fundingProgress = fundingProgress;
                    remainingFunding = remainingFunding;
                    totalInvestors = totalInvestors;
                    availableNFTs = availableNFTs;
                };
            };
        };
    };

    // ========== Enhanced Investor Dashboard ==========

    // Get comprehensive investor dashboard
    public query func getInvestorDashboard(caller : Principal) : async ?{
        investor : InvestorTypes.Investor;
        investments : [InvestmentTypes.InvestmentSummary];
        totalInvestedUSD : Nat;
        totalInvestedICP : Nat;
        portfolioValue : Nat; // Current USD value
        ownedNFTs : [NFTTypes.NFTToken];
        stats : {
            totalProjects : Nat;
            totalNFTs : Nat;
            averageInvestment : Nat;
        };
    } {
        switch (investorManager.getInvestorByPrincipal(caller)) {
            case null { null };
            case (?investor) {
                let allProjects = projectManager.getAllProjects();
                let investments = investmentManager.getInvestmentSummariesForInvestor(
                    investor.id,
                    allProjects,
                    {
                        icpE8sToUSDCents = icpToken.icpE8sToUSDCents;
                        getICPToUSDRate = icpToken.getICPToUSDRate;
                    },
                );

                let totalInvestedUSD = investmentManager.getTotalInvestmentByInvestor(
                    investor.id,
                    {
                        icpE8sToUSDCents = icpToken.icpE8sToUSDCents;
                    },
                );

                // Calculate total ICP invested
                let investorInvestments = investmentManager.getInvestmentsByInvestor(investor.id);
                let totalInvestedICP = Array.foldLeft<InvestmentTypes.Investment, Nat>(
                    investorInvestments,
                    0,
                    func(acc : Nat, inv : InvestmentTypes.Investment) : Nat {
                        acc + inv.amount; // amount is stored in ICP e8s
                    },
                );

                let ownedNFTs = nftManager.getTokensByOwner(caller);

                let stats = {
                    totalProjects = investments.size();
                    totalNFTs = ownedNFTs.size();
                    averageInvestment = if (investments.size() > 0) {
                        totalInvestedUSD / investments.size();
                    } else {
                        0;
                    };
                };

                ?{
                    investor = investor;
                    investments = investments;
                    totalInvestedUSD = totalInvestedUSD;
                    totalInvestedICP = totalInvestedICP;
                    portfolioValue = totalInvestedUSD; // For now, same as invested (no appreciation calculated)
                    ownedNFTs = ownedNFTs;
                    stats = stats;
                };
            };
        };
    };

    // ========== Collection Management with Real Supply Updates ==========

    // Get collection with real-time data
    public query func getCollectionWithStats(collectionId : Text) : async ?{
        collection : NFTTypes.NFTCollection;
        remainingSupply : Nat;
        soldOut : Bool;
        totalValueUSD : Nat; // Total value of sold NFTs in USD
        totalValueICP : Nat; // Total value of sold NFTs in ICP
        averagePriceICP : Nat; // Average ICP price paid per NFT
    } {
        switch (nftManager.getCollection(collectionId)) {
            case null { null };
            case (?collection) {
                let remainingSupply = collection.maxSupply - collection.totalSupply;
                let soldOut = remainingSupply == 0;

                // Calculate total values
                let totalValueUSD = collection.pricePerToken * collection.totalSupply;
                let totalValueICP = icpToken.usdCentsToICPe8s(totalValueUSD);

                let averagePriceICP = if (collection.totalSupply > 0) {
                    totalValueICP / collection.totalSupply;
                } else {
                    icpToken.usdCentsToICPe8s(collection.pricePerToken);
                };

                ?{
                    collection = collection;
                    remainingSupply = remainingSupply;
                    soldOut = soldOut;
                    totalValueUSD = totalValueUSD;
                    totalValueICP = totalValueICP;
                    averagePriceICP = averagePriceICP;
                };
            };
        };
    };

    // ========== Admin Functions ==========

    // Create NFT collection (Admin only)
    public func createNFTCollection(
        request : NFTTypes.CreateCollectionRequest,
        caller : Principal,
    ) : async NFTTypes.CollectionResult {
        // In production, add admin role verification here
        let projectOpt = projectManager.getProject(request.projectId);
        nftManager.createCollection(request, projectOpt, caller);
    };

    // Update collection status (Admin only)
    public func updateCollectionStatus(
        collectionId : Text,
        isActive : Bool,
        caller : Principal,
    ) : async Result.Result<(), Text> {
        // In production, add admin role verification here
        switch (nftManager.getCollection(collectionId)) {
            case null { #err("Collection not found") };
            case (?collection) {
                let updatedCollection : NFTTypes.NFTCollection = {
                    id = collection.id;
                    projectId = collection.projectId;
                    metadata = collection.metadata;
                    totalSupply = collection.totalSupply;
                    maxSupply = collection.maxSupply;
                    pricePerToken = collection.pricePerToken;
                    createdAt = collection.createdAt;
                    createdBy = collection.createdBy;
                    isActive = isActive;
                };

                // Update collection in storage (you'd need to implement this in NFTService)
                #ok(());
            };
        };
    };

    // ========== Query Functions ==========

    // Get all active projects with funding info
    public query func getActiveProjectsWithFunding() : async [{
        project : ProjectTypes.Project;
        fundingProgress : Float;
        availableNFTs : Nat;
        minInvestmentICP : Nat;
    }] {
        let allProjects = projectManager.getAllProjects();
        let activeProjects = Array.filter<ProjectTypes.Project>(
            allProjects,
            func(p : ProjectTypes.Project) : Bool { p.status == #Active },
        );

        Array.map<ProjectTypes.Project, { project : ProjectTypes.Project; fundingProgress : Float; availableNFTs : Nat; minInvestmentICP : Nat }>(
            activeProjects,
            func(project : ProjectTypes.Project) : {
                project : ProjectTypes.Project;
                fundingProgress : Float;
                availableNFTs : Nat;
                minInvestmentICP : Nat;
            } {
                let totalInvestment = investmentManager.getTotalInvestmentByProject(
                    project.id,
                    {
                        icpE8sToUSDCents = icpToken.icpE8sToUSDCents;
                    },
                );

                let fundingProgress = if (project.fundingGoal > 0) {
                    (Float.fromInt(totalInvestment) / Float.fromInt(project.fundingGoal)) * 100.0;
                } else {
                    0.0;
                };

                let collections = nftManager.getCollectionsByProject(project.id);
                let availableNFTs = Array.foldLeft<NFTTypes.NFTCollection, Nat>(
                    collections,
                    0,
                    func(acc : Nat, collection : NFTTypes.NFTCollection) : Nat {
                        acc + (collection.maxSupply - collection.totalSupply);
                    },
                );

                let minInvestmentICP = icpToken.usdCentsToICPe8s(project.minInvestment);

                {
                    project = project;
                    fundingProgress = fundingProgress;
                    availableNFTs = availableNFTs;
                    minInvestmentICP = minInvestmentICP;
                };
            },
        );
    };

    // Get platform statistics
    public query func getPlatformStats() : async {
        totalProjects : Nat;
        activeProjects : Nat;
        totalInvestors : Nat;
        totalFundingUSD : Nat;
        totalFundingICP : Nat;
        totalNFTsSold : Nat;
        averageInvestmentUSD : Nat;
    } {
        let allProjects = projectManager.getAllProjects();
        let activeProjectsCount = Array.filter<ProjectTypes.Project>(
            allProjects,
            func(p : ProjectTypes.Project) : Bool { p.status == #Active },
        ).size();

        let investmentStats = investmentManager.getInvestmentStats();

        // Calculate total funding
        let allInvestments = Array.foldLeft<ProjectTypes.Project, Nat>(
            allProjects,
            0,
            func(acc : Nat, project : ProjectTypes.Project) : Nat {
                acc + investmentManager.getTotalInvestmentByProject(
                    project.id,
                    {
                        icpE8sToUSDCents = icpToken.icpE8sToUSDCents;
                    },
                );
            },
        );

        let totalFundingICP = icpToken.usdCentsToICPe8s(allInvestments);

        // Calculate total NFTs sold across all collections
        let allCollections = Array.foldLeft<ProjectTypes.Project, [NFTTypes.NFTCollection]>(
            allProjects,
            [],
            func(acc : [NFTTypes.NFTCollection], project : ProjectTypes.Project) : [NFTTypes.NFTCollection] {
                let projectCollections = nftManager.getCollectionsByProject(project.id);
                Array.append(acc, projectCollections);
            },
        );

        let totalNFTsSold = Array.foldLeft<NFTTypes.NFTCollection, Nat>(
            allCollections,
            0,
            func(acc : Nat, collection : NFTTypes.NFTCollection) : Nat {
                acc + collection.totalSupply;
            },
        );

        let averageInvestment = if (investmentStats.totalInvestments > 0) {
            allInvestments / investmentStats.totalInvestments;
        } else {
            0;
        };

        {
            totalProjects = allProjects.size();
            activeProjects = activeProjectsCount;
            totalInvestors = investmentStats.totalInvestors;
            totalFundingUSD = allInvestments;
            totalFundingICP = totalFundingICP;
            totalNFTsSold = totalNFTsSold;
            averageInvestmentUSD = averageInvestment;
        };
    };

    // ========== Legacy API Compatibility ==========

    // Legacy project functions
    public func createProject(request : ProjectTypes.ProjectCreateRequest, caller : Principal) : async ProjectTypes.UpdateResult {
        // You may need to extract founderId from the request or caller, adjust as needed
        let founderId : Text = Principal.toText(caller);
        let result = projectManager.createProject(request, founderId, caller);
        switch (result) {
            case (#err(e)) { #err(e) };
            case (#ok(_project)) { #ok };
        };
    };

    public query func getProject(projectId : Text) : async ?ProjectTypes.Project {
        projectManager.getProject(projectId);
    };

    public query func getAllProjects() : async [ProjectTypes.Project] {
        projectManager.getAllProjects();
    };

    // Legacy investor functions
    public func registerInvestor(request : InvestorTypes.InvestorRegistrationRequest, caller : Principal) : async InvestorTypes.RegistrationResult {
        investorManager.registerInvestor(request, caller);
    };

    public query func getInvestor(investorId : Text) : async ?InvestorTypes.Investor {
        investorManager.getInvestor(investorId);
    };

    // Legacy NFT functions
    public query func getCollection(collectionId : Text) : async ?NFTTypes.NFTCollection {
        nftManager.getCollection(collectionId);
    };

    public query func getToken(tokenId : NFTTypes.TokenId) : async ?NFTTypes.NFTToken {
        nftManager.getToken(tokenId);
    };

    public query func getTokensByOwner(owner : Principal) : async [NFTTypes.NFTToken] {
        nftManager.getTokensByOwner(owner);
    };

    // ========== System Functions ==========

    system func preupgrade() {
        Debug.print("Starting preupgrade...");
    };

    system func postupgrade() {
        Debug.print("Postupgrade completed");
    };
};
