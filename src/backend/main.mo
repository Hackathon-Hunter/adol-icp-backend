import FounderTypes "./types/FounderTypes";
import ProjectTypes "./types/ProjectTypes";
import FounderService "./services/FounderService";
import ProjectService "./services/ProjectService";
import Nat "mo:base/Nat";

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

    // Initialize managers
    private let founderManager = FounderService.FounderManager();
    private let projectManager = ProjectService.ProjectManager();

    // Stable variables for upgrades
    private stable var foundersData : [(Text, Founder)] = [];
    private stable var projectsData : [(Text, Project)] = [];

    // System functions for upgrades
    system func preupgrade() {
        foundersData := founderManager.preupgrade();
        projectsData := projectManager.preupgrade();
    };

    system func postupgrade() {
        founderManager.postupgrade(foundersData);
        projectManager.postupgrade(projectsData);
        foundersData := [];
        projectsData := [];
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
    public shared (msg) func getMyProfile() : async ?Founder {
        founderManager.getFounderByPrincipal(msg.caller);
    };

    // Update founder verification status (admin function)
    public shared (msg) func updateFounderVerification(founderId : Text, isVerified : Bool) : async FounderUpdateResult {
        // TODO: Add admin authorization check
        founderManager.updateFounderVerification(founderId, isVerified);
    };

    // Update founder profile (only by the founder themselves)
    public shared (msg) func updateMyProfile(founderId : Text, request : FounderRegistrationRequest) : async FounderUpdateResult {
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
    public shared (msg) func updateProjectStatus(projectId : Text, newStatus : ProjectStatus) : async ProjectUpdateResult {
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

    // Health check
    public query func healthCheck() : async Text {
        "Plantify Backend is running! Founders registered: " # Nat.toText(founderManager.getFounderCount());
    };
};
