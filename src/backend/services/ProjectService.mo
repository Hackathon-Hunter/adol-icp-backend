import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import ProjectTypes "../types/ProjectTypes";
import ProjectValidation "../utils/ProjectValidation";
import ProjectStorage "../storage/ProjectStorage";

module ProjectService {

    type Project = ProjectTypes.Project;
    type ProjectCreateRequest = ProjectTypes.ProjectCreateRequest;
    type ProjectUpdateRequest = ProjectTypes.ProjectUpdateRequest;
    type ProjectResult = ProjectTypes.ProjectResult;
    type UpdateResult = ProjectTypes.UpdateResult;
    type ProjectStatus = ProjectTypes.ProjectStatus;
    type ProjectType = ProjectTypes.ProjectType;
    type Industry = ProjectTypes.Industry;

    public class ProjectManager() {

        private let storage = ProjectStorage.ProjectStore();

        // System functions for upgrades
        public func preupgrade() : [(Text, Project)] {
            storage.preupgrade();
        };

        public func postupgrade(entries : [(Text, Project)]) {
            storage.postupgrade(entries);
        };

        // Create new project with enhanced fields
        public func createProject(
            request : ProjectCreateRequest,
            founderId : Text,
            founderPrincipal : Principal,
        ) : ProjectResult {
            // Validate input
            switch (ProjectValidation.validateProjectCreateRequest(request)) {
                case (#err(error)) { return #err(error) };
                case (#ok(())) {};
            };

            // Create new project with all enhanced fields
            let projectId = storage.generateProjectId();
            let currentTime = Time.now();

            let newProject : Project = {
                // Basic Information
                id = projectId;
                founderId = founderId;
                founderPrincipal = founderPrincipal;

                // Company Information
                companyName = request.companyName;
                companyTagline = request.companyTagline;
                website = request.website;
                companyLogo = request.companyLogo;

                // Classification
                projectType = request.projectType;
                industry = request.industry;
                location = request.location;

                // Business Description
                problem = request.problem;
                solution = request.solution;
                marketOpportunity = request.marketOpportunity;

                // Financial Information
                fundingGoal = request.fundingGoal;
                companyValuation = request.companyValuation;
                minimumFunding = request.minimumFunding;
                fundingRaised = 0; // Start with 0 funding
                useOfFunds = request.useOfFunds;

                // Progress and Milestones
                milestones = request.milestones;

                // Team
                teamMembers = request.teamMembers;

                // Media and Documentation
                pitchDeckUrl = request.pitchDeckUrl;
                demoVideoUrl = request.demoVideoUrl;
                productImages = request.productImages;

                // Project Metadata
                status = #Draft;
                tags = request.tags;
                timeline = request.timeline;
                expectedROI = request.expectedROI;
                riskLevel = request.riskLevel;

                // Investment Information
                minInvestment = request.minInvestment;
                maxInvestment = request.maxInvestment;
                investorCount = 0; // Start with 0 investors

                // Timestamps
                createdAt = currentTime;
                updatedAt = currentTime;
                launchDate = null; // Will be set when project goes active
                targetDate = request.targetDate;

                // Legal and Compliance
                legalStructure = request.legalStructure;
                jurisdiction = request.jurisdiction;
            };

            // Store project
            storage.putProject(projectId, newProject);

            #ok(newProject);
        };

        // Update project with enhanced fields (only by owner)
        public func updateProject(
            projectId : Text,
            request : ProjectUpdateRequest,
            callerPrincipal : Principal,
        ) : UpdateResult {
            switch (storage.getProject(projectId)) {
                case null { #err("Project not found") };
                case (?project) {
                    // Check if caller is the project owner
                    if (project.founderPrincipal != callerPrincipal) {
                        return #err("Unauthorized: Can only update own projects");
                    };

                    // Only allow updates if project is in Draft status
                    if (project.status != #Draft) {
                        return #err("Can only update projects in Draft status");
                    };

                    // Validate update data
                    switch (ProjectValidation.validateProjectUpdateRequest(request)) {
                        case (#err(error)) { return #err(error) };
                        case (#ok(())) {};
                    };

                    let updatedProject : Project = {
                        // Basic Information (unchanged)
                        id = project.id;
                        founderId = project.founderId;
                        founderPrincipal = project.founderPrincipal;

                        // Company Information (updated)
                        companyName = request.companyName;
                        companyTagline = request.companyTagline;
                        website = request.website;
                        companyLogo = request.companyLogo;

                        // Classification (updated)
                        projectType = request.projectType;
                        industry = request.industry;
                        location = request.location;

                        // Business Description (updated)
                        problem = request.problem;
                        solution = request.solution;
                        marketOpportunity = request.marketOpportunity;

                        // Financial Information (updated)
                        fundingGoal = request.fundingGoal;
                        companyValuation = request.companyValuation;
                        minimumFunding = request.minimumFunding;
                        fundingRaised = project.fundingRaised; // Keep existing funding
                        useOfFunds = request.useOfFunds;

                        // Progress and Milestones (updated)
                        milestones = request.milestones;

                        // Team (updated)
                        teamMembers = request.teamMembers;

                        // Media and Documentation (updated)
                        pitchDeckUrl = request.pitchDeckUrl;
                        demoVideoUrl = request.demoVideoUrl;
                        productImages = request.productImages;

                        // Project Metadata (updated)
                        status = project.status; // Keep existing status
                        tags = request.tags;
                        timeline = request.timeline;
                        expectedROI = request.expectedROI;
                        riskLevel = request.riskLevel;

                        // Investment Information (updated)
                        minInvestment = request.minInvestment;
                        maxInvestment = request.maxInvestment;
                        investorCount = project.investorCount; // Keep existing count

                        // Timestamps (updated)
                        createdAt = project.createdAt;
                        updatedAt = Time.now();
                        launchDate = project.launchDate; // Keep existing launch date
                        targetDate = request.targetDate;

                        // Legal and Compliance (updated)
                        legalStructure = request.legalStructure;
                        jurisdiction = request.jurisdiction;
                    };

                    if (storage.updateProject(projectId, updatedProject)) {
                        #ok(());
                    } else {
                        #err("Failed to update project");
                    };
                };
            };
        };

        // Get project by ID
        public func getProject(projectId : Text) : ?Project {
            storage.getProject(projectId);
        };

        // Get projects by founder ID
        public func getProjectsByFounder(founderId : Text) : [Project] {
            storage.getProjectsByFounder(founderId);
        };

        // Get projects by founder principal
        public func getProjectsByFounderPrincipal(principal : Principal) : [Project] {
            storage.getProjectsByFounderPrincipal(principal);
        };

        // Get projects by industry
        public func getProjectsByIndustry(industry : Industry) : [Project] {
            let allProjects = storage.getAllProjects();
            let filteredProjects = Array.filter<Project>(
                allProjects,
                func(project : Project) : Bool {
                    project.industry == industry;
                },
            );
            filteredProjects;
        };

        // Submit project for review (change status from Draft to InReview)
        public func submitProjectForReview(projectId : Text, callerPrincipal : Principal) : UpdateResult {
            switch (storage.getProject(projectId)) {
                case null { #err("Project not found") };
                case (?project) {
                    // Check if caller is the project owner
                    if (project.founderPrincipal != callerPrincipal) {
                        return #err("Unauthorized: Can only submit own projects");
                    };

                    // Only allow submission if project is in Draft status
                    if (project.status != #Draft) {
                        return #err("Can only submit projects in Draft status");
                    };

                    let updatedProject : Project = {
                        id = project.id;
                        founderId = project.founderId;
                        founderPrincipal = project.founderPrincipal;
                        companyName = project.companyName;
                        companyTagline = project.companyTagline;
                        website = project.website;
                        companyLogo = project.companyLogo;
                        projectType = project.projectType;
                        industry = project.industry;
                        location = project.location;
                        problem = project.problem;
                        solution = project.solution;
                        marketOpportunity = project.marketOpportunity;
                        fundingGoal = project.fundingGoal;
                        companyValuation = project.companyValuation;
                        minimumFunding = project.minimumFunding;
                        fundingRaised = project.fundingRaised;
                        useOfFunds = project.useOfFunds;
                        milestones = project.milestones;
                        teamMembers = project.teamMembers;
                        pitchDeckUrl = project.pitchDeckUrl;
                        demoVideoUrl = project.demoVideoUrl;
                        productImages = project.productImages;
                        status = #InReview; // Change status
                        tags = project.tags;
                        timeline = project.timeline;
                        expectedROI = project.expectedROI;
                        riskLevel = project.riskLevel;
                        minInvestment = project.minInvestment;
                        maxInvestment = project.maxInvestment;
                        investorCount = project.investorCount;
                        createdAt = project.createdAt;
                        updatedAt = Time.now();
                        launchDate = project.launchDate;
                        targetDate = project.targetDate;
                        legalStructure = project.legalStructure;
                        jurisdiction = project.jurisdiction;
                    };

                    if (storage.updateProject(projectId, updatedProject)) {
                        #ok(());
                    } else {
                        #err("Failed to submit project for review");
                    };
                };
            };
        };

        // Launch project for funding (change status to Active and set launch date)
        public func launchProject(projectId : Text) : UpdateResult {
            switch (storage.getProject(projectId)) {
                case null { #err("Project not found") };
                case (?project) {
                    // Only allow launch if project is in InReview status
                    if (project.status != #InReview) {
                        return #err("Can only launch projects that are in review");
                    };

                    let updatedProject : Project = {
                        id = project.id;
                        founderId = project.founderId;
                        founderPrincipal = project.founderPrincipal;
                        companyName = project.companyName;
                        companyTagline = project.companyTagline;
                        website = project.website;
                        companyLogo = project.companyLogo;
                        projectType = project.projectType;
                        industry = project.industry;
                        location = project.location;
                        problem = project.problem;
                        solution = project.solution;
                        marketOpportunity = project.marketOpportunity;
                        fundingGoal = project.fundingGoal;
                        companyValuation = project.companyValuation;
                        minimumFunding = project.minimumFunding;
                        fundingRaised = project.fundingRaised;
                        useOfFunds = project.useOfFunds;
                        milestones = project.milestones;
                        teamMembers = project.teamMembers;
                        pitchDeckUrl = project.pitchDeckUrl;
                        demoVideoUrl = project.demoVideoUrl;
                        productImages = project.productImages;
                        status = #Active; // Change status
                        tags = project.tags;
                        timeline = project.timeline;
                        expectedROI = project.expectedROI;
                        riskLevel = project.riskLevel;
                        minInvestment = project.minInvestment;
                        maxInvestment = project.maxInvestment;
                        investorCount = project.investorCount;
                        createdAt = project.createdAt;
                        updatedAt = Time.now();
                        launchDate = ?Time.now(); // Set launch date
                        targetDate = project.targetDate;
                        legalStructure = project.legalStructure;
                        jurisdiction = project.jurisdiction;
                    };

                    if (storage.updateProject(projectId, updatedProject)) {
                        #ok(());
                    } else {
                        #err("Failed to launch project");
                    };
                };
            };
        };

        // Update project status (admin function)
        public func updateProjectStatus(projectId : Text, newStatus : ProjectStatus) : UpdateResult {
            switch (storage.getProject(projectId)) {
                case null { #err("Project not found") };
                case (?project) {
                    let currentTime = Time.now();
                    let launchDate = switch (newStatus) {
                        case (#Active) {
                            // Set launch date when project becomes active
                            if (project.launchDate == null) ?currentTime else project.launchDate;
                        };
                        case (_) { project.launchDate };
                    };

                    let updatedProject : Project = {
                        id = project.id;
                        founderId = project.founderId;
                        founderPrincipal = project.founderPrincipal;
                        companyName = project.companyName;
                        companyTagline = project.companyTagline;
                        website = project.website;
                        companyLogo = project.companyLogo;
                        projectType = project.projectType;
                        industry = project.industry;
                        location = project.location;
                        problem = project.problem;
                        solution = project.solution;
                        marketOpportunity = project.marketOpportunity;
                        fundingGoal = project.fundingGoal;
                        companyValuation = project.companyValuation;
                        minimumFunding = project.minimumFunding;
                        fundingRaised = project.fundingRaised;
                        useOfFunds = project.useOfFunds;
                        milestones = project.milestones;
                        teamMembers = project.teamMembers;
                        pitchDeckUrl = project.pitchDeckUrl;
                        demoVideoUrl = project.demoVideoUrl;
                        productImages = project.productImages;
                        status = newStatus; // Change status
                        tags = project.tags;
                        timeline = project.timeline;
                        expectedROI = project.expectedROI;
                        riskLevel = project.riskLevel;
                        minInvestment = project.minInvestment;
                        maxInvestment = project.maxInvestment;
                        investorCount = project.investorCount;
                        createdAt = project.createdAt;
                        updatedAt = currentTime;
                        launchDate = launchDate;
                        targetDate = project.targetDate;
                        legalStructure = project.legalStructure;
                        jurisdiction = project.jurisdiction;
                    };

                    if (storage.updateProject(projectId, updatedProject)) {
                        #ok(());
                    } else {
                        #err("Failed to update project status");
                    };
                };
            };
        };

        // Update project funding (when investment is made)
        public func updateProjectFunding(projectId : Text, investmentAmount : Nat) : UpdateResult {
            switch (storage.getProject(projectId)) {
                case null { #err("Project not found") };
                case (?project) {
                    // Can only invest in active projects
                    if (project.status != #Active) {
                        return #err("Can only invest in active projects");
                    };

                    let newFundingRaised = project.fundingRaised + investmentAmount;

                    // Check if funding goal is exceeded
                    if (newFundingRaised > project.fundingGoal) {
                        return #err("Investment would exceed funding goal");
                    };

                    // Determine new status based on funding
                    let newStatus = if (newFundingRaised >= project.fundingGoal) {
                        #Funded;
                    } else {
                        project.status;
                    };

                    let updatedProject : Project = {
                        id = project.id;
                        founderId = project.founderId;
                        founderPrincipal = project.founderPrincipal;
                        companyName = project.companyName;
                        companyTagline = project.companyTagline;
                        website = project.website;
                        companyLogo = project.companyLogo;
                        projectType = project.projectType;
                        industry = project.industry;
                        location = project.location;
                        problem = project.problem;
                        solution = project.solution;
                        marketOpportunity = project.marketOpportunity;
                        fundingGoal = project.fundingGoal;
                        companyValuation = project.companyValuation;
                        minimumFunding = project.minimumFunding;
                        fundingRaised = newFundingRaised; // Update funding
                        useOfFunds = project.useOfFunds;
                        milestones = project.milestones;
                        teamMembers = project.teamMembers;
                        pitchDeckUrl = project.pitchDeckUrl;
                        demoVideoUrl = project.demoVideoUrl;
                        productImages = project.productImages;
                        status = newStatus; // Update status if needed
                        tags = project.tags;
                        timeline = project.timeline;
                        expectedROI = project.expectedROI;
                        riskLevel = project.riskLevel;
                        minInvestment = project.minInvestment;
                        maxInvestment = project.maxInvestment;
                        investorCount = project.investorCount + 1; // Increment investor count
                        createdAt = project.createdAt;
                        updatedAt = Time.now();
                        launchDate = project.launchDate;
                        targetDate = project.targetDate;
                        legalStructure = project.legalStructure;
                        jurisdiction = project.jurisdiction;
                    };

                    if (storage.updateProject(projectId, updatedProject)) {
                        #ok(());
                    } else {
                        #err("Failed to update project funding");
                    };
                };
            };
        };

        // Get all projects (admin function)
        public func getAllProjects() : [Project] {
            storage.getAllProjects();
        };

        // Get projects by status
        public func getProjectsByStatus(status : ProjectStatus) : [Project] {
            storage.getProjectsByStatus(status);
        };

        // Get projects by type
        public func getProjectsByType(projectType : ProjectType) : [Project] {
            storage.getProjectsByType(projectType);
        };

        // Get project count
        public func getProjectCount() : Nat {
            storage.getProjectCount();
        };

        // Delete project (only by owner and only if in Draft status)
        public func deleteProject(projectId : Text, callerPrincipal : Principal) : UpdateResult {
            switch (storage.getProject(projectId)) {
                case null { #err("Project not found") };
                case (?project) {
                    // Check if caller is the project owner
                    if (project.founderPrincipal != callerPrincipal) {
                        return #err("Unauthorized: Can only delete own projects");
                    };

                    // Only allow deletion if project is in Draft status
                    if (project.status != #Draft) {
                        return #err("Can only delete projects in Draft status");
                    };

                    if (storage.deleteProject(projectId)) {
                        #ok(());
                    } else {
                        #err("Failed to delete project");
                    };
                };
            };
        };

        // Get projects with pagination
        public func getProjectsPaginated(offset : Nat, limit : Nat) : [Project] {
            storage.getProjectsPaginated(offset, limit);
        };

        // Search projects by tags
        public func searchProjectsByTags(searchTags : [Text]) : [Project] {
            storage.searchProjectsByTags(searchTags);
        };
    };
};
