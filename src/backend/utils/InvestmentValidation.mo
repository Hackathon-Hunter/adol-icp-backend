import Text "mo:base/Text";
import Array "mo:base/Array";
import InvestmentTypes "../types/InvestmentTypes";

module {

    // Farm Info Validation
    public func validateFarmInfo(farmInfo : InvestmentTypes.FarmInfoRequest) : ?Text {

        // Country validation
        if (Text.size(farmInfo.country) < 2) {
            return ?"Country must be specified";
        };

        // State/Province validation
        if (Text.size(farmInfo.stateProvince) < 2) {
            return ?"State/Province must be specified";
        };

        // City/District validation
        if (Text.size(farmInfo.cityDistrict) < 2) {
            return ?"City/District must be specified";
        };

        // Farm size validation
        if (Text.size(farmInfo.farmSize) == 0) {
            return ?"Farm size must be specified";
        };

        // Water source validation
        if (Text.size(farmInfo.waterSource) < 5) {
            return ?"Water source description must be at least 5 characters";
        };

        // Funding validation (minimum $100)
        if (farmInfo.fundingRequired < 10000) {
            // $100 in cents
            return ?"Funding required must be at least $100";
        };

        // Maximum funding validation ($1M)
        if (farmInfo.fundingRequired > 100000000) {
            // $1M in cents
            return ?"Funding required cannot exceed $1,000,000";
        };

        null;
    };

    // Experience Validation
    public func validateExperience(experience : InvestmentTypes.ExperienceRequest) : ?Text {

        // Expected yield validation
        if (Text.size(experience.expectedYield) < 3) {
            return ?"Expected yield must be specified with unit (e.g., '10 tons')";
        };

        // Investment description validation (max 200 words)
        let wordCount = countWords(experience.investmentDescription);
        if (wordCount > 200) {
            return ?"Investment description must not exceed 200 words";
        };

        if (Text.size(experience.investmentDescription) < 50) {
            return ?"Investment description must be at least 50 characters";
        };

        // Market distribution validation (at least one option)
        if (experience.marketDistribution.size() == 0) {
            return ?"At least one market distribution channel must be selected";
        };

        null;
    };

    // Budget Validation
    public func validateBudget(budget : InvestmentTypes.BudgetRequest) : ?Text {

        // Budget allocation validation (must sum to 100%)
        let total = budget.budgetAllocation.seeds + budget.budgetAllocation.fertilizers + budget.budgetAllocation.labor + budget.budgetAllocation.equipment + budget.budgetAllocation.operational + budget.budgetAllocation.infrastructure + budget.budgetAllocation.insurance;

        if (total != 100) {
            return ?"Budget allocation must sum to 100%";
        };

        // Individual allocation validation (none should be 0 or > 80%)
        if (budget.budgetAllocation.seeds == 0 or budget.budgetAllocation.seeds > 80) {
            return ?"Seeds allocation must be between 1% and 80%";
        };

        if (budget.budgetAllocation.labor == 0 or budget.budgetAllocation.labor > 80) {
            return ?"Labor allocation must be between 1% and 80%";
        };

        // Emergency contact validation
        if (Text.size(budget.emergencyContactName) < 2) {
            return ?"Emergency contact name must be specified";
        };

        if (Text.size(budget.emergencyContactPhone) < 10) {
            return ?"Emergency contact phone must be at least 10 digits";
        };

        // ROI validation
        if (budget.expectedMinROI >= budget.expectedMaxROI) {
            return ?"Maximum ROI must be greater than minimum ROI";
        };

        if (budget.expectedMinROI > 100 or budget.expectedMaxROI > 200) {
            return ?"ROI percentages seem unrealistic (max 200%)";
        };

        null;
    };

    // Document validation
    public func validateDocuments(documents : [InvestmentTypes.InvestmentDocument]) : ?Text {

        // Check for required documents
        let hasLandDocument = Array.find<InvestmentTypes.InvestmentDocument>(
            documents,
            func(doc) {
                doc.documentType == #LandCertificate or doc.documentType == #LeaseAgreement;
            },
        );

        if (hasLandDocument == null) {
            return ?"Land certificate or lease agreement is required";
        };

        // Check for farm photos
        let hasFarmPhotos = Array.find<InvestmentTypes.InvestmentDocument>(
            documents,
            func(doc) { doc.documentType == #FarmPhoto },
        );

        if (hasFarmPhotos == null) {
            return ?"At least one farm photo is required";
        };

        // Validate individual documents
        for (doc in documents.vals()) {
            if (Text.size(doc.fileName) == 0) {
                return ?"Document filename cannot be empty";
            };

            if (Text.size(doc.fileHash) < 32) {
                return ?"Invalid document file hash";
            };
        };

        null;
    };

    // Legal agreements validation
    public func validateAgreements(agreements : [Bool]) : ?Text {

        // Should have exactly 5 agreements based on the form
        if (agreements.size() != 5) {
            return ?"All legal agreements must be acknowledged";
        };

        // All agreements must be true
        for (agreement in agreements.vals()) {
            if (not agreement) {
                return ?"All legal agreements must be accepted";
            };
        };

        null;
    };

    // Complete request validation
    public func validateInvestmentRequest(request : InvestmentTypes.CreateInvestmentRequest) : ?Text {

        switch (validateFarmInfo(request.farmInfo)) {
            case (?error) { return ?error };
            case null {};
        };

        switch (validateExperience(request.experience)) {
            case (?error) { return ?error };
            case null {};
        };

        switch (validateBudget(request.budget)) {
            case (?error) { return ?error };
            case null {};
        };

        switch (validateDocuments(request.documents)) {
            case (?error) { return ?error };
            case null {};
        };

        switch (validateAgreements(request.agreements)) {
            case (?error) { return ?error };
            case null {};
        };

        null;
    };

    // Helper function to count words
    private func countWords(text : Text) : Nat {
        let chars = Text.toIter(text);
        var wordCount = 0;
        var inWord = false;

        for (char in chars) {
            if (char == ' ' or char == '\n' or char == '\t') {
                if (inWord) {
                    wordCount += 1;
                    inWord := false;
                };
            } else {
                inWord := true;
            };
        };

        // Count the last word if text doesn't end with whitespace
        if (inWord) {
            wordCount += 1;
        };

        wordCount;
    };

    // Validate GPS coordinates format (optional)
    public func validateGPSCoordinates(coords : ?Text) : Bool {
        switch (coords) {
            case null { true }; // Optional field
            case (?coordinates) {
                // Basic validation for GPS format (latitude, longitude)
                Text.contains(coordinates, #char ',') and Text.size(coordinates) > 5
            };
        };
    };
};
