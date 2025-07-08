import Principal "mo:base/Principal";

module {
    public type InvestorId = Principal;

    public type InvestorStatus = {
        #Active;
        #Inactive;
        #Suspended;
    };

    public type InvestorProfile = {
        investorId : InvestorId;
        fullName : Text;
        email : Text;
        registrationDate : Int;
        status : InvestorStatus;
        isActive : Bool;
        lastUpdated : Int;
        // Investment tracking
        totalInvestmentAmount : Nat; // Total amount invested in ICP e8s
        activeInvestments : Nat; // Number of active investments
        portfolioValue : Nat; // Current portfolio value in ICP e8s
    };

    public type RegisterInvestorRequest = {
        fullName : Text;
        email : Text;
    };

    public type InvestorRegistrationResult = {
        #Success : InvestorId;
        #AlreadyRegistered : InvestorId;
        #InvalidData : Text;
        #Error : Text;
    };

    public type InvestorStats = {
        totalInvestors : Nat;
        activeInvestors : Nat;
        inactiveInvestors : Nat;
        suspendedInvestors : Nat;
        totalInvestmentVolume : Nat;
        averageInvestmentAmount : Nat;
    };

    public type InvestorInvestment = {
        investmentId : Nat;
        nftTokenIds : [Nat];
        investmentAmount : Nat; // Amount invested in ICP e8s
        purchaseDate : Int;
        currentValue : Nat; // Current estimated value
        status : { #Active; #Matured; #Sold };
    };

    public type InvestorPortfolio = {
        investor : InvestorProfile;
        investments : [InvestorInvestment];
        totalValue : Nat;
        totalReturns : Nat;
        roiPercentage : Float;
    };
};
