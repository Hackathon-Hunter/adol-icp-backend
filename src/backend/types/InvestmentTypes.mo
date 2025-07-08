import Principal "mo:base/Principal";

module {
    public type InvestmentId = Nat;
    public type FarmerId = Principal;

    public type CropType = {
        #Rice;
        #Corn;
        #Vegetables;
        #Fruits;
        #Coffee;
        #Other : Text;
    };

    public type LandOwnership = {
        #Owned;
        #Leased;
        #Partnership;
    };

    public type AccessRoadCondition = {
        #Good;
        #Fair;
        #Poor;
    };

    public type ExperienceLevel = {
        #Beginner; // 0-2 years
        #Intermediate; // 3-5 years
        #Experienced; // 5+ years
    };

    public type HarvestTimeline = {
        #Short; // 3-4 months
        #Medium; // 6-8 months
        #Long; // 12+ months
    };

    public type CultivationMethod = {
        #Organic;
        #Conventional;
        #Hydroponic;
    };

    public type MarketDistribution = {
        #LocalMarkets;
        #ExportBuyers;
        #DirectToConsumer;
        #Cooperatives;
        #ProcessingIndustries;
        #ContractFarming;
    };

    public type BudgetAllocation = {
        seeds : Nat; // percentage
        fertilizers : Nat; // percentage
        labor : Nat; // percentage
        equipment : Nat; // percentage
        operational : Nat; // percentage
        infrastructure : Nat; // percentage
        insurance : Nat; // percentage
    };

    public type InvestmentStatus = {
        #Draft;
        #PendingVerification;
        #InVerification;
        #Approved;
        #Rejected;
        #Active;
        #Completed;
        #Cancelled;
    };

    public type DocumentType = {
        #LandCertificate;
        #LeaseAgreement;
        #GovernmentPermit;
        #PreviousHarvestPhoto;
        #AgriculturalCertification;
        #CommunityEndorsement;
        #SoilTestResult;
        #FarmPhoto;
    };

    public type InvestmentDocument = {
        documentType : DocumentType;
        fileName : Text;
        fileHash : Text;
        uploadedAt : Int;
        isRequired : Bool;
    };

    // Step 1: Farm Information
    public type FarmInfoRequest = {
        cropType : CropType;
        country : Text;
        stateProvince : Text;
        cityDistrict : Text;
        gpsCoordinates : ?Text;
        farmSize : Text; // in hectares/acres
        landOwnership : LandOwnership;
        waterSource : Text;
        accessRoads : AccessRoadCondition;
        fundingRequired : Nat; // in USD cents to avoid decimals
    };

    // Step 2: Experience & Cultivation Plan
    public type ExperienceRequest = {
        farmingExperience : ExperienceLevel;
        harvestTimeline : HarvestTimeline;
        expectedYield : Text; // amount with unit (tons/kg)
        cultivationMethod : CultivationMethod;
        marketDistribution : [MarketDistribution];
        investmentDescription : Text; // max 200 words
    };

    // Step 3: Budget Allocation
    public type BudgetRequest = {
        budgetAllocation : BudgetAllocation;
        hasBusinessBankAccount : Bool;
        previousFarmingLoans : ?Bool; // Yes/No/NA
        emergencyContactName : Text;
        emergencyContactPhone : Text;
        expectedMinROI : Nat; // percentage
        expectedMaxROI : Nat; // percentage
    };

    // Complete Investment Setup
    public type CreateInvestmentRequest = {
        farmInfo : FarmInfoRequest;
        experience : ExperienceRequest;
        budget : BudgetRequest;
        documents : [InvestmentDocument];
        agreements : [Bool]; // Legal agreements checkboxes
    };

    public type InvestmentProject = {
        id : InvestmentId;
        farmerId : FarmerId;
        farmInfo : FarmInfoRequest;
        experience : ExperienceRequest;
        budget : BudgetRequest;
        documents : [InvestmentDocument];
        agreements : [Bool];
        status : InvestmentStatus;
        createdAt : Int;
        lastUpdated : Int;
        verificationNotes : ?Text;
        approvedAt : ?Int;
        rejectedReason : ?Text;
    };

    public type InvestmentProjectResult = {
        #Success : InvestmentId;
        #InvalidData : Text;
        #FarmerNotVerified;
        #Error : Text;
    };

    public type InvestmentStats = {
        totalProjects : Nat;
        pendingVerification : Nat;
        approvedProjects : Nat;
        rejectedProjects : Nat;
        activeProjects : Nat;
        completedProjects : Nat;
    };

    public type VerificationStep = {
        stepName : Text;
        description : Text;
        status : { #Pending; #InProgress; #Completed; #Failed };
        estimatedTime : Text;
        completedAt : ?Int;
        notes : ?Text;
    };

    public type VerificationTracker = {
        investmentId : InvestmentId;
        overallProgress : Nat; // percentage
        currentStep : Text;
        steps : [VerificationStep];
        lastUpdated : Int;
    };
};
