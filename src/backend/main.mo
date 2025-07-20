import FounderTypes "./types/FounderTypes";
import ProjectTypes "./types/ProjectTypes";
import InvestorTypes "./types/InvestorTypes";
import InvestmentTypes "./types/InvestmentTypes";
import NFTTypes "./types/NFTTypes";
import FounderService "./services/FounderService";
import ProjectService "./services/ProjectService";
import InvestorService "./services/InvestorService";
import InvestmentService "./services/InvestmentService";
import NFTService "./services/NFTService";
import ICPTransferService "./services/ICPTransferService";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";

actor PlantifyBackend {

    // Founder types
    type Founder = FounderTypes.Founder;
    type FounderRegistrationRequest = FounderTypes.FounderRegistrationRequest;
    type FounderRegistrationResult = FounderTypes.RegistrationResult;
    type FounderUpdateResult = FounderTypes.UpdateResult;

    // Project types
    type Project = ProjectTypes.Project;
    type ProjectCreateRequest = ProjectTypes.ProjectCreateRequest;
    type ProjectUpdateRequest = ProjectTypes.ProjectUpdateRequest;
    type ProjectResult = ProjectTypes.ProjectResult;
    type ProjectUpdateResult = ProjectTypes.UpdateResult;
    type ProjectStatus = ProjectTypes.ProjectStatus;

    // Investor types
    type Investor = InvestorTypes.Investor;
    type InvestorRegistrationRequest = InvestorTypes.InvestorRegistrationRequest;
    type InvestorRegistrationResult = InvestorTypes.RegistrationResult;
    type InvestorUpdateResult = InvestorTypes.UpdateResult;

    // Investment types
    type Investment = InvestmentTypes.Investment;
    type PurchaseRequest = InvestmentTypes.PurchaseRequest;
    type PurchaseResult = InvestmentTypes.PurchaseResult;
    type InvestmentSummary = InvestmentTypes.InvestmentSummary;
    type ICPTransferRequest = InvestmentTypes.ICPTransferRequest;
    type TransferResult = InvestmentTypes.TransferResult;

    // NFT types
    type NFTCollection = NFTTypes.NFTCollection;
    type CreateCollectionRequest = NFTTypes.CreateCollectionRequest;
    type CollectionResult = NFTTypes.CollectionResult;

    // Initialize managers
    private let founderManager = FounderService.FounderManager();
    private let projectManager = ProjectService.ProjectManager();
    private let investorManager = InvestorService.InvestorManager();
    private let investmentManager = InvestmentService.InvestmentManager();
    private let nftManager = NFTService.NFTManager();
    private let icpTransferManager = ICPTransferService.ICPTransferManager();

    // Stable variables for upgrades
    private stable var foundersData : [(Text, Founder)] = [];
    private stable var projectsData : [(Text, Project)] = [];
    private stable var investorsData : [(Text, Investor)] = [];
    private stable var investmentsData : [(Text, Investment)] = [];
    private stable var nftCollectionsData : [(Text, NFTCollection)] = [];
    private stable var nftTokensData : [(Nat, NFTTypes.NFTToken)] = [];
    private stable var nftOwnershipData : [(Principal, [Nat])] = [];

    // System functions for upgrades
    system func preupgrade() {
        foundersData := founderManager.preupgrade();
        projectsData := projectManager.preupgrade();
        investorsData := investorManager.preupgrade();
        investmentsData := investmentManager.preupgrade();
        let (collections, tokens, ownership) = nftManager.preupgrade();
        nftCollectionsData := collections;
        nftTokensData := tokens;
        nftOwnershipData := ownership;
    };

    system func postupgrade() {
        founderManager.postupgrade(foundersData);
        projectManager.postupgrade(projectsData);
        investorManager.postupgrade(investorsData);
        investmentManager.postupgrade(investmentsData);
        nftManager.postupgrade(nftCollectionsData, nftTokensData, nftOwnershipData);
        foundersData := [];
        projectsData := [];
        investorsData := [];
        investmentsData := [];
        nftCollectionsData := [];
        nftTokensData := [];
        nftOwnershipData := [];
    };

    // =============================================================================
    // FOUNDER API FUNCTIONS
    // =============================================================================

    // Register new founder
    public shared (msg) func registerFounder(request : FounderRegistrationRequest) : async FounderRegistrationResult {
        founderManager.registerFounder(request, msg.caller);
    };

    // Get founder by ID
    public query func getFounder(founderId : Text) : async ?Founder {
        founderManager.getFounder(founderId);
    };

    // Get founder by email
    public query func getFounderByEmail(email : Text) : async ?Founder {
        founderManager.getFounderByEmail(email);
    };

    // Get founder by principal (current user)
    public shared (msg) func getMyFounderProfile() : async ?Founder {
        founderManager.getFounderByPrincipal(msg.caller);
    };

    // Update founder verification status (admin function)
    public shared (_msg) func updateFounderVerification(founderId : Text, isVerified : Bool) : async FounderUpdateResult {
        // TODO: Add admin authorization check
        founderManager.updateFounderVerification(founderId, isVerified);
    };

    // Update founder profile (only by the founder themselves)
    public shared (msg) func updateMyFounderProfile(founderId : Text, request : FounderRegistrationRequest) : async FounderUpdateResult {
        founderManager.updateFounderProfile(founderId, request, msg.caller);
    };

    // Get all founders (admin function)
    public query func getAllFounders() : async [Founder] {
        founderManager.getAllFounders();
    };

    // Get total number of registered founders
    public query func getFounderCount() : async Nat {
        founderManager.getFounderCount();
    };

    // Check if founder exists by email
    public query func founderExistsByEmail(email : Text) : async Bool {
        founderManager.founderExistsByEmail(email);
    };

    // =============================================================================
    // INVESTOR API FUNCTIONS
    // =============================================================================

    // Register new investor
    public shared (msg) func registerInvestor(request : InvestorRegistrationRequest) : async InvestorRegistrationResult {
        investorManager.registerInvestor(request, msg.caller);
    };

    // Get investor by ID
    public query func getInvestor(investorId : Text) : async ?Investor {
        investorManager.getInvestor(investorId);
    };

    // Get investor by email
    public query func getInvestorByEmail(email : Text) : async ?Investor {
        investorManager.getInvestorByEmail(email);
    };

    // Get investor by principal (current user)
    public shared (msg) func getMyInvestorProfile() : async ?Investor {
        investorManager.getInvestorByPrincipal(msg.caller);
    };

    // Update investor verification status (admin function)
    public shared (_msg) func updateInvestorVerification(investorId : Text, isVerified : Bool) : async InvestorUpdateResult {
        // TODO: Add admin authorization check
        investorManager.updateInvestorVerification(investorId, isVerified);
    };

    // Update investor profile (only by the investor themselves)
    public shared (msg) func updateMyInvestorProfile(investorId : Text, request : InvestorRegistrationRequest) : async InvestorUpdateResult {
        investorManager.updateInvestorProfile(investorId, request, msg.caller);
    };

    // Get all investors (admin function)
    public query func getAllInvestors() : async [Investor] {
        investorManager.getAllInvestors();
    };

    // Get total number of registered investors
    public query func getInvestorCount() : async Nat {
        investorManager.getInvestorCount();
    };

    // Check if investor exists by email
    public query func investorExistsByEmail(email : Text) : async Bool {
        investorManager.investorExistsByEmail(email);
    };

    // =============================================================================
    // PROJECT API FUNCTIONS
    // =============================================================================

    // Create new project
    public shared (msg) func createProject(request : ProjectCreateRequest) : async ProjectResult {
        // Get founder by principal
        switch (founderManager.getFounderByPrincipal(msg.caller)) {
            case null {
                #err("Founder not found. Please register as a founder first.");
            };
            case (?founder) {
                projectManager.createProject(request, founder.id, msg.caller);
            };
        };
    };

    // Get project by ID
    public query func getProject(projectId : Text) : async ?Project {
        projectManager.getProject(projectId);
    };

    // Get my projects (projects created by current user)
    public shared (msg) func getMyProjects() : async [Project] {
        projectManager.getProjectsByFounderPrincipal(msg.caller);
    };

    // Get projects by founder ID
    public query func getProjectsByFounder(founderId : Text) : async [Project] {
        projectManager.getProjectsByFounder(founderId);
    };

    // Update project (only by project owner)
    public shared (msg) func updateProject(projectId : Text, request : ProjectUpdateRequest) : async ProjectUpdateResult {
        projectManager.updateProject(projectId, request, msg.caller);
    };

    // Submit project for review
    public shared (msg) func submitProjectForReview(projectId : Text) : async ProjectUpdateResult {
        projectManager.submitProjectForReview(projectId, msg.caller);
    };

    // Update project status (admin function)
    public shared (_msg) func updateProjectStatus(projectId : Text, newStatus : ProjectStatus) : async ProjectUpdateResult {
        // TODO: Add admin authorization check
        projectManager.updateProjectStatus(projectId, newStatus);
    };

    // Delete project (only by project owner)
    public shared (msg) func deleteProject(projectId : Text) : async ProjectUpdateResult {
        projectManager.deleteProject(projectId, msg.caller);
    };

    // Get all projects (admin function)
    public query func getAllProjects() : async [Project] {
        projectManager.getAllProjects();
    };

    // Get projects by status
    public query func getProjectsByStatus(status : ProjectStatus) : async [Project] {
        projectManager.getProjectsByStatus(status);
    };

    // Get active projects (for marketplace)
    public query func getActiveProjects() : async [Project] {
        projectManager.getProjectsByStatus(#Active);
    };

    // Get total number of projects
    public query func getProjectCount() : async Nat {
        projectManager.getProjectCount();
    };

    // =============================================================================
    // NFT COLLECTION API FUNCTIONS
    // =============================================================================

    // Create NFT collection for a project (admin function)
    public shared (msg) func createNFTCollection(request : CreateCollectionRequest) : async CollectionResult {
        // TODO: Add admin authorization check
        let project = projectManager.getProject(request.projectId);
        nftManager.createCollection(request, project, msg.caller);
    };

    // Get NFT collection by ID
    public query func getNFTCollection(collectionId : Text) : async ?NFTCollection {
        nftManager.getCollection(collectionId);
    };

    // Get NFT collections by project
    public query func getNFTCollectionsByProject(projectId : Text) : async [NFTCollection] {
        nftManager.getCollectionsByProject(projectId);
    };

    // Get all active NFT collections
    public query func getActiveNFTCollections() : async [NFTCollection] {
        nftManager.getActiveCollections();
    };

    // =============================================================================
    // INVESTMENT API FUNCTIONS
    // =============================================================================

    // Purchase NFTs (investor function)
    public shared (msg) func purchaseNFTs(request : PurchaseRequest) : async PurchaseResult {
        // Get investor
        let investor = switch (investorManager.getInvestorByPrincipal(msg.caller)) {
            case null {
                return #err("Investor not found. Please register as an investor first.");
            };
            case (?inv) { inv };
        };

        // Get project
        let project = switch (projectManager.getProject(request.projectId)) {
            case null { return #err("Project not found") };
            case (?proj) { proj };
        };

        // Get founder
        let founder = switch (founderManager.getFounder(project.founderId)) {
            case null { return #err("Founder not found") };
            case (?f) { f };
        };

        // Get NFT collection
        let collection = switch (nftManager.getCollection(request.collectionId)) {
            case null { return #err("NFT collection not found") };
            case (?coll) { coll };
        };

        // Process the purchase
        await investmentManager.purchaseNFTs(request, investor, project, founder, collection, msg.caller);
    };

    // Get my investments
    public shared (msg) func getMyInvestments() : async [Investment] {
        investmentManager.getInvestmentsByInvestorPrincipal(msg.caller);
    };

    // Get investment summaries for my portfolio
    public shared (msg) func getMyInvestmentSummaries() : async [InvestmentSummary] {
        switch (investorManager.getInvestorByPrincipal(msg.caller)) {
            case null { [] };
            case (?investor) {
                let allProjects = projectManager.getAllProjects();
                investmentManager.getInvestmentSummariesForInvestor(investor.id, allProjects);
            };
        };
    };

    // Get investment by ID
    public query func getInvestment(investmentId : Text) : async ?Investment {
        investmentManager.getInvestment(investmentId);
    };

    // Get investments by project (founder function)
    public shared (msg) func getInvestmentsForMyProjects() : async [Investment] {
        switch (founderManager.getFounderByPrincipal(msg.caller)) {
            case null { [] };
            case (?founder) {
                investmentManager.getInvestmentsByFounder(founder.id);
            };
        };
    };

    // Get total funding raised for a project
    public query func getTotalFundingForProject(projectId : Text) : async Nat {
        investmentManager.getTotalFundingForProject(projectId);
    };

    // Get investor count for a project
    public query func getInvestorCountForProject(projectId : Text) : async Nat {
        investmentManager.getInvestorCountForProject(projectId);
    };

    // =============================================================================
    // ICP TRANSFER API FUNCTIONS
    // =============================================================================

    // Transfer ICP (for testing/admin purposes)
    public shared (_msg) func transferICP(request : ICPTransferRequest) : async TransferResult {
        // TODO: Add proper authorization check
        await icpTransferManager.transferICP(request);
    };

    // Simulate ICP transfer (for testing)
    public shared (_msg) func simulateICPTransfer(request : ICPTransferRequest) : async TransferResult {
        await icpTransferManager.simulateTransfer(request);
    };

    // Get ICP transfer fee
    public query func getICPTransferFee() : async Nat {
        icpTransferManager.getTransferFee();
    };

    // Get account balance
    public shared (msg) func getMyICPBalance() : async {
        #ok : Nat;
        #err : Text;
    } {
        switch (await icpTransferManager.getAccountBalance(msg.caller)) {
            case (#ok(balance)) { #ok(balance) };
            case (#err(error)) { #err(error) };
        };
    };

    // =============================================================================
    // STATISTICS AND ANALYTICS
    // =============================================================================

    // Get platform statistics
    public query func getPlatformStats() : async {
        totalFounders : Nat;
        totalInvestors : Nat;
        totalProjects : Nat;
        totalInvestments : Nat;
        totalFundingRaised : Nat;
        activeProjects : Nat;
    } {
        let investmentStats = investmentManager.getInvestmentStats();
        let activeProjects = projectManager.getProjectsByStatus(#Active);

        {
            totalFounders = founderManager.getFounderCount();
            totalInvestors = investorManager.getInvestorCount();
            totalProjects = projectManager.getProjectCount();
            totalInvestments = investmentStats.totalInvestments;
            totalFundingRaised = investmentStats.totalAmount;
            activeProjects = activeProjects.size();
        };
    };

    // Get NFT collection statistics
    public query func getNFTStats() : async NFTTypes.CollectionStats {
        nftManager.getCollectionStats();
    };

    // Health check
    public query func healthCheck() : async Text {
        "Plantify Backend is running! Founders: " # Nat.toText(founderManager.getFounderCount()) #
        ", Investors: " # Nat.toText(investorManager.getInvestorCount()) #
        ", Projects: " # Nat.toText(projectManager.getProjectCount()) #
        ", Investments: " # Nat.toText(investmentManager.getInvestmentStats().totalInvestments);
    };
};
