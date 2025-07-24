import Principal "mo:base/Principal";
import Result "mo:base/Result";

module ProjectTypes {

    // Enhanced project type enum - more comprehensive categories
    public type ProjectType = {
        #Technology; // Software, hardware, AI, blockchain
        #Healthcare; // Biotech, medical devices, digital health
        #Finance; // Fintech, payments, investing
        #Education; // Edtech, learning platforms, training
        #Entertainment; // Gaming, media, streaming, content
        #Commerce; // E-commerce, retail, marketplaces
        #Food; // Food tech, restaurants, delivery
        #Transportation; // Mobility, logistics, automotive
        #RealEstate; // Proptech, construction, housing
        #Energy; // Clean energy, utilities, sustainability
        #Agriculture; // Agtech, farming, food production
        #Manufacturing; // Hardware, industrial, 3D printing
        #Services; // Professional services, consulting
        #SocialImpact; // Non-profit, social enterprises
        #Consumer; // Consumer products, lifestyle
        #B2B; // Business software, enterprise tools
        #Other;
    };

    // Industry subcategories for more specific classification
    public type Industry = {
        // Technology
        #SoftwareDevelopment;
        #ArtificialIntelligence;
        #Blockchain;
        #Cybersecurity;
        #CloudComputing;
        #MobileApps;
        #WebDevelopment;

        // Healthcare
        #Biotechnology;
        #MedicalDevices;
        #DigitalHealth;
        #Pharmaceuticals;
        #HealthcareServices;
        #Telemedicine;

        // Finance
        #Fintech;
        #Payments;
        #Cryptocurrency;
        #Insurance;
        #Banking;
        #InvestmentPlatforms;

        // Education
        #OnlineLearning;
        #EducationTechnology;
        #SkillTraining;
        #LanguageLearning;
        #CorporateTraining;

        // Entertainment
        #Gaming;
        #StreamingMedia;
        #ContentCreation;
        #SocialMedia;
        #VirtualReality;

        // Commerce
        #ECommerce;
        #Marketplace;
        #RetailTechnology;
        #SupplyChain;
        #Logistics;

        // Food
        #FoodTechnology;
        #RestaurantTech;
        #FoodDelivery;
        #Agriculture;
        #NutritionTech;

        // Transportation
        #Mobility;
        #ElectricVehicles;
        #AutonomousVehicles;
        #PublicTransport;
        #DeliveryServices;

        // Real Estate
        #PropertyTechnology;
        #Construction;
        #SmartHomes;
        #RealEstateServices;

        // Energy
        #RenewableEnergy;
        #EnergyStorage;
        #SmartGrid;
        #CleanTech;
        #Sustainability;

        // Other
        #Other;
    };

    // Team member information
    public type TeamMember = {
        name : Text;
        role : Text;
        bio : ?Text;
        linkedinUrl : ?Text;
        imageUrl : ?Text;
    };

    // Use of funds breakdown
    public type UseOfFunds = {
        category : Text; // e.g., "Marketing", "Development", "Operations"
        amount : Nat; // Amount in USD cents
        percentage : Float; // Percentage of total funding
        description : Text; // Brief description of usage
    };

    // Milestone information
    public type Milestone = {
        title : Text;
        description : Text;
        targetDate : ?Int; // Target completion date
        fundingRequired : Nat; // Funding required to reach this milestone
        completed : Bool;
        completedDate : ?Int;
    };

    // Project status enum
    public type ProjectStatus = {
        #Draft;
        #InReview;
        #Active;
        #Funded;
        #InProgress;
        #Completed;
        #Rejected;
        #Cancelled;
        #Suspended;
    };

    // Enhanced project data structure
    public type Project = {
        // Basic Information
        id : Text;
        founderId : Text;
        founderPrincipal : Principal;

        // Company Information
        companyName : Text;
        companyTagline : Text;
        website : ?Text;
        companyLogo : ?Text; // URL to company logo

        // Classification
        projectType : ProjectType;
        industry : Industry;
        location : Text;

        // Business Description
        problem : Text; // The problem being solved
        solution : Text; // The proposed solution
        marketOpportunity : Text; // Market size and opportunity

        // Financial Information
        fundingGoal : Nat; // Target funding in USD cents
        companyValuation : Nat; // Pre-money valuation in USD cents
        minimumFunding : Nat; // Minimum viable funding in USD cents
        fundingRaised : Nat; // Amount raised so far
        useOfFunds : [UseOfFunds]; // Detailed breakdown of fund usage

        // Progress and Milestones
        milestones : [Milestone]; // Key milestones and progress

        // Team
        teamMembers : [TeamMember]; // Founding team and key employees

        // Media and Documentation
        pitchDeckUrl : ?Text; // URL to pitch deck
        demoVideoUrl : ?Text; // URL to demo video
        productImages : [Text]; // URLs to product images

        // Project Metadata
        status : ProjectStatus;
        tags : [Text]; // Searchable tags
        timeline : Text; // Expected timeline to completion
        expectedROI : Text; // Expected return on investment
        riskLevel : Text; // Low, Medium, High

        // Investment Information
        minInvestment : Nat; // Minimum investment amount in cents
        maxInvestment : ?Nat; // Optional maximum investment per investor
        investorCount : Nat; // Number of current investors

        // Timestamps
        createdAt : Int;
        updatedAt : Int;
        launchDate : ?Int; // When project goes live for funding
        targetDate : ?Int; // Expected completion date

        // Legal and Compliance
        legalStructure : ?Text; // Legal entity type
        jurisdiction : ?Text; // Legal jurisdiction
    };

    // Enhanced project creation request
    public type ProjectCreateRequest = {
        // Company Information
        companyName : Text;
        companyTagline : Text;
        website : ?Text;
        companyLogo : ?Text;

        // Classification
        projectType : ProjectType;
        industry : Industry;
        location : Text;

        // Business Description
        problem : Text;
        solution : Text;
        marketOpportunity : Text;

        // Financial Information
        fundingGoal : Nat;
        companyValuation : Nat;
        minimumFunding : Nat;
        useOfFunds : [UseOfFunds];

        // Progress and Milestones
        milestones : [Milestone];

        // Team
        teamMembers : [TeamMember];

        // Media and Documentation
        pitchDeckUrl : ?Text;
        demoVideoUrl : ?Text;
        productImages : [Text];

        // Project Metadata
        tags : [Text];
        timeline : Text;
        expectedROI : Text;
        riskLevel : Text;

        // Investment Information
        minInvestment : Nat;
        maxInvestment : ?Nat;
        targetDate : ?Int;

        // Legal and Compliance
        legalStructure : ?Text;
        jurisdiction : ?Text;
    };

    // Enhanced project update request
    public type ProjectUpdateRequest = {
        // Company Information
        companyName : Text;
        companyTagline : Text;
        website : ?Text;
        companyLogo : ?Text;

        // Classification
        projectType : ProjectType;
        industry : Industry;
        location : Text;

        // Business Description
        problem : Text;
        solution : Text;
        marketOpportunity : Text;

        // Financial Information
        fundingGoal : Nat;
        companyValuation : Nat;
        minimumFunding : Nat;
        useOfFunds : [UseOfFunds];

        // Progress and Milestones
        milestones : [Milestone];

        // Team
        teamMembers : [TeamMember];

        // Media and Documentation
        pitchDeckUrl : ?Text;
        demoVideoUrl : ?Text;
        productImages : [Text];

        // Project Metadata
        tags : [Text];
        timeline : Text;
        expectedROI : Text;
        riskLevel : Text;

        // Investment Information
        minInvestment : Nat;
        maxInvestment : ?Nat;
        targetDate : ?Int;

        // Legal and Compliance
        legalStructure : ?Text;
        jurisdiction : ?Text;
    };

    // Project summary for listings (lighter version)
    public type ProjectSummary = {
        id : Text;
        companyName : Text;
        companyTagline : Text;
        companyLogo : ?Text;
        projectType : ProjectType;
        industry : Industry;
        location : Text;
        fundingGoal : Nat;
        fundingRaised : Nat;
        fundingPercentage : Nat;
        companyValuation : Nat;
        expectedROI : Text;
        riskLevel : Text;
        status : ProjectStatus;
        investorCount : Nat;
        tags : [Text];
        createdAt : Int;
        teamSize : Nat; // Number of team members
        milestonesCompleted : Nat; // Number of completed milestones
        totalMilestones : Nat; // Total number of milestones
    };

    // Investment-related types
    public type Investment = {
        id : Text;
        projectId : Text;
        investorPrincipal : Principal;
        amount : Nat; // in cents
        investmentDate : Int;
        status : InvestmentStatus;
    };

    public type InvestmentStatus = {
        #Pending;
        #Confirmed;
        #Cancelled;
        #Refunded;
    };

    // Response types
    public type ProjectResult = Result.Result<Project, Text>;
    public type ProjectSummaryResult = Result.Result<ProjectSummary, Text>;
    public type UpdateResult = Result.Result<(), Text>;
    public type ValidationResult = Result.Result<(), Text>;
    public type InvestmentResult = Result.Result<Investment, Text>;

    // Filter and query types
    public type ProjectFilter = {
        projectType : ?ProjectType;
        industry : ?Industry;
        status : ?ProjectStatus;
        minFunding : ?Nat;
        maxFunding : ?Nat;
        minValuation : ?Nat;
        maxValuation : ?Nat;
        riskLevel : ?Text;
        location : ?Text;
        tags : ?[Text];
    };

    public type ProjectSort = {
        #CreatedAt;
        #FundingGoal;
        #FundingRaised;
        #CompanyValuation;
        #ExpectedROI;
        #InvestorCount;
        #CompanyName;
        #FundingProgress;
    };

    public type SortDirection = {
        #Asc;
        #Desc;
    };

    // Error types
    public type ProjectError = {
        #NotFound;
        #Unauthorized;
        #ValidationFailed : Text;
        #FounderNotFound;
        #InvalidStatus;
        #FundingLimitExceeded;
        #MinInvestmentNotMet;
        #MaxInvestmentExceeded;
        #ProjectNotActive;
        #InsufficientFunding;
        #InvalidValuation;
        #MilestoneError : Text;
        #TeamMemberError : Text;
        #UseOfFundsError : Text;
    };

    // Statistics type
    public type ProjectStats = {
        totalProjects : Nat;
        projectsByType : [(ProjectType, Nat)];
        projectsByIndustry : [(Industry, Nat)];
        projectsByStatus : [(ProjectStatus, Nat)];
        totalFundingGoal : Nat;
        totalFundingRaised : Nat;
        averageFundingGoal : Nat;
        averageValuation : Nat;
        totalInvestors : Nat;
        successRate : Float; // Percentage of successfully funded projects
        averageTimeToFunding : ?Nat; // Average days to reach funding goal
    };

    // Helper types for marketplace features
    public type TrendingProject = {
        project : ProjectSummary;
        trendingScore : Float; // Based on recent activity, funding velocity, etc.
        recentInvestments : Nat; // Number of investments in last 7 days
        momentum : Text; // "Hot", "Rising", "Steady"
    };

    public type FeaturedProject = {
        project : ProjectSummary;
        featuredReason : Text; // Why this project is featured
        featuredUntil : Int; // When featuring expires
    };
};
