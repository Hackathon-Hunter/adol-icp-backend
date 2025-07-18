import FounderTypes "./types/FounderTypes";
import FounderService "./services/FounderService";
import Nat "mo:base/Nat";

actor PlantifyBackend {

    type Founder = FounderTypes.Founder;
    type FounderRegistrationRequest = FounderTypes.FounderRegistrationRequest;
    type RegistrationResult = FounderTypes.RegistrationResult;
    type UpdateResult = FounderTypes.UpdateResult;

    // Initialize founder manager
    private let founderManager = FounderService.FounderManager();

    // Stable variables for upgrades
    private stable var foundersData : [(Text, Founder)] = [];

    // System functions for upgrades
    system func preupgrade() {
        foundersData := founderManager.preupgrade();
    };

    system func postupgrade() {
        founderManager.postupgrade(foundersData);
        foundersData := [];
    };

    // Public API Functions

    // Register new founder
    public shared (msg) func registerFounder(request : FounderRegistrationRequest) : async RegistrationResult {
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
    public shared (msg) func getMyProfile() : async ?Founder {
        founderManager.getFounderByPrincipal(msg.caller);
    };

    // Update founder verification status (admin function)
    public shared (msg) func updateFounderVerification(founderId : Text, isVerified : Bool) : async UpdateResult {
        // TODO: Add admin authorization check
        founderManager.updateFounderVerification(founderId, isVerified);
    };

    // Update founder profile (only by the founder themselves)
    public shared (msg) func updateMyProfile(founderId : Text, request : FounderRegistrationRequest) : async UpdateResult {
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

    // Health check
    public query func healthCheck() : async Text {
        "Plantify Backend is running! Founders registered: " # Nat.toText(founderManager.getFounderCount());
    };
};
