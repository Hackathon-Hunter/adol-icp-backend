import Time "mo:base/Time";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Nat "mo:base/Nat";

import InvestorTypes "../types/InvestorTypes";
import Validation "../utils/Validation";
import InvestorStorage "../storage/InvestorStorage";

module {

    public class InvestorService(storage : InvestorStorage.InvestorStorage) {

        public func registerInvestor(
            investorId : InvestorTypes.InvestorId,
            request : InvestorTypes.RegisterInvestorRequest,
        ) : InvestorTypes.InvestorRegistrationResult {

            // Check if investor is already registered
            switch (storage.getInvestor(investorId)) {
                case (?existingInvestor) {
                    return #AlreadyRegistered(investorId);
                };
                case null {};
            };

            // Validate input data
            if (not Validation.isValidName(request.fullName)) {
                return #InvalidData("Full name must be between 2 and 100 characters");
            };

            if (not Validation.isValidEmail(request.email)) {
                return #InvalidData("Please provide a valid email address");
            };

            // Check for duplicate email
            switch (storage.getInvestorByEmail(request.email)) {
                case (?existingInvestorId) {
                    return #InvalidData("Email address is already registered");
                };
                case null {};
            };

            // Create investor profile
            let investorProfile : InvestorTypes.InvestorProfile = {
                investorId = investorId;
                fullName = request.fullName;
                email = request.email;
                registrationDate = Time.now();
                status = #Active;
                isActive = true;
                lastUpdated = Time.now();
                totalInvestmentAmount = 0;
                activeInvestments = 0;
                portfolioValue = 0;
            };

            // Store investor profile
            storage.putInvestor(investorId, investorProfile);

            Debug.print("New investor registered: " # request.fullName # " (" # Principal.toText(investorId) # ")");

            #Success(investorId);
        };

        public func updateInvestorProfile(
            investorId : InvestorTypes.InvestorId,
            fullName : ?Text,
            email : ?Text,
        ) : Result.Result<(), Text> {

            switch (storage.getInvestor(investorId)) {
                case null {
                    return #err("Investor not registered");
                };
                case (?investor) {
                    var updatedInvestor = investor;

                    // Update full name if provided
                    switch (fullName) {
                        case (?name) {
                            if (not Validation.isValidName(name)) {
                                return #err("Invalid full name");
                            };
                            updatedInvestor := {
                                updatedInvestor with fullName = name
                            };
                        };
                        case null {};
                    };

                    // Update email if provided
                    switch (email) {
                        case (?newEmail) {
                            if (not Validation.isValidEmail(newEmail)) {
                                return #err("Invalid email address");
                            };

                            // Check if email is already taken by another investor
                            switch (storage.getInvestorByEmail(newEmail)) {
                                case (?existingInvestorId) {
                                    if (not Principal.equal(existingInvestorId, investorId)) {
                                        return #err("Email already taken");
                                    };
                                };
                                case null {};
                            };

                            updatedInvestor := {
                                updatedInvestor with email = newEmail
                            };
                        };
                        case null {};
                    };

                    // Update last modified timestamp
                    updatedInvestor := {
                        updatedInvestor with lastUpdated = Time.now()
                    };

                    storage.updateInvestor(investorId, updatedInvestor);

                    Debug.print("Investor profile updated: " # Principal.toText(investorId));
                    #ok(());
                };
            };
        };

        public func updateInvestorStatus(
            investorId : InvestorTypes.InvestorId,
            newStatus : InvestorTypes.InvestorStatus,
        ) : Result.Result<(), Text> {

            switch (storage.getInvestor(investorId)) {
                case null {
                    return #err("Investor not found");
                };
                case (?investor) {
                    let updatedInvestor : InvestorTypes.InvestorProfile = {
                        investor with
                        status = newStatus;
                        isActive = (newStatus == #Active);
                        lastUpdated = Time.now();
                    };

                    storage.updateInvestor(investorId, updatedInvestor);

                    Debug.print("Investor status updated: " # Principal.toText(investorId));
                    #ok(());
                };
            };
        };

        // Record a new investment for an investor
        public func recordInvestment(
            investorId : InvestorTypes.InvestorId,
            investmentId : Nat,
            nftTokenIds : [Nat],
            investmentAmount : Nat,
        ) : Result.Result<(), Text> {

            switch (storage.getInvestor(investorId)) {
                case null {
                    return #err("Investor not found");
                };
                case (?investor) {
                    // Create investment record
                    let investment : InvestorTypes.InvestorInvestment = {
                        investmentId = investmentId;
                        nftTokenIds = nftTokenIds;
                        investmentAmount = investmentAmount;
                        purchaseDate = Time.now();
                        currentValue = investmentAmount; // Initially same as purchase amount
                        status = #Active;
                    };

                    // Add investment to investor's portfolio
                    storage.addInvestorInvestment(investorId, investment);

                    // Update investor profile statistics
                    let updatedInvestor : InvestorTypes.InvestorProfile = {
                        investor with
                        totalInvestmentAmount = investor.totalInvestmentAmount + investmentAmount;
                        activeInvestments = investor.activeInvestments + 1;
                        portfolioValue = investor.portfolioValue + investmentAmount;
                        lastUpdated = Time.now();
                    };

                    storage.updateInvestor(investorId, updatedInvestor);

                    Debug.print("Investment recorded for investor: " # Principal.toText(investorId) # ", amount: " # Nat.toText(investmentAmount));
                    #ok(());
                };
            };
        };

        // Get investor portfolio
        public func getInvestorPortfolio(investorId : InvestorTypes.InvestorId) : ?InvestorTypes.InvestorPortfolio {
            switch (storage.getInvestor(investorId)) {
                case null { null };
                case (?investor) {
                    let investments = storage.getInvestorInvestments(investorId);

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

                    let roiPercentage = if (totalInvested > 0) {
                        (Float.fromInt(totalReturns) / Float.fromInt(totalInvested)) * 100.0;
                    } else { 0.0 };

                    ?{
                        investor = investor;
                        investments = investments;
                        totalValue = totalValue;
                        totalReturns = totalReturns;
                        roiPercentage = roiPercentage;
                    };
                };
            };
        };

        public func getInvestorsByStatus(status : InvestorTypes.InvestorStatus) : [InvestorTypes.InvestorProfile] {
            storage.getInvestorsByStatus(status);
        };

        public func getInvestorStats() : InvestorTypes.InvestorStats {
            let allInvestors = storage.getAllInvestors();

            let activeInvestors = Array.filter(
                allInvestors,
                func(investor : InvestorTypes.InvestorProfile) : Bool {
                    investor.status == #Active;
                },
            );

            let inactiveInvestors = Array.filter(
                allInvestors,
                func(investor : InvestorTypes.InvestorProfile) : Bool {
                    investor.status == #Inactive;
                },
            );

            let suspendedInvestors = Array.filter(
                allInvestors,
                func(investor : InvestorTypes.InvestorProfile) : Bool {
                    investor.status == #Suspended;
                },
            );

            let totalInvestmentVolume = storage.getTotalInvestmentVolume();
            let averageInvestmentAmount = if (allInvestors.size() > 0) {
                totalInvestmentVolume / allInvestors.size();
            } else { 0 };

            {
                totalInvestors = allInvestors.size();
                activeInvestors = activeInvestors.size();
                inactiveInvestors = inactiveInvestors.size();
                suspendedInvestors = suspendedInvestors.size();
                totalInvestmentVolume = totalInvestmentVolume;
                averageInvestmentAmount = averageInvestmentAmount;
            };
        };

        // Get top investors by investment amount
        public func getTopInvestors(limit : Nat) : [InvestorTypes.InvestorProfile] {
            let allInvestors = storage.getAllInvestors();

            // Sort by total investment amount (highest first)
            let sorted = Array.sort<InvestorTypes.InvestorProfile>(
                allInvestors,
                func(a, b) {
                    if (a.totalInvestmentAmount > b.totalInvestmentAmount) {
                        #less;
                    } else if (a.totalInvestmentAmount < b.totalInvestmentAmount) {
                        #greater;
                    } else { #equal };
                },
            );

            // Return first 'limit' items
            if (sorted.size() <= limit) {
                sorted;
            } else {
                Array.tabulate<InvestorTypes.InvestorProfile>(limit, func(i) { sorted[i] });
            };
        };

        // Update investment value (for portfolio tracking)
        public func updateInvestmentValue(
            investorId : InvestorTypes.InvestorId,
            investmentId : Nat,
            newValue : Nat,
        ) : Result.Result<(), Text> {

            let investments = storage.getInvestorInvestments(investorId);

            switch (Array.find<InvestorTypes.InvestorInvestment>(investments, func(inv) { inv.investmentId == investmentId })) {
                case null {
                    return #err("Investment not found");
                };
                case (?existingInvestment) {
                    let updatedInvestment : InvestorTypes.InvestorInvestment = {
                        existingInvestment with currentValue = newValue
                    };

                    storage.updateInvestorInvestment(investorId, investmentId, updatedInvestment);

                    // Recalculate investor's total portfolio value
                    let allInvestments = storage.getInvestorInvestments(investorId);
                    let totalPortfolioValue = Array.foldLeft<InvestorTypes.InvestorInvestment, Nat>(
                        allInvestments,
                        0,
                        func(acc, inv) { acc + inv.currentValue },
                    );

                    // Update investor profile
                    switch (storage.getInvestor(investorId)) {
                        case (?investor) {
                            let updatedInvestor : InvestorTypes.InvestorProfile = {
                                investor with
                                portfolioValue = totalPortfolioValue;
                                lastUpdated = Time.now();
                            };
                            storage.updateInvestor(investorId, updatedInvestor);
                        };
                        case null {};
                    };

                    #ok(());
                };
            };
        };

        // Check if investor exists and is active
        public func isActiveInvestor(investorId : InvestorTypes.InvestorId) : Bool {
            switch (storage.getInvestor(investorId)) {
                case null { false };
                case (?investor) {
                    investor.status == #Active and investor.isActive;
                };
            };
        };
    };
};
