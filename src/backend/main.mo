import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Float "mo:base/Float";

import FarmerTypes "types/FarmerTypes";
import FarmerStorage "storage/FarmerStorage";
import FarmerService "services/FarmerService";

import InvestorTypes "types/InvestorTypes";
import InvestorStorage "storage/InvestorStorage";
import InvestorService "services/InvestorService";

import InvestmentTypes "types/InvestmentTypes";
import InvestmentStorage "storage/InvestmentStorage";
import InvestmentService "services/InvestmentService";

import ICRC7Types "types/ICRC7Types";
import ICRC7Storage "storage/ICRC7Storage";
import ICRC7Service "services/ICRC7Service";

actor PlantifyBackend {

  // Stable storage for upgrades - Farmer data
  private stable var farmersStable : [(FarmerTypes.FarmerId, FarmerTypes.FarmerProfile)] = [];
  private stable var emailToFarmerStable : [(Text, FarmerTypes.FarmerId)] = [];
  private stable var governmentIdToFarmerStable : [(Text, FarmerTypes.FarmerId)] = [];

  // Stable storage for upgrades - Investor data
  private stable var investorsStable : [(InvestorTypes.InvestorId, InvestorTypes.InvestorProfile)] = [];
  private stable var emailToInvestorStable : [(Text, InvestorTypes.InvestorId)] = [];
  private stable var investorInvestmentsStable : [(InvestorTypes.InvestorId, [InvestorTypes.InvestorInvestment])] = [];

  // Stable storage for upgrades - Investment data
  private stable var investmentsStable : [(InvestmentTypes.InvestmentId, InvestmentTypes.InvestmentProject)] = [];
  private stable var farmerInvestmentsStable : [(InvestmentTypes.FarmerId, [InvestmentTypes.InvestmentId])] = [];
  private stable var verificationTrackersStable : [(InvestmentTypes.InvestmentId, InvestmentTypes.VerificationTracker)] = [];
  private stable var nextInvestmentIdStable : Nat = 1;

  // Stable storage for upgrades - ICRC-7 NFT data
  private stable var nftTokensStable : [(ICRC7Types.TokenId, ICRC7Types.Account)] = [];
  private stable var nftMetadataStable : [(ICRC7Types.TokenId, ICRC7Types.FarmNFTMetadata)] = [];
  private stable var nftOwnerTokensStable : [(Principal, [ICRC7Types.TokenId])] = [];
  private stable var nftApprovalsStable : [(ICRC7Types.TokenId, ICRC7Types.Account)] = [];
  private stable var nftCollectionsStable : [(Nat, ICRC7Types.NFTCollection)] = [];
  private stable var nextTokenIdStable : Nat = 1;

  // Initialize storage and services
  private let farmerStorage = FarmerStorage.FarmerStorage();
  private let investorStorage = InvestorStorage.InvestorStorage();
  private let investmentStorage = InvestmentStorage.InvestmentStorage();
  private let nftStorage = ICRC7Storage.ICRC7Storage();

  private let farmerService = FarmerService.FarmerService(farmerStorage);
  private let investorService = InvestorService.InvestorService(investorStorage);
  private let investmentService = InvestmentService.InvestmentService(investmentStorage, farmerStorage);
  private let nftService = ICRC7Service.ICRC7Service(nftStorage);

  // System functions for upgrades
  system func preupgrade() {
    // Farmer data
    farmersStable := farmerStorage.getEntries();
    emailToFarmerStable := farmerStorage.getEmailEntries();
    governmentIdToFarmerStable := farmerStorage.getGovernmentIdEntries();

    // Investor data
    investorsStable := investorStorage.getEntries();
    emailToInvestorStable := investorStorage.getEmailEntries();
    investorInvestmentsStable := investorStorage.getInvestmentEntries();

    // Investment data
    investmentsStable := investmentStorage.getInvestmentEntries();
    farmerInvestmentsStable := investmentStorage.getFarmerInvestmentEntries();
    verificationTrackersStable := investmentStorage.getVerificationTrackerEntries();
    nextInvestmentIdStable := investmentService.getNextInvestmentId();

    // NFT data
    nftTokensStable := nftStorage.getTokenEntries();
    nftMetadataStable := nftStorage.getMetadataEntries();
    nftOwnerTokensStable := nftStorage.getOwnerTokenEntries();
    nftApprovalsStable := nftStorage.getApprovalEntries();
    nftCollectionsStable := nftStorage.getNFTCollectionEntries();
    nextTokenIdStable := nftService.getNextTokenId();
  };

  system func postupgrade() {
    // Restore farmer data
    farmerStorage.initFromStable(farmersStable, emailToFarmerStable, governmentIdToFarmerStable);
    farmersStable := [];
    emailToFarmerStable := [];
    governmentIdToFarmerStable := [];

    // Restore investor data
    investorStorage.initFromStable(investorsStable, emailToInvestorStable, investorInvestmentsStable);
    investorsStable := [];
    emailToInvestorStable := [];
    investorInvestmentsStable := [];

    // Restore investment data
    investmentStorage.initFromStable(investmentsStable, farmerInvestmentsStable, verificationTrackersStable);
    investmentsStable := [];
    farmerInvestmentsStable := [];
    verificationTrackersStable := [];
    investmentService.setNextInvestmentId(nextInvestmentIdStable);

    // Restore NFT data
    nftStorage.initFromStable(nftTokensStable, nftMetadataStable, nftOwnerTokensStable, nftApprovalsStable, nftCollectionsStable);
    nftTokensStable := [];
    nftMetadataStable := [];
    nftOwnerTokensStable := [];
    nftApprovalsStable := [];
    nftCollectionsStable := [];
    nftService.setNextTokenId(nextTokenIdStable);
  };

  // ========== FARMER REGISTRATION FUNCTIONS ==========

  // Register a new farmer
  public shared (msg) func registerFarmer(
    request : FarmerTypes.RegisterFarmerRequest
  ) : async FarmerTypes.FarmerRegistrationResult {
    farmerService.registerFarmer(msg.caller, request);
  };

  // Upload documents (government ID, selfie, etc.)
  public shared (msg) func uploadDocument(
    request : FarmerTypes.UploadDocumentRequest
  ) : async Result.Result<(), Text> {
    farmerService.uploadDocument(msg.caller, request);
  };

  // Get farmer profile by ID
  public query func getFarmerProfile(farmerId : FarmerTypes.FarmerId) : async ?FarmerTypes.FarmerProfile {
    farmerStorage.getFarmer(farmerId);
  };

  // Get your own farmer profile
  public shared query (msg) func getMyFarmerProfile() : async ?FarmerTypes.FarmerProfile {
    farmerStorage.getFarmer(msg.caller);
  };

  // Update farmer profile
  public shared (msg) func updateFarmerProfile(
    fullName : ?Text,
    email : ?Text,
    phoneNumber : ?Text,
  ) : async Result.Result<(), Text> {
    farmerService.updateFarmerProfile(msg.caller, fullName, email, phoneNumber);
  };

  // Check if farmer is verified
  public query func isFarmerVerified(farmerId : FarmerTypes.FarmerId) : async Bool {
    farmerService.isFarmerVerified(farmerId);
  };

  // ========== INVESTOR REGISTRATION FUNCTIONS ==========

  // Register a new investor
  public shared (msg) func registerInvestor(
    request : InvestorTypes.RegisterInvestorRequest
  ) : async InvestorTypes.InvestorRegistrationResult {
    investorService.registerInvestor(msg.caller, request);
  };

  // Get investor profile by ID
  public query func getInvestorProfile(investorId : InvestorTypes.InvestorId) : async ?InvestorTypes.InvestorProfile {
    investorStorage.getInvestor(investorId);
  };

  // Get your own investor profile
  public shared query (msg) func getMyInvestorProfile() : async ?InvestorTypes.InvestorProfile {
    investorStorage.getInvestor(msg.caller);
  };

  // Update investor profile
  public shared (msg) func updateInvestorProfile(
    fullName : ?Text,
    email : ?Text,
  ) : async Result.Result<(), Text> {
    investorService.updateInvestorProfile(msg.caller, fullName, email);
  };

  // Get investor portfolio
  public shared query (msg) func getMyPortfolio() : async ?InvestorTypes.InvestorPortfolio {
    investorService.getInvestorPortfolio(msg.caller);
  };

  // Get investor portfolio by ID
  public query func getInvestorPortfolio(investorId : InvestorTypes.InvestorId) : async ?InvestorTypes.InvestorPortfolio {
    investorService.getInvestorPortfolio(investorId);
  };

  // Check if investor is active
  public query func isActiveInvestor(investorId : InvestorTypes.InvestorId) : async Bool {
    investorService.isActiveInvestor(investorId);
  };

  // Get top investors
  public query func getTopInvestors(limit : Nat) : async [InvestorTypes.InvestorProfile] {
    investorService.getTopInvestors(limit);
  };

  // ========== INVESTMENT SETUP FUNCTIONS ==========

  // Create new investment project (farmers only)
  public shared (msg) func createInvestmentProject(
    request : InvestmentTypes.CreateInvestmentRequest
  ) : async InvestmentTypes.InvestmentProjectResult {
    investmentService.createInvestment(msg.caller, request);
  };

  // Get investment project by ID
  public query func getInvestmentProject(investmentId : InvestmentTypes.InvestmentId) : async ?InvestmentTypes.InvestmentProject {
    investmentStorage.getInvestment(investmentId);
  };

  // Get all investment projects by farmer
  public shared query (msg) func getMyInvestmentProjects() : async [InvestmentTypes.InvestmentProject] {
    investmentService.getInvestmentsByFarmer(msg.caller);
  };

  // Get investment projects by farmer ID
  public query func getInvestmentProjectsByFarmer(farmerId : InvestmentTypes.FarmerId) : async [InvestmentTypes.InvestmentProject] {
    investmentService.getInvestmentsByFarmer(farmerId);
  };

  // Add document to existing investment project
  public shared (msg) func addInvestmentDocument(
    investmentId : InvestmentTypes.InvestmentId,
    document : InvestmentTypes.InvestmentDocument,
  ) : async Result.Result<(), Text> {
    investmentService.addDocument(msg.caller, investmentId, document);
  };

  // Get verification tracker for investment
  public query func getVerificationTracker(investmentId : InvestmentTypes.InvestmentId) : async ?InvestmentTypes.VerificationTracker {
    investmentService.getVerificationTracker(investmentId);
  };

  // Get investment projects by status
  public query func getInvestmentProjectsByStatus(status : InvestmentTypes.InvestmentStatus) : async [InvestmentTypes.InvestmentProject] {
    investmentService.getInvestmentsByStatus(status);
  };

  // Search investment projects
  public query func searchInvestmentProjects(
    cropType : ?InvestmentTypes.CropType,
    country : ?Text,
    minFunding : ?Nat,
    maxFunding : ?Nat,
    status : ?InvestmentTypes.InvestmentStatus,
  ) : async [InvestmentTypes.InvestmentProject] {
    investmentService.searchInvestments(cropType, country, minFunding, maxFunding, status);
  };

  // Get investment statistics
  public query func getInvestmentStats() : async InvestmentTypes.InvestmentStats {
    investmentService.getInvestmentStats();
  };

  // ========== ICRC-7 NFT FUNCTIONS ==========

  // Mint NFT for approved investment project (admin only)
  public shared (msg) func mintFarmNFT(
    investmentId : InvestmentTypes.InvestmentId,
    customSupply : ?Nat,
  ) : async ICRC7Types.MintResult {
    // Get investment project
    switch (investmentStorage.getInvestment(investmentId)) {
      case null {
        return #Err(#GenericError({ error_code = 404; message = "Investment project not found" }));
      };
      case (?investment) {
        nftService.mintFarmNFT(msg.caller, investment.farmerId, investment, customSupply);
      };
    };
  };

  // Transfer NFT
  public shared (msg) func icrc7_transfer(
    args : [ICRC7Types.TransferArg]
  ) : async [ICRC7Types.TransferResult] {
    // For simplicity, we'll handle single transfers
    if (args.size() == 0) {
      return [];
    };

    let arg = args[0];
    let toAccount : ICRC7Types.Account = arg.to;

    [nftService.transferNFT(msg.caller, arg.token_id, toAccount)];
  };

  // Get owner of token
  public query func icrc7_owner_of(
    token_ids : [ICRC7Types.TokenId]
  ) : async [?ICRC7Types.Account] {
    if (token_ids.size() == 0) {
      return [];
    };

    [nftService.ownerOf(token_ids[0])];
  };

  // Get balance of owner
  public query func icrc7_balance_of(
    accounts : [ICRC7Types.Account]
  ) : async [Nat] {
    if (accounts.size() == 0) {
      return [];
    };

    [nftService.balanceOf(accounts[0].owner)];
  };

  // Get tokens owned by user
  public query func icrc7_tokens_of(
    account : ICRC7Types.Account,
    prev : ?ICRC7Types.TokenId,
    take : ?Nat,
  ) : async [ICRC7Types.TokenId] {
    // For simplicity, we ignore pagination for now
    nftService.tokensOf(account.owner);
  };

  // Get token metadata
  public query func icrc7_token_metadata(
    token_ids : [ICRC7Types.TokenId]
  ) : async [?ICRC7Types.TokenMetadata] {
    if (token_ids.size() == 0) {
      return [];
    };

    [nftService.tokenMetadata(token_ids[0])];
  };

  // Get farm-specific metadata
  public query func getFarmNFTMetadata(
    tokenId : ICRC7Types.TokenId
  ) : async ?ICRC7Types.FarmNFTMetadata {
    nftService.getFarmMetadata(tokenId);
  };

  // Get total supply
  public query func icrc7_total_supply() : async Nat {
    nftService.totalSupply();
  };

  // Collection metadata
  public query func icrc7_name() : async Text {
    nftService.name();
  };

  public query func icrc7_symbol() : async Text {
    nftService.symbol();
  };

  public query func icrc7_description() : async ?Text {
    ?nftService.description();
  };

  public query func icrc7_logo() : async ?Text {
    nftService.logo();
  };

  public query func icrc7_supported_standards() : async [ICRC7Types.Standard] {
    nftService.supportedStandards();
  };

  // Get my NFTs
  public shared query (msg) func getMyNFTs() : async [ICRC7Types.TokenId] {
    nftService.tokensOf(msg.caller);
  };

  // Get NFTs by investment project
  public query func getNFTsByInvestment(
    investmentId : Nat
  ) : async [ICRC7Types.TokenId] {
    nftService.getTokensByInvestment(investmentId);
  };

  // Get NFTs by farmer
  public query func getNFTsByFarmer(
    farmerId : Principal
  ) : async [ICRC7Types.TokenId] {
    nftService.getTokensByFarmer(farmerId);
  };

  // Approve spender for NFT
  public shared (msg) func icrc7_approve(
    args : [ICRC7Types.ApprovalInfo]
  ) : async [ICRC7Types.ApprovalResult] {
    // For simplicity, we'll handle single approvals
    if (args.size() == 0) {
      return [];
    };

    let arg = args[0];
    // This is a simplified implementation - in a full ICRC-7 implementation,
    // you would need to handle the token_id properly
    // For now, we'll return a placeholder
    [#Err(#GenericError({ error_code = 501; message = "Approval not fully implemented in this demo" }))];
  };

  // ========== ENHANCED NFT PURCHASE FUNCTIONS ==========

  // Purchase NFT from available supply (enhanced with investor tracking)
  public shared (msg) func purchaseNFT(
    request : ICRC7Types.PurchaseNFTRequest
  ) : async ICRC7Types.PurchaseNFTResult {

    // Check if caller is a registered investor
    if (not investorService.isActiveInvestor(msg.caller)) {
      return #Error("You must be a registered investor to purchase NFTs. Please register as an investor first.");
    };

    // Process the NFT purchase
    let purchaseResult = nftService.purchaseNFT(msg.caller, request);

    // If purchase is successful, record the investment for the investor
    switch (purchaseResult) {
      case (#Success(details)) {
        // Record the investment in investor's portfolio
        let recordResult = investorService.recordInvestment(
          msg.caller,
          request.investmentId,
          details.tokenIds,
          details.totalPaid,
        );

        // If recording fails, log but don't fail the purchase
        switch (recordResult) {
          case (#err(error)) {
            // Log error but return successful purchase
            // In production, you might want to implement compensation logic
          };
          case (#ok()) {
            // Successfully recorded investment
          };
        };

        purchaseResult;
      };
      case (other) { other };
    };
  };

  // Get NFT collection information
  public query func getNFTCollection(
    investmentId : Nat
  ) : async ?ICRC7Types.NFTCollection {
    nftService.getNFTCollection(investmentId);
  };

  // Get all NFT collections
  public query func getAllNFTCollections() : async [ICRC7Types.NFTCollection] {
    nftService.getAllNFTCollections();
  };

  // Get pricing information for an investment
  public query func getPricingInfo(
    investmentId : Nat
  ) : async ?{
    nftPrice : Nat;
    totalSupply : Nat;
    availableSupply : Nat;
    soldSupply : Nat;
    fundingRequired : Nat;
    priceInICP : Float;
  } {
    nftService.getPricingInfo(investmentId);
  };

  // Calculate NFT price for investment
  public query func calculateNFTPrice(
    fundingRequiredUSD : Nat,
    totalSupply : Nat,
  ) : async Nat {
    nftService.calculateNFTPrice(fundingRequiredUSD, totalSupply);
  };

  // ========== ADMIN FUNCTIONS ==========

  // Update farmer verification status (admin only)
  public shared (msg) func updateFarmerVerificationStatus(
    farmerId : FarmerTypes.FarmerId,
    newStatus : FarmerTypes.VerificationStatus,
  ) : async Result.Result<(), Text> {
    // TODO: Add admin check
    // if (not isAdmin(msg.caller)) {
    //     return #err("Unauthorized: Only admins can update verification status");
    // };

    farmerService.updateVerificationStatus(farmerId, newStatus);
  };

  // Update investor status (admin only)
  public shared (msg) func updateInvestorStatus(
    investorId : InvestorTypes.InvestorId,
    newStatus : InvestorTypes.InvestorStatus,
  ) : async Result.Result<(), Text> {
    // TODO: Add admin check
    // if (not isAdmin(msg.caller)) {
    //     return #err("Unauthorized: Only admins can update investor status");
    // };

    investorService.updateInvestorStatus(investorId, newStatus);
  };

  // Update investment project status (admin only)
  public shared (msg) func updateInvestmentProjectStatus(
    investmentId : InvestmentTypes.InvestmentId,
    newStatus : InvestmentTypes.InvestmentStatus,
    notes : ?Text,
  ) : async Result.Result<(), Text> {
    // TODO: Add admin check
    // if (not isAdmin(msg.caller)) {
    //     return #err("Unauthorized: Only admins can update project status");
    // };

    investmentService.updateInvestmentStatus(investmentId, newStatus, notes);
  };

  // Approve investment and mint NFT (admin only)
  public shared (msg) func approveInvestmentAndMintNFT(
    investmentId : InvestmentTypes.InvestmentId,
    notes : ?Text,
    customSupply : ?Nat,
  ) : async Result.Result<ICRC7Types.TokenId, Text> {
    // TODO: Add admin check
    // if (not isAdmin(msg.caller)) {
    //     return #err("Unauthorized: Only admins can approve investments");
    // };

    // First, approve the investment
    switch (investmentService.updateInvestmentStatus(investmentId, #Approved, notes)) {
      case (#err(error)) {
        return #err(error);
      };
      case (#ok()) {
        // Then mint the NFT
        switch (investmentStorage.getInvestment(investmentId)) {
          case null {
            return #err("Investment project not found");
          };
          case (?investment) {
            switch (nftService.mintFarmNFT(msg.caller, investment.farmerId, investment, customSupply)) {
              case (#Ok(tokenId)) {
                #ok(tokenId);
              };
              case (#Err(mintError)) {
                // Try to revert investment status if NFT minting fails
                ignore investmentService.updateInvestmentStatus(investmentId, #PendingVerification, ?"NFT minting failed, reverted to pending");

                switch (mintError) {
                  case (#TokenIdAlreadyExists) {
                    #err("Token ID already exists");
                  };
                  case (#InvalidRecipient) { #err("Invalid recipient") };
                  case (#Unauthorized) { #err("Unauthorized to mint NFT") };
                  case (#GenericError(details)) { #err(details.message) };
                };
              };
            };
          };
        };
      };
    };
  };

  // Update NFT metadata (admin only)
  public shared (msg) func updateNFTMetadata(
    tokenId : ICRC7Types.TokenId,
    imageUrl : ?Text,
    projectStatus : ?Text,
  ) : async Result.Result<(), Text> {
    // TODO: Add admin check
    // if (not isAdmin(msg.caller)) {
    //     return #err("Unauthorized: Only admins can update NFT metadata");
    // };

    nftService.updateNFTMetadata(msg.caller, tokenId, imageUrl, projectStatus);
  };

  // Update investment value for portfolio tracking (admin only)
  public shared (msg) func updateInvestmentValue(
    investorId : InvestorTypes.InvestorId,
    investmentId : Nat,
    newValue : Nat,
  ) : async Result.Result<(), Text> {
    // TODO: Add admin check
    // if (not isAdmin(msg.caller)) {
    //     return #err("Unauthorized: Only admins can update investment values");
    // };

    investorService.updateInvestmentValue(investorId, investmentId, newValue);
  };

  // Get all farmers (admin only)
  public query func getAllFarmers() : async [FarmerTypes.FarmerProfile] {
    // TODO: Add admin check
    farmerStorage.getAllFarmers();
  };

  // Get all investors (admin only)
  public query func getAllInvestors() : async [InvestorTypes.InvestorProfile] {
    // TODO: Add admin check
    investorStorage.getAllInvestors();
  };

  // Get all investment projects (admin only)
  public query func getAllInvestmentProjects() : async [InvestmentTypes.InvestmentProject] {
    // TODO: Add admin check
    investmentStorage.getAllInvestments();
  };

  // Get all NFTs (admin only)
  public query func getAllNFTs() : async [ICRC7Types.TokenId] {
    // TODO: Add admin check
    nftService.getAllTokens();
  };

  // Get farmers by verification status
  public query func getFarmersByStatus(status : FarmerTypes.VerificationStatus) : async [FarmerTypes.FarmerProfile] {
    farmerService.getFarmersByStatus(status);
  };

  // Get investors by status
  public query func getInvestorsByStatus(status : InvestorTypes.InvestorStatus) : async [InvestorTypes.InvestorProfile] {
    investorService.getInvestorsByStatus(status);
  };

  // Get farmer registration statistics
  public query func getFarmerRegistrationStats() : async FarmerTypes.FarmerStats {
    farmerService.getFarmerStats();
  };

  // Get investor registration statistics
  public query func getInvestorRegistrationStats() : async InvestorTypes.InvestorStats {
    investorService.getInvestorStats();
  };

  // ========== UTILITY FUNCTIONS ==========

  // Health check
  public query func healthCheck() : async Text {
    "Plantify Backend is healthy! 🌱 Farmers, Investors, Investment Projects, and NFTs ready!";
  };

  // Get platform overview
  public query func getPlatformOverview() : async {
    farmers : FarmerTypes.FarmerStats;
    investors : InvestorTypes.InvestorStats;
    investments : InvestmentTypes.InvestmentStats;
    nfts : { totalSupply : Nat; totalCollections : Nat };
  } {
    {
      farmers = farmerService.getFarmerStats();
      investors = investorService.getInvestorStats();
      investments = investmentService.getInvestmentStats();
      nfts = {
        totalSupply = nftService.totalSupply();
        totalCollections = nftService.getAllNFTCollections().size();
      };
    };
  };

  // Get NFT statistics
  public query func getNFTStats() : async {
    totalSupply : Nat;
    totalCollections : Nat;
    averagePrice : Nat;
  } {
    let collections = nftService.getAllNFTCollections();
    let totalPrices = Array.foldLeft<ICRC7Types.NFTCollection, Nat>(
      collections,
      0,
      func(acc, collection) { acc + collection.nftPrice },
    );

    {
      totalSupply = nftService.totalSupply();
      totalCollections = collections.size();
      averagePrice = if (collections.size() > 0) {
        totalPrices / collections.size();
      } else { 0 };
    };
  };

  // Get platform metrics dashboard
  public query func getPlatformMetrics() : async {
    totalUsers : Nat;
    totalFarmers : Nat;
    totalInvestors : Nat;
    totalInvestmentProjects : Nat;
    totalInvestmentVolume : Nat;
    averageInvestmentSize : Nat;
    platformGrowthRate : Float;
  } {
    let farmerStats = farmerService.getFarmerStats();
    let investorStats = investorService.getInvestorStats();
    let investmentStats = investmentService.getInvestmentStats();

    {
      totalUsers = farmerStats.totalFarmers + investorStats.totalInvestors;
      totalFarmers = farmerStats.totalFarmers;
      totalInvestors = investorStats.totalInvestors;
      totalInvestmentProjects = investmentStats.totalProjects;
      totalInvestmentVolume = investorStats.totalInvestmentVolume;
      averageInvestmentSize = investorStats.averageInvestmentAmount;
      platformGrowthRate = 0.0; // TODO: Implement growth rate calculation
    };
  };

  // Check user registration status
  public shared query (msg) func getMyRegistrationStatus() : async {
    isFarmer : Bool;
    isInvestor : Bool;
    farmerStatus : ?FarmerTypes.VerificationStatus;
    investorStatus : ?InvestorTypes.InvestorStatus;
  } {
    let farmerProfile = farmerStorage.getFarmer(msg.caller);
    let investorProfile = investorStorage.getInvestor(msg.caller);

    {
      isFarmer = farmerProfile != null;
      isInvestor = investorProfile != null;
      farmerStatus = switch (farmerProfile) {
        case (?farmer) { ?farmer.verificationStatus };
        case null { null };
      };
      investorStatus = switch (investorProfile) {
        case (?investor) { ?investor.status };
        case null { null };
      };
    };
  };

  // Get marketplace overview for investors
  public query func getMarketplaceOverview() : async {
    activeProjects : Nat;
    totalInvestmentOpportunities : Nat;
    averageROI : Float;
    totalFundingAvailable : Nat;
    topPerformingCrops : [Text];
  } {
    let activeProjects = investmentService.getInvestmentsByStatus(#Active);
    let approvedProjects = investmentService.getInvestmentsByStatus(#Approved);
    let allCollections = nftService.getAllNFTCollections();

    let totalFundingAvailable = Array.foldLeft<ICRC7Types.NFTCollection, Nat>(
      allCollections,
      0,
      func(acc, collection) {
        acc + (collection.nftPrice * collection.availableSupply);
      },
    );

    {
      activeProjects = activeProjects.size();
      totalInvestmentOpportunities = approvedProjects.size();
      averageROI = 18.5; // TODO: Calculate from real data
      totalFundingAvailable = totalFundingAvailable;
      topPerformingCrops = ["Rice", "Coffee", "Apple"]; // TODO: Calculate from real data
    };
  };

  // Get user dashboard data
  public shared query (msg) func getMyDashboardData() : async {
    userType : Text;
    farmerData : ?{
      totalProjects : Nat;
      activeProjects : Nat;
      totalFundingRaised : Nat;
      verificationStatus : FarmerTypes.VerificationStatus;
    };
    investorData : ?{
      totalInvestments : Nat;
      portfolioValue : Nat;
      totalReturns : Nat;
      roiPercentage : Float;
    };
  } {
    let farmerProfile = farmerStorage.getFarmer(msg.caller);
    let investorProfile = investorStorage.getInvestor(msg.caller);

    let userType = if (farmerProfile != null and investorProfile != null) {
      "Both";
    } else if (farmerProfile != null) {
      "Farmer";
    } else if (investorProfile != null) {
      "Investor";
    } else {
      "Unregistered";
    };

    let farmerData = switch (farmerProfile) {
      case (?farmer) {
        let myProjects = investmentService.getInvestmentsByFarmer(msg.caller);
        let activeProjects = Array.filter(
          myProjects,
          func(project : InvestmentTypes.InvestmentProject) : Bool {
            project.status == #Active;
          },
        );

        let totalFunding = Array.foldLeft<InvestmentTypes.InvestmentProject, Nat>(
          myProjects,
          0,
          func(acc, project) { acc + project.farmInfo.fundingRequired },
        );

        ?{
          totalProjects = myProjects.size();
          activeProjects = activeProjects.size();
          totalFundingRaised = totalFunding;
          verificationStatus = farmer.verificationStatus;
        };
      };
      case null { null };
    };

    let investorData = switch (investorService.getInvestorPortfolio(msg.caller)) {
      case (?portfolio) {
        ?{
          totalInvestments = portfolio.investments.size();
          portfolioValue = portfolio.totalValue;
          totalReturns = portfolio.totalReturns;
          roiPercentage = portfolio.roiPercentage;
        };
      };
      case null { null };
    };

    {
      userType = userType;
      farmerData = farmerData;
      investorData = investorData;
    };
  };

  // Get investment opportunities for investors
  public query func getInvestmentOpportunities() : async [InvestmentTypes.InvestmentProject] {
    investmentService.getInvestmentsByStatus(#Approved);
  };

  // Get recent investments activity
  public query func getRecentInvestmentActivity(limit : Nat) : async [InvestmentTypes.InvestmentProject] {
    investmentService.getRecentInvestments(limit);
  };

  // Bulk investor registration status check
  public query func checkInvestorRegistration(principalIds : [Principal]) : async [(Principal, Bool)] {
    Array.map<Principal, (Principal, Bool)>(
      principalIds,
      func(id) { (id, investorService.isActiveInvestor(id)) },
    );
  };

  // Get investment project summary for marketplace
  public query func getInvestmentProjectSummary(investmentId : InvestmentTypes.InvestmentId) : async ?{
    project : InvestmentTypes.InvestmentProject;
    nftCollection : ?ICRC7Types.NFTCollection;
    pricing : ?{
      nftPrice : Nat;
      totalSupply : Nat;
      availableSupply : Nat;
      soldSupply : Nat;
      fundingRequired : Nat;
      priceInICP : Float;
    };
  } {
    switch (investmentStorage.getInvestment(investmentId)) {
      case null { null };
      case (?project) {
        let collection = nftService.getNFTCollection(investmentId);
        let pricing = nftService.getPricingInfo(investmentId);

        ?{
          project = project;
          nftCollection = collection;
          pricing = pricing;
        };
      };
    };
  };

  // Enhanced portfolio tracking
  public shared query (msg) func getDetailedPortfolio() : async ?{
    investor : InvestorTypes.InvestorProfile;
    investments : [{
      investment : InvestorTypes.InvestorInvestment;
      project : ?InvestmentTypes.InvestmentProject;
      nftTokens : [ICRC7Types.TokenId];
      currentMarketValue : Nat;
      roiPercentage : Float;
    }];
    summary : {
      totalValue : Nat;
      totalReturns : Nat;
      overallROI : Float;
      bestPerforming : ?Nat;
      worstPerforming : ?Nat;
    };
  } {
    switch (investorStorage.getInvestor(msg.caller)) {
      case null { null };
      case (?investor) {
        let investments = investorStorage.getInvestorInvestments(msg.caller);

        let detailedInvestments = Array.map<InvestorTypes.InvestorInvestment, { investment : InvestorTypes.InvestorInvestment; project : ?InvestmentTypes.InvestmentProject; nftTokens : [ICRC7Types.TokenId]; currentMarketValue : Nat; roiPercentage : Float }>(
          investments,
          func(inv) {
            let project = investmentStorage.getInvestment(inv.investmentId);
            let nftTokens = inv.nftTokenIds;
            let currentValue = inv.currentValue;
            let roi = if (inv.investmentAmount > 0) {
              ((Float.fromInt(currentValue) - Float.fromInt(inv.investmentAmount)) / Float.fromInt(inv.investmentAmount)) * 100.0;
            } else { 0.0 };

            {
              investment = inv;
              project = project;
              nftTokens = nftTokens;
              currentMarketValue = currentValue;
              roiPercentage = roi;
            };
          },
        );

        let totalValue = Array.foldLeft<InvestorTypes.InvestorInvestment, Nat>(
          investments,
          0,
          func(acc, inv) { acc + inv.currentValue },
        );

        let totalInvested = Array.foldLeft<InvestorTypes.InvestorInvestment, Nat>(
          investments,
          0,
          func(acc, inv) { acc + inv.investmentAmount },
        );

        let totalReturns = if (totalValue > totalInvested) {
          totalValue - totalInvested;
        } else { 0 };

        let overallROI = if (totalInvested > 0) {
          (Float.fromInt(totalReturns) / Float.fromInt(totalInvested)) * 100.0;
        } else { 0.0 };

        ?{
          investor = investor;
          investments = detailedInvestments;
          summary = {
            totalValue = totalValue;
            totalReturns = totalReturns;
            overallROI = overallROI;
            bestPerforming = null; // TODO: Calculate best performing investment
            worstPerforming = null; // TODO: Calculate worst performing investment
          };
        };
      };
    };
  };

  // Get platform statistics for admin dashboard
  public query func getAdminDashboardStats() : async {
    users : {
      farmers : FarmerTypes.FarmerStats;
      investors : InvestorTypes.InvestorStats;
    };
    projects : InvestmentTypes.InvestmentStats;
    nfts : {
      totalSupply : Nat;
      totalCollections : Nat;
      averagePrice : Nat;
      totalVolume : Nat;
    };
    financial : {
      totalInvestmentVolume : Nat;
      platformRevenue : Nat;
      averageInvestmentSize : Nat;
    };
  } {
    let farmerStats = farmerService.getFarmerStats();
    let investorStats = investorService.getInvestorStats();
    let investmentStats = investmentService.getInvestmentStats();

    // Calculate NFT stats inline instead of calling getNFTStats()
    let collections = nftService.getAllNFTCollections();
    let totalPrices = Array.foldLeft<ICRC7Types.NFTCollection, Nat>(
      collections,
      0,
      func(acc, collection) { acc + collection.nftPrice },
    );

    let nftStats = {
      totalSupply = nftService.totalSupply();
      totalCollections = collections.size();
      averagePrice = if (collections.size() > 0) {
        totalPrices / collections.size();
      } else { 0 };
    };

    {
      users = {
        farmers = farmerStats;
        investors = investorStats;
      };
      projects = investmentStats;
      nfts = {
        totalSupply = nftStats.totalSupply;
        totalCollections = nftStats.totalCollections;
        averagePrice = nftStats.averagePrice;
        totalVolume = investorStats.totalInvestmentVolume;
      };
      financial = {
        totalInvestmentVolume = investorStats.totalInvestmentVolume;
        platformRevenue = investorStats.totalInvestmentVolume / 10; // Assuming 10% platform fee
        averageInvestmentSize = investorStats.averageInvestmentAmount;
      };
    };
  };
};
