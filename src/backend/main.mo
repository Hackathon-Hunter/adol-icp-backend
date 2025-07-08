// src/plantify_backend/main.mo

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Array "mo:base/Array";

import FarmerTypes "types/FarmerTypes";
import FarmerStorage "storage/FarmerStorage";
import FarmerService "services/FarmerService";

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
  private let investmentStorage = InvestmentStorage.InvestmentStorage();
  private let nftStorage = ICRC7Storage.ICRC7Storage();

  private let farmerService = FarmerService.FarmerService(farmerStorage);
  private let investmentService = InvestmentService.InvestmentService(investmentStorage, farmerStorage);
  private let nftService = ICRC7Service.ICRC7Service(nftStorage);

  // System functions for upgrades
  system func preupgrade() {
    // Farmer data
    farmersStable := farmerStorage.getEntries();
    emailToFarmerStable := farmerStorage.getEmailEntries();
    governmentIdToFarmerStable := farmerStorage.getGovernmentIdEntries();

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

  // Purchase NFT from available supply
  public shared (msg) func purchaseNFT(
    request : ICRC7Types.PurchaseNFTRequest
  ) : async ICRC7Types.PurchaseNFTResult {
    nftService.purchaseNFT(msg.caller, request);
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

  // Get all farmers (admin only)
  public query func getAllFarmers() : async [FarmerTypes.FarmerProfile] {
    // TODO: Add admin check
    farmerStorage.getAllFarmers();
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

  // Get farmer registration statistics
  public query func getFarmerRegistrationStats() : async FarmerTypes.FarmerStats {
    farmerService.getFarmerStats();
  };

  // ========== UTILITY FUNCTIONS ==========

  // Health check
  public query func healthCheck() : async Text {
    "Plantify Backend is healthy! 🌱 Farmers, Investment Projects, and NFTs ready!";
  };

  // Get platform overview
  public query func getPlatformOverview() : async {
    farmers : FarmerTypes.FarmerStats;
    investments : InvestmentTypes.InvestmentStats;
    nfts : { totalSupply : Nat; totalCollections : Nat };
  } {
    {
      farmers = farmerService.getFarmerStats();
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
};
