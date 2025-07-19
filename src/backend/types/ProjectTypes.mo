import Principal "mo:base/Principal";
import Result "mo:base/Result";

module ProjectTypes {

    // Project type enum - for different categories of projects
    public type ProjectType = {
        #Agriculture;
        #Technology;
        #Healthcare;
        #Education;
        #Environment;
        #Energy;
        #Finance;
        #RealEstate;
        #Manufacturing;
        #Services;
        #Other;
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
    };

    // Project data structure - generalized for any type of project
    public type Project = {
        id : Text;
        founderId : Text;
        founderPrincipal : Principal;
        projectType : ProjectType;
        title : Text;
        description : Text;
        category : Text; // More specific category within the project type
        location : Text;
        fundingGoal : Nat; // in ICP (e.g., 500000 = $5000)
        fundingRaised : Nat; // amount raised so far
        timeline : Text; // e.g., "8 months", "2 years"
        expectedROI : Text; // e.g., "18%", "3x returns"
        riskLevel : Text; // e.g., "Low", "Medium", "High"
        status : ProjectStatus;
        tags : [Text]; // searchable tags
        minInvestment : Nat; // minimum investment amount in cents
        maxInvestment : ?Nat; // optional maximum investment per investor
        investorCount : Nat; // number of current investors
        createdAt : Int;
        updatedAt : Int;
        launchDate : ?Int; // when project goes live for funding
        targetDate : ?Int; // expected completion date
    };

    // Project creation request
    public type ProjectCreateRequest = {
        projectType : ProjectType;
        title : Text;
        description : Text;
        category : Text;
        location : Text;
        fundingGoal : Nat;
        timeline : Text;
        expectedROI : Text;
        riskLevel : Text;
        tags : [Text];
        minInvestment : Nat;
        maxInvestment : ?Nat;
        targetDate : ?Int;
    };

    // Project update request
    public type ProjectUpdateRequest = {
        projectType : ProjectType;
        title : Text;
        description : Text;
        category : Text;
        location : Text;
        fundingGoal : Nat;
        timeline : Text;
        expectedROI : Text;
        riskLevel : Text;
        tags : [Text];
        minInvestment : Nat;
        maxInvestment : ?Nat;
        targetDate : ?Int;
    };

    // Project summary for listings (lighter version)
    public type ProjectSummary = {
        id : Text;
        projectType : ProjectType;
        title : Text;
        category : Text;
        location : Text;
        fundingGoal : Nat;
        fundingRaised : Nat;
        fundingPercentage : Nat; // calculated percentage
        expectedROI : Text;
        riskLevel : Text;
        status : ProjectStatus;
        investorCount : Nat;
        tags : [Text];
        createdAt : Int;
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
        status : ?ProjectStatus;
        minFunding : ?Nat;
        maxFunding : ?Nat;
        riskLevel : ?Text;
        location : ?Text;
        tags : ?[Text];
    };

    public type ProjectSort = {
        #CreatedAt;
        #FundingGoal;
        #FundingRaised;
        #ExpectedROI;
        #InvestorCount;
        #Title;
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
    };

    // Statistics type
    public type ProjectStats = {
        totalProjects : Nat;
        projectsByType : [(ProjectType, Nat)];
        projectsByStatus : [(ProjectStatus, Nat)];
        totalFundingGoal : Nat;
        totalFundingRaised : Nat;
        averageFundingGoal : Nat;
        totalInvestors : Nat;
    };
};
