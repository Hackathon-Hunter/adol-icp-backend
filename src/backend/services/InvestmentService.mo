import Time "mo:base/Time";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";

import InvestmentTypes "../types/InvestmentTypes";
import InvestmentValidation "../utils/InvestmentValidation";
import InvestmentStorage "../storage/InvestmentStorage";

module {

    public class InvestmentService(
        storage : InvestmentStorage.InvestmentStorage,
        farmerStorage : {
            getFarmer : (Principal) -> ?{
                verificationStatus : {
                    #Pending;
                    #InReview;
                    #Approved;
                    #Rejected;
                };
                isActive : Bool;
            };
        },
    ) {

        private var nextInvestmentId : Nat = 1;

        public func createInvestment(
            farmerId : InvestmentTypes.FarmerId,
            request : InvestmentTypes.CreateInvestmentRequest,
        ) : InvestmentTypes.InvestmentProjectResult {

            // Check if farmer is verified
            switch (farmerStorage.getFarmer(farmerId)) {
                case null {
                    return #Error("Farmer not found. Please register as a farmer first.");
                };
                case (?farmer) {
                    if (farmer.verificationStatus != #Approved or not farmer.isActive) {
                        return #FarmerNotVerified;
                    };
                };
            };

            // Validate the complete request
            switch (InvestmentValidation.validateInvestmentRequest(request)) {
                case (?error) {
                    return #InvalidData(error);
                };
                case null {};
            };

            // Create investment project
            let investmentProject : InvestmentTypes.InvestmentProject = {
                id = nextInvestmentId;
                farmerId = farmerId;
                farmInfo = request.farmInfo;
                experience = request.experience;
                budget = request.budget;
                documents = request.documents;
                agreements = request.agreements;
                status = #PendingVerification;
                createdAt = Time.now();
                lastUpdated = Time.now();
                verificationNotes = null;
                approvedAt = null;
                rejectedReason = null;
            };

            // Store investment project
            storage.putInvestment(nextInvestmentId, investmentProject);

            // Create verification tracker
            let verificationTracker = createInitialVerificationTracker(nextInvestmentId);
            storage.putVerificationTracker(nextInvestmentId, verificationTracker);

            let currentId = nextInvestmentId;
            nextInvestmentId += 1;

            Debug.print("New investment project created with ID: " # Nat.toText(currentId) # " by farmer: " # Principal.toText(farmerId));

            #Success(currentId);
        };

        // Update investment status (admin function)
        public func updateInvestmentStatus(
            investmentId : InvestmentTypes.InvestmentId,
            newStatus : InvestmentTypes.InvestmentStatus,
            notes : ?Text,
        ) : Result.Result<(), Text> {

            switch (storage.getInvestment(investmentId)) {
                case null {
                    return #err("Investment project not found");
                };
                case (?investment) {
                    let updatedInvestment : InvestmentTypes.InvestmentProject = {
                        investment with
                        status = newStatus;
                        lastUpdated = Time.now();
                        verificationNotes = notes;
                        approvedAt = if (newStatus == #Approved) {
                            ?Time.now();
                        } else { investment.approvedAt };
                        rejectedReason = if (newStatus == #Rejected) { notes } else {
                            investment.rejectedReason;
                        };
                    };

                    storage.updateInvestment(investmentId, updatedInvestment);

                    // Update verification tracker
                    updateVerificationProgress(investmentId, newStatus);

                    Debug.print("Investment " # Nat.toText(investmentId) # " status updated to: " # debug_show (newStatus));
                    #ok(());
                };
            };
        };

        // Add document to existing investment
        public func addDocument(
            farmerId : InvestmentTypes.FarmerId,
            investmentId : InvestmentTypes.InvestmentId,
            document : InvestmentTypes.InvestmentDocument,
        ) : Result.Result<(), Text> {

            switch (storage.getInvestment(investmentId)) {
                case null {
                    return #err("Investment project not found");
                };
                case (?investment) {
                    // Check if farmer owns this investment
                    if (not Principal.equal(investment.farmerId, farmerId)) {
                        return #err("You can only add documents to your own investment projects");
                    };

                    // Validate document
                    if (InvestmentValidation.validateDocuments([document]) != null) {
                        return #err("Invalid document");
                    };

                    let updatedDocuments = Array.append<InvestmentTypes.InvestmentDocument>(investment.documents, [document]);
                    let updatedInvestment : InvestmentTypes.InvestmentProject = {
                        investment with
                        documents = updatedDocuments;
                        lastUpdated = Time.now();
                    };

                    storage.updateInvestment(investmentId, updatedInvestment);

                    Debug.print("Document added to investment " # Nat.toText(investmentId));
                    #ok(());
                };
            };
        };

        // Get investments by farmer
        public func getInvestmentsByFarmer(farmerId : InvestmentTypes.FarmerId) : [InvestmentTypes.InvestmentProject] {
            storage.getInvestmentsByFarmer(farmerId);
        };

        // Get investments by status
        public func getInvestmentsByStatus(status : InvestmentTypes.InvestmentStatus) : [InvestmentTypes.InvestmentProject] {
            storage.getInvestmentsByStatus(status);
        };

        // Get investment statistics
        public func getInvestmentStats() : InvestmentTypes.InvestmentStats {
            let allInvestments = storage.getAllInvestments();

            let pendingVerification = Array.filter(
                allInvestments,
                func(inv : InvestmentTypes.InvestmentProject) : Bool {
                    inv.status == #PendingVerification or inv.status == #InVerification;
                },
            );

            let approved = Array.filter(
                allInvestments,
                func(inv : InvestmentTypes.InvestmentProject) : Bool {
                    inv.status == #Approved;
                },
            );

            let rejected = Array.filter(
                allInvestments,
                func(inv : InvestmentTypes.InvestmentProject) : Bool {
                    inv.status == #Rejected;
                },
            );

            let active = Array.filter(
                allInvestments,
                func(inv : InvestmentTypes.InvestmentProject) : Bool {
                    inv.status == #Active;
                },
            );

            let completed = Array.filter(
                allInvestments,
                func(inv : InvestmentTypes.InvestmentProject) : Bool {
                    inv.status == #Completed;
                },
            );

            {
                totalProjects = allInvestments.size();
                pendingVerification = pendingVerification.size();
                approvedProjects = approved.size();
                rejectedProjects = rejected.size();
                activeProjects = active.size();
                completedProjects = completed.size();
            };
        };

        // Get verification tracker
        public func getVerificationTracker(investmentId : InvestmentTypes.InvestmentId) : ?InvestmentTypes.VerificationTracker {
            storage.getVerificationTracker(investmentId);
        };

        // Search investments by criteria
        public func searchInvestments(
            cropType : ?InvestmentTypes.CropType,
            country : ?Text,
            minFunding : ?Nat,
            maxFunding : ?Nat,
            status : ?InvestmentTypes.InvestmentStatus,
        ) : [InvestmentTypes.InvestmentProject] {

            var filteredInvestments = storage.getAllInvestments();

            // Filter by crop type
            switch (cropType) {
                case (?crop) {
                    filteredInvestments := Array.filter(
                        filteredInvestments,
                        func(inv : InvestmentTypes.InvestmentProject) : Bool {
                            inv.farmInfo.cropType == crop;
                        },
                    );
                };
                case null {};
            };

            // Filter by country
            switch (country) {
                case (?countryFilter) {
                    filteredInvestments := Array.filter(
                        filteredInvestments,
                        func(inv : InvestmentTypes.InvestmentProject) : Bool {
                            inv.farmInfo.country == countryFilter;
                        },
                    );
                };
                case null {};
            };

            // Filter by funding range
            switch (minFunding, maxFunding) {
                case (?minAmount, ?maxAmount) {
                    filteredInvestments := Array.filter(
                        filteredInvestments,
                        func(inv : InvestmentTypes.InvestmentProject) : Bool {
                            let funding = inv.farmInfo.fundingRequired;
                            funding >= minAmount and funding <= maxAmount;
                        },
                    );
                };
                case (?minAmount, null) {
                    filteredInvestments := Array.filter(
                        filteredInvestments,
                        func(inv : InvestmentTypes.InvestmentProject) : Bool {
                            inv.farmInfo.fundingRequired >= minAmount;
                        },
                    );
                };
                case (null, ?maxAmount) {
                    filteredInvestments := Array.filter(
                        filteredInvestments,
                        func(inv : InvestmentTypes.InvestmentProject) : Bool {
                            inv.farmInfo.fundingRequired <= maxAmount;
                        },
                    );
                };
                case (null, null) {};
            };

            // Filter by status
            switch (status) {
                case (?statusFilter) {
                    filteredInvestments := Array.filter(
                        filteredInvestments,
                        func(inv : InvestmentTypes.InvestmentProject) : Bool {
                            inv.status == statusFilter;
                        },
                    );
                };
                case null {};
            };

            filteredInvestments;
        };

        // Get investment projects by crop type
        public func getInvestmentsByCrop(cropType : InvestmentTypes.CropType) : [InvestmentTypes.InvestmentProject] {
            storage.getInvestmentsByCrop(cropType);
        };

        // Get investment projects by location
        public func getInvestmentsByLocation(country : Text, state : ?Text) : [InvestmentTypes.InvestmentProject] {
            storage.getInvestmentsByLocation(country, state);
        };

        // Get investment projects by funding range
        public func getInvestmentsByFundingRange(minAmount : Nat, maxAmount : Nat) : [InvestmentTypes.InvestmentProject] {
            storage.getInvestmentsByFundingRange(minAmount, maxAmount);
        };

        // Get recent investment projects
        public func getRecentInvestments(limit : Nat) : [InvestmentTypes.InvestmentProject] {
            storage.getRecentInvestments(limit);
        };

        // Update investment project details (farmer only)
        public func updateInvestmentProject(
            farmerId : InvestmentTypes.FarmerId,
            investmentId : InvestmentTypes.InvestmentId,
            farmInfo : ?InvestmentTypes.FarmInfoRequest,
            experience : ?InvestmentTypes.ExperienceRequest,
            budget : ?InvestmentTypes.BudgetRequest,
        ) : Result.Result<(), Text> {

            switch (storage.getInvestment(investmentId)) {
                case null {
                    return #err("Investment project not found");
                };
                case (?investment) {
                    // Check if farmer owns this investment
                    if (not Principal.equal(investment.farmerId, farmerId)) {
                        return #err("You can only update your own investment projects");
                    };

                    // Only allow updates if status is Draft or PendingVerification
                    if (investment.status != #Draft and investment.status != #PendingVerification) {
                        return #err("Cannot update investment project after verification has started");
                    };

                    var updatedInvestment = investment;

                    // Update farm info if provided
                    switch (farmInfo) {
                        case (?newFarmInfo) {
                            switch (InvestmentValidation.validateFarmInfo(newFarmInfo)) {
                                case (?error) { return #err(error) };
                                case null {
                                    updatedInvestment := {
                                        updatedInvestment with farmInfo = newFarmInfo
                                    };
                                };
                            };
                        };
                        case null {};
                    };

                    // Update experience if provided
                    switch (experience) {
                        case (?newExperience) {
                            switch (InvestmentValidation.validateExperience(newExperience)) {
                                case (?error) { return #err(error) };
                                case null {
                                    updatedInvestment := {
                                        updatedInvestment with experience = newExperience
                                    };
                                };
                            };
                        };
                        case null {};
                    };

                    // Update budget if provided
                    switch (budget) {
                        case (?newBudget) {
                            switch (InvestmentValidation.validateBudget(newBudget)) {
                                case (?error) { return #err(error) };
                                case null {
                                    updatedInvestment := {
                                        updatedInvestment with budget = newBudget
                                    };
                                };
                            };
                        };
                        case null {};
                    };

                    // Update last modified timestamp
                    updatedInvestment := {
                        updatedInvestment with lastUpdated = Time.now()
                    };

                    storage.updateInvestment(investmentId, updatedInvestment);

                    Debug.print("Investment project " # Nat.toText(investmentId) # " updated by farmer: " # Principal.toText(farmerId));
                    #ok(());
                };
            };
        };

        // Delete investment project (farmer only, only if Draft)
        public func deleteInvestmentProject(
            farmerId : InvestmentTypes.FarmerId,
            investmentId : InvestmentTypes.InvestmentId,
        ) : Result.Result<(), Text> {

            switch (storage.getInvestment(investmentId)) {
                case null {
                    return #err("Investment project not found");
                };
                case (?investment) {
                    // Check if farmer owns this investment
                    if (not Principal.equal(investment.farmerId, farmerId)) {
                        return #err("You can only delete your own investment projects");
                    };

                    // Only allow deletion if status is Draft
                    if (investment.status != #Draft) {
                        return #err("Cannot delete investment project after submission");
                    };

                    storage.deleteInvestment(investmentId);

                    Debug.print("Investment project " # Nat.toText(investmentId) # " deleted by farmer: " # Principal.toText(farmerId));
                    #ok(());
                };
            };
        };

        // Submit investment project for verification (farmer only)
        public func submitInvestmentForVerification(
            farmerId : InvestmentTypes.FarmerId,
            investmentId : InvestmentTypes.InvestmentId,
        ) : Result.Result<(), Text> {

            switch (storage.getInvestment(investmentId)) {
                case null {
                    return #err("Investment project not found");
                };
                case (?investment) {
                    // Check if farmer owns this investment
                    if (not Principal.equal(investment.farmerId, farmerId)) {
                        return #err("You can only submit your own investment projects");
                    };

                    // Only allow submission if status is Draft
                    if (investment.status != #Draft) {
                        return #err("Investment project has already been submitted");
                    };

                    // Validate complete investment before submission
                    let completeRequest : InvestmentTypes.CreateInvestmentRequest = {
                        farmInfo = investment.farmInfo;
                        experience = investment.experience;
                        budget = investment.budget;
                        documents = investment.documents;
                        agreements = investment.agreements;
                    };

                    switch (InvestmentValidation.validateInvestmentRequest(completeRequest)) {
                        case (?error) {
                            return #err("Validation failed: " # error);
                        };
                        case null {};
                    };

                    // Update status to PendingVerification
                    let updatedInvestment : InvestmentTypes.InvestmentProject = {
                        investment with
                        status = #PendingVerification;
                        lastUpdated = Time.now();
                    };

                    storage.updateInvestment(investmentId, updatedInvestment);

                    // Create verification tracker if it doesn't exist
                    switch (storage.getVerificationTracker(investmentId)) {
                        case null {
                            let tracker = createInitialVerificationTracker(investmentId);
                            storage.putVerificationTracker(investmentId, tracker);
                        };
                        case (?_) {}; // Tracker already exists
                    };

                    Debug.print("Investment project " # Nat.toText(investmentId) # " submitted for verification by farmer: " # Principal.toText(farmerId));
                    #ok(());
                };
            };
        };

        // Get total funding requested across all projects
        public func getTotalFundingRequested() : Nat {
            storage.getTotalFundingRequested();
        };

        // Get investment count
        public func getInvestmentCount() : Nat {
            storage.getInvestmentCount();
        };

        // Get farmer count (farmers who have created investment projects)
        public func getFarmerInvestorCount() : Nat {
            storage.getFarmerCount();
        };

        // Helper function to create initial verification tracker
        private func createInitialVerificationTracker(investmentId : InvestmentTypes.InvestmentId) : InvestmentTypes.VerificationTracker {
            let steps : [InvestmentTypes.VerificationStep] = [
                {
                    stepName = "Document Review";
                    description = "Reviewing submitted documents and application forms";
                    status = #Pending;
                    estimatedTime = "6-12 hours";
                    completedAt = null;
                    notes = null;
                },
                {
                    stepName = "Agricultural Assessment";
                    description = "Evaluating farming plan, crop viability, and market analysis";
                    status = #Pending;
                    estimatedTime = "12-24 hours";
                    completedAt = null;
                    notes = null;
                },
                {
                    stepName = "Site Verification";
                    description = "Physical inspection of farm location and infrastructure";
                    status = #Pending;
                    estimatedTime = "1-2 days";
                    completedAt = null;
                    notes = null;
                },
                {
                    stepName = "Financial Validation";
                    description = "Budget analysis and financial feasibility assessment";
                    status = #Pending;
                    estimatedTime = "4-8 hours";
                    completedAt = null;
                    notes = null;
                },
                {
                    stepName = "Final Approval";
                    description = "Management review and final approval decision";
                    status = #Pending;
                    estimatedTime = "2-4 hours";
                    completedAt = null;
                    notes = null;
                },
                {
                    stepName = "Investment Launched";
                    description = "Project goes live on marketplace for investors";
                    status = #Pending;
                    estimatedTime = "1-2 hours";
                    completedAt = null;
                    notes = null;
                },
            ];

            {
                investmentId = investmentId;
                overallProgress = 0;
                currentStep = "Document Review";
                steps = steps;
                lastUpdated = Time.now();
            };
        };

        // Helper function to update verification progress
        private func updateVerificationProgress(investmentId : InvestmentTypes.InvestmentId, newStatus : InvestmentTypes.InvestmentStatus) {
            switch (storage.getVerificationTracker(investmentId)) {
                case (?tracker) {
                    let (updatedSteps, progress, currentStep) = updateStepsBasedOnStatus(tracker.steps, newStatus);

                    let updatedTracker : InvestmentTypes.VerificationTracker = {
                        tracker with
                        overallProgress = progress;
                        currentStep = currentStep;
                        steps = updatedSteps;
                        lastUpdated = Time.now();
                    };

                    storage.updateVerificationTracker(investmentId, updatedTracker);
                };
                case null {};
            };
        };

        // Helper function to update steps based on status
        private func updateStepsBasedOnStatus(
            steps : [InvestmentTypes.VerificationStep],
            status : InvestmentTypes.InvestmentStatus,
        ) : ([InvestmentTypes.VerificationStep], Nat, Text) {

            var updatedSteps = steps;
            var progress : Nat = 0;
            var currentStep = "Document Review";

            switch (status) {
                case (#PendingVerification) {
                    progress := 0;
                    currentStep := "Document Review";
                };
                case (#InVerification) {
                    progress := 16; // 1/6 steps
                    currentStep := "Agricultural Assessment";
                    updatedSteps := Array.tabulate<InvestmentTypes.VerificationStep>(
                        steps.size(),
                        func(i) {
                            let step = steps[i];
                            if (i == 0) {
                                {
                                    step with status = #Completed;
                                    completedAt = ?Time.now();
                                };
                            } else if (i == 1) {
                                { step with status = #InProgress };
                            } else {
                                step;
                            };
                        },
                    );
                };
                case (#Approved) {
                    progress := 100;
                    currentStep := "Investment Launched";
                    updatedSteps := Array.map<InvestmentTypes.VerificationStep, InvestmentTypes.VerificationStep>(
                        steps,
                        func(step) {
                            {
                                step with status = #Completed;
                                completedAt = ?Time.now();
                            };
                        },
                    );
                };
                case (#Rejected) {
                    progress := 33; // Failed at some point
                    currentStep := "Verification Failed";
                    updatedSteps := Array.tabulate<InvestmentTypes.VerificationStep>(
                        steps.size(),
                        func(i) {
                            let step = steps[i];
                            if (i <= 2) {
                                {
                                    step with status = #Failed;
                                    completedAt = ?Time.now();
                                };
                            } else {
                                step;
                            };
                        },
                    );
                };
                case (#Active) {
                    progress := 100;
                    currentStep := "Project Active";
                };
                case _ {
                    progress := 0;
                    currentStep := "Document Review";
                };
            };

            (updatedSteps, progress, currentStep);
        };

        // Set next investment ID (for initialization)
        public func setNextInvestmentId(id : Nat) {
            nextInvestmentId := id;
        };

        // Get next investment ID (for stable storage)
        public func getNextInvestmentId() : Nat {
            nextInvestmentId;
        };
    };
};
