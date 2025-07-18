import Text "mo:base/Text";
import Array "mo:base/Array";
import Result "mo:base/Result";
import ProjectTypes "../types/ProjectTypes";

module ProjectValidation {

    type ProjectCreateRequest = ProjectTypes.ProjectCreateRequest;
    type ProjectUpdateRequest = ProjectTypes.ProjectUpdateRequest;
    type ValidationResult = ProjectTypes.ValidationResult;
    type ProjectType = ProjectTypes.ProjectType;

    // Validate project title
    public func validateTitle(title : Text) : ValidationResult {
        if (Text.size(title) < 5) {
            return #err("Project title must be at least 5 characters");
        };
        if (Text.size(title) > 100) {
            return #err("Project title must be less than 100 characters");
        };
        #ok(());
    };

    // Validate project description
    public func validateDescription(description : Text) : ValidationResult {
        if (Text.size(description) < 20) {
            return #err("Project description must be at least 20 characters");
        };
        if (Text.size(description) > 2000) {
            return #err("Project description must be less than 2000 characters");
        };
        #ok(());
    };

    // Validate category
    public func validateCategory(category : Text) : ValidationResult {
        if (Text.size(category) < 2) {
            return #err("Category must be at least 2 characters");
        };
        if (Text.size(category) > 50) {
            return #err("Category must be less than 50 characters");
        };
        #ok(());
    };

    // Validate location
    public func validateLocation(location : Text) : ValidationResult {
        if (Text.size(location) < 2) {
            return #err("Location must be at least 2 characters");
        };
        if (Text.size(location) > 100) {
            return #err("Location must be less than 100 characters");
        };
        #ok(());
    };

    // Validate funding goal
    public func validateFundingGoal(fundingGoal : Nat) : ValidationResult {
        if (fundingGoal < 10000) {
            // Minimum $100
            return #err("Funding goal must be at least $100");
        };
        if (fundingGoal > 10000000000) {
            // Maximum $100,000,000
            return #err("Funding goal must be less than $100,000,000");
        };
        #ok(());
    };

    // Validate minimum investment
    public func validateMinInvestment(minInvestment : Nat, fundingGoal : Nat) : ValidationResult {
        if (minInvestment < 1000) {
            // Minimum $10
            return #err("Minimum investment must be at least $10");
        };
        if (minInvestment > fundingGoal) {
            return #err("Minimum investment cannot exceed funding goal");
        };
        if (minInvestment > fundingGoal / 10) {
            // Max 10% of funding goal
            return #err("Minimum investment too high - should be reasonable portion of funding goal");
        };
        #ok(());
    };

    // Validate maximum investment
    public func validateMaxInvestment(maxInvestment : ?Nat, fundingGoal : Nat, minInvestment : Nat) : ValidationResult {
        switch (maxInvestment) {
            case null { #ok(()) }; // Optional field
            case (?max) {
                if (max < minInvestment) {
                    return #err("Maximum investment must be greater than minimum investment");
                };
                if (max > fundingGoal) {
                    return #err("Maximum investment cannot exceed funding goal");
                };
                #ok(());
            };
        };
    };

    // Validate timeline
    public func validateTimeline(timeline : Text) : ValidationResult {
        if (Text.size(timeline) < 2) {
            return #err("Timeline is required");
        };
        if (Text.size(timeline) > 50) {
            return #err("Timeline must be less than 50 characters");
        };
        #ok(());
    };

    // Validate expected ROI
    public func validateExpectedROI(expectedROI : Text) : ValidationResult {
        if (Text.size(expectedROI) < 1) {
            return #err("Expected ROI is required");
        };
        if (Text.size(expectedROI) > 20) {
            return #err("Expected ROI must be less than 20 characters");
        };
        #ok(());
    };

    // Validate risk level
    public func validateRiskLevel(riskLevel : Text) : ValidationResult {
        let validRiskLevels = ["Low", "Medium", "High"];
        let isValid = Array.find<Text>(validRiskLevels, func(level) = level == riskLevel);

        switch (isValid) {
            case null { #err("Risk level must be one of: Low, Medium, High") };
            case (?_) { #ok(()) };
        };
    };

    // Validate tags
    public func validateTags(tags : [Text]) : ValidationResult {
        if (tags.size() > 10) {
            return #err("Maximum 10 tags allowed");
        };

        for (tag in tags.vals()) {
            if (Text.size(tag) < 1) {
                return #err("Tags cannot be empty");
            };
            if (Text.size(tag) > 30) {
                return #err("Each tag must be less than 30 characters");
            };
        };
        #ok(());
    };

    // Validate project type (always valid since it's an enum)
    public func validateProjectType(projectType : ProjectType) : ValidationResult {
        #ok(());
    };

    // Validate complete project creation request
    public func validateProjectCreateRequest(request : ProjectCreateRequest) : ValidationResult {
        switch (validateProjectType(request.projectType)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateTitle(request.title)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateDescription(request.description)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateCategory(request.category)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateLocation(request.location)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateFundingGoal(request.fundingGoal)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateMinInvestment(request.minInvestment, request.fundingGoal)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateMaxInvestment(request.maxInvestment, request.fundingGoal, request.minInvestment)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateTimeline(request.timeline)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateExpectedROI(request.expectedROI)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateRiskLevel(request.riskLevel)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateTags(request.tags)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        #ok(());
    };

    // Validate project update request (same validation as create)
    public func validateProjectUpdateRequest(request : ProjectUpdateRequest) : ValidationResult {
        let createRequest : ProjectCreateRequest = {
            projectType = request.projectType;
            title = request.title;
            description = request.description;
            category = request.category;
            location = request.location;
            fundingGoal = request.fundingGoal;
            timeline = request.timeline;
            expectedROI = request.expectedROI;
            riskLevel = request.riskLevel;
            tags = request.tags;
            minInvestment = request.minInvestment;
            maxInvestment = request.maxInvestment;
            targetDate = request.targetDate;
        };
        validateProjectCreateRequest(createRequest);
    };
};
