// src/plantify_backend/main.mo

import Result "mo:base/Result";

import FarmerTypes "types/FarmerTypes";
import FarmerStorage "storage/FarmerStorage";
import FarmerService "services/FarmerService";

import InvestmentTypes "types/InvestmentTypes";
import InvestmentStorage "storage/InvestmentStorage";
import InvestmentService "services/InvestmentService";

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

  // Initialize storage and services
  private let farmerStorage = FarmerStorage.FarmerStorage();
  private let investmentStorage = InvestmentStorage.InvestmentStorage();
  private let farmerService = FarmerService.FarmerService(farmerStorage);
  private let investmentService = InvestmentService.InvestmentService(investmentStorage, farmerStorage);

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
    "Plantify Backend is healthy! 🌱 Farmers and Investment Projects ready!";
  };

  // Get platform overview
  public query func getPlatformOverview() : async {
    farmers : FarmerTypes.FarmerStats;
    investments : InvestmentTypes.InvestmentStats;
  } {
    {
      farmers = farmerService.getFarmerStats();
      investments = investmentService.getInvestmentStats();
    };
  };
};
