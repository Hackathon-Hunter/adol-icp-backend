import Text "mo:base/Text";
import Array "mo:base/Array";
import Float "mo:base/Float";
import ProjectTypes "../types/ProjectTypes";

module ProjectValidation {

    type ProjectCreateRequest = ProjectTypes.ProjectCreateRequest;
    type ProjectUpdateRequest = ProjectTypes.ProjectUpdateRequest;
    type ValidationResult = ProjectTypes.ValidationResult;
    type ProjectType = ProjectTypes.ProjectType;
    type Industry = ProjectTypes.Industry;
    type TeamMember = ProjectTypes.TeamMember;
    type UseOfFunds = ProjectTypes.UseOfFunds;
    type Milestone = ProjectTypes.Milestone;

    // Validate company name
    public func validateCompanyName(name : Text) : ValidationResult {
        if (Text.size(name) < 2) {
            return #err("Company name must be at least 2 characters");
        };
        if (Text.size(name) > 100) {
            return #err("Company name must be less than 100 characters");
        };
        #ok(());
    };

    // Validate company tagline
    public func validateCompanyTagline(tagline : Text) : ValidationResult {
        if (Text.size(tagline) < 10) {
            return #err("Company tagline must be at least 10 characters");
        };
        if (Text.size(tagline) > 200) {
            return #err("Company tagline must be less than 200 characters");
        };
        #ok(());
    };

    // Validate website URL
    public func validateWebsite(website : ?Text) : ValidationResult {
        switch (website) {
            case null { #ok(()) }; // Optional field
            case (?url) {
                if (Text.size(url) < 8) {
                    return #err("Website URL must be at least 8 characters");
                };
                if (Text.size(url) > 500) {
                    return #err("Website URL must be less than 500 characters");
                };
                if (not (Text.startsWith(url, #text "https://") or Text.startsWith(url, #text "http://"))) {
                    return #err("Website URL must start with http:// or https://");
                };
                #ok(());
            };
        };
    };

    // Validate company logo URL
    public func validateCompanyLogo(logo : ?Text) : ValidationResult {
        switch (logo) {
            case null { #ok(()) }; // Optional field
            case (?url) {
                if (Text.size(url) < 8) {
                    return #err("Company logo URL must be at least 8 characters");
                };
                if (Text.size(url) > 500) {
                    return #err("Company logo URL must be less than 500 characters");
                };
                if (not (Text.startsWith(url, #text "https://") or Text.startsWith(url, #text "http://"))) {
                    return #err("Company logo URL must start with http:// or https://");
                };
                #ok(());
            };
        };
    };

    // Validate problem statement
    public func validateProblem(problem : Text) : ValidationResult {
        if (Text.size(problem) < 50) {
            return #err("Problem statement must be at least 50 characters");
        };
        if (Text.size(problem) > 2000) {
            return #err("Problem statement must be less than 2000 characters");
        };
        #ok(());
    };

    // Validate solution description
    public func validateSolution(solution : Text) : ValidationResult {
        if (Text.size(solution) < 50) {
            return #err("Solution description must be at least 50 characters");
        };
        if (Text.size(solution) > 2000) {
            return #err("Solution description must be less than 2000 characters");
        };
        #ok(());
    };

    // Validate market opportunity
    public func validateMarketOpportunity(marketOpportunity : Text) : ValidationResult {
        if (Text.size(marketOpportunity) < 50) {
            return #err("Market opportunity must be at least 50 characters");
        };
        if (Text.size(marketOpportunity) > 2000) {
            return #err("Market opportunity must be less than 2000 characters");
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
        if (fundingGoal < 500000) {
            // Minimum $5,000
            return #err("Funding goal must be at least $5,000");
        };
        if (fundingGoal > 500000000000) {
            // Maximum $5,000,000
            return #err("Funding goal must be less than $5,000,000");
        };
        #ok(());
    };

    // Validate company valuation
    public func validateCompanyValuation(valuation : Nat, fundingGoal : Nat) : ValidationResult {
        if (valuation < fundingGoal) {
            return #err("Company valuation must be greater than funding goal");
        };
        if (valuation < 100000) {
            // Minimum $1,000
            return #err("Company valuation must be at least $1,000");
        };
        if (valuation > 100000000000000) {
            // Maximum $1,000,000,000
            return #err("Company valuation must be less than $1,000,000,000");
        };
        #ok(());
    };

    // Validate minimum funding
    public func validateMinimumFunding(minFunding : Nat, fundingGoal : Nat) : ValidationResult {
        if (minFunding < 100000) {
            // Minimum $1,000
            return #err("Minimum funding must be at least $1,000");
        };
        if (minFunding > fundingGoal) {
            return #err("Minimum funding cannot exceed funding goal");
        };
        if (minFunding > (fundingGoal * 80 / 100)) {
            // Max 80% of funding goal
            return #err("Minimum funding should not exceed 80% of funding goal");
        };
        #ok(());
    };

    // Validate minimum investment
    public func validateMinInvestment(minInvestment : Nat, fundingGoal : Nat) : ValidationResult {
        if (minInvestment < 10000) {
            // Minimum $100
            return #err("Minimum investment must be at least $100");
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

    // Validate team members
    public func validateTeamMembers(teamMembers : [TeamMember]) : ValidationResult {
        if (teamMembers.size() == 0) {
            return #err("At least one team member is required");
        };
        if (teamMembers.size() > 20) {
            return #err("Maximum 20 team members allowed");
        };

        for (member in teamMembers.vals()) {
            if (Text.size(member.name) < 2) {
                return #err("Team member name must be at least 2 characters");
            };
            if (Text.size(member.name) > 100) {
                return #err("Team member name must be less than 100 characters");
            };
            if (Text.size(member.role) < 2) {
                return #err("Team member role must be at least 2 characters");
            };
            if (Text.size(member.role) > 100) {
                return #err("Team member role must be less than 100 characters");
            };

            // Validate optional bio
            switch (member.bio) {
                case null { /* OK */ };
                case (?bio) {
                    if (Text.size(bio) > 500) {
                        return #err("Team member bio must be less than 500 characters");
                    };
                };
            };

            // Validate optional LinkedIn URL
            switch (member.linkedinUrl) {
                case null { /* OK */ };
                case (?url) {
                    if (Text.size(url) > 300) {
                        return #err("LinkedIn URL must be less than 300 characters");
                    };
                    if (not Text.contains(url, #text "linkedin.com")) {
                        return #err("Invalid LinkedIn URL format");
                    };
                };
            };

            // Validate optional image URL
            switch (member.imageUrl) {
                case null { /* OK */ };
                case (?url) {
                    if (Text.size(url) > 500) {
                        return #err("Team member image URL must be less than 500 characters");
                    };
                    if (not (Text.startsWith(url, #text "https://") or Text.startsWith(url, #text "http://"))) {
                        return #err("Team member image URL must start with http:// or https://");
                    };
                };
            };
        };
        #ok(());
    };

    // Validate use of funds
    public func validateUseOfFunds(useOfFunds : [UseOfFunds], fundingGoal : Nat) : ValidationResult {
        if (useOfFunds.size() == 0) {
            return #err("At least one use of funds category is required");
        };
        if (useOfFunds.size() > 15) {
            return #err("Maximum 15 use of funds categories allowed");
        };

        var totalAmount : Nat = 0;
        var totalPercentage : Float = 0.0;

        for (fund in useOfFunds.vals()) {
            if (Text.size(fund.category) < 2) {
                return #err("Use of funds category must be at least 2 characters");
            };
            if (Text.size(fund.category) > 50) {
                return #err("Use of funds category must be less than 50 characters");
            };
            if (Text.size(fund.description) < 5) {
                return #err("Use of funds description must be at least 5 characters");
            };
            if (Text.size(fund.description) > 200) {
                return #err("Use of funds description must be less than 200 characters");
            };
            if (fund.amount == 0) {
                return #err("Use of funds amount must be greater than 0");
            };
            if (fund.percentage < 0.0 or fund.percentage > 100.0) {
                return #err("Use of funds percentage must be between 0 and 100");
            };

            totalAmount += fund.amount;
            totalPercentage += fund.percentage;
        };

        // Check total amounts
        if (totalAmount > fundingGoal * 110 / 100) {
            // Allow 10% buffer for rounding
            return #err("Total use of funds amount exceeds funding goal");
        };
        if (totalPercentage > 105.0 or totalPercentage < 95.0) {
            // Allow 5% buffer for rounding
            return #err("Total use of funds percentage should be approximately 100%");
        };

        #ok(());
    };

    // Validate milestones
    public func validateMilestones(milestones : [Milestone]) : ValidationResult {
        if (milestones.size() > 20) {
            return #err("Maximum 20 milestones allowed");
        };

        for (milestone in milestones.vals()) {
            if (Text.size(milestone.title) < 3) {
                return #err("Milestone title must be at least 3 characters");
            };
            if (Text.size(milestone.title) > 100) {
                return #err("Milestone title must be less than 100 characters");
            };
            if (Text.size(milestone.description) < 10) {
                return #err("Milestone description must be at least 10 characters");
            };
            if (Text.size(milestone.description) > 500) {
                return #err("Milestone description must be less than 500 characters");
            };
        };
        #ok(());
    };

    // Validate pitch deck URL
    public func validatePitchDeckUrl(pitchDeckUrl : ?Text) : ValidationResult {
        switch (pitchDeckUrl) {
            case null { #ok(()) }; // Optional field
            case (?url) {
                if (Text.size(url) < 8) {
                    return #err("Pitch deck URL must be at least 8 characters");
                };
                if (Text.size(url) > 500) {
                    return #err("Pitch deck URL must be less than 500 characters");
                };
                if (not (Text.startsWith(url, #text "https://") or Text.startsWith(url, #text "http://"))) {
                    return #err("Pitch deck URL must start with http:// or https://");
                };
                #ok(());
            };
        };
    };

    // Validate demo video URL
    public func validateDemoVideoUrl(demoVideoUrl : ?Text) : ValidationResult {
        switch (demoVideoUrl) {
            case null { #ok(()) }; // Optional field
            case (?url) {
                if (Text.size(url) < 8) {
                    return #err("Demo video URL must be at least 8 characters");
                };
                if (Text.size(url) > 500) {
                    return #err("Demo video URL must be less than 500 characters");
                };
                if (not (Text.startsWith(url, #text "https://") or Text.startsWith(url, #text "http://"))) {
                    return #err("Demo video URL must start with http:// or https://");
                };
                #ok(());
            };
        };
    };

    // Validate product images
    public func validateProductImages(productImages : [Text]) : ValidationResult {
        if (productImages.size() > 10) {
            return #err("Maximum 10 product images allowed");
        };

        for (imageUrl in productImages.vals()) {
            if (Text.size(imageUrl) < 8) {
                return #err("Product image URL must be at least 8 characters");
            };
            if (Text.size(imageUrl) > 500) {
                return #err("Product image URL must be less than 500 characters");
            };
            if (not (Text.startsWith(imageUrl, #text "https://") or Text.startsWith(imageUrl, #text "http://"))) {
                return #err("Product image URL must start with http:// or https://");
            };
        };
        #ok(());
    };

    // Validate legal structure
    public func validateLegalStructure(legalStructure : ?Text) : ValidationResult {
        switch (legalStructure) {
            case null { #ok(()) }; // Optional field
            case (?structure) {
                if (Text.size(structure) < 2) {
                    return #err("Legal structure must be at least 2 characters");
                };
                if (Text.size(structure) > 50) {
                    return #err("Legal structure must be less than 50 characters");
                };
                #ok(());
            };
        };
    };

    // Validate jurisdiction
    public func validateJurisdiction(jurisdiction : ?Text) : ValidationResult {
        switch (jurisdiction) {
            case null { #ok(()) }; // Optional field
            case (?jur) {
                if (Text.size(jur) < 2) {
                    return #err("Jurisdiction must be at least 2 characters");
                };
                if (Text.size(jur) > 100) {
                    return #err("Jurisdiction must be less than 100 characters");
                };
                #ok(());
            };
        };
    };

    // Validate project type (always valid since it's an enum)
    public func validateProjectType(_projectType : ProjectType) : ValidationResult {
        #ok(());
    };

    // Validate industry (always valid since it's an enum)
    public func validateIndustry(_industry : Industry) : ValidationResult {
        #ok(());
    };

    // Validate complete project creation request
    public func validateProjectCreateRequest(request : ProjectCreateRequest) : ValidationResult {
        // Company Information
        switch (validateCompanyName(request.companyName)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateCompanyTagline(request.companyTagline)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateWebsite(request.website)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateCompanyLogo(request.companyLogo)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        // Classification
        switch (validateProjectType(request.projectType)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateIndustry(request.industry)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateLocation(request.location)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        // Business Description
        switch (validateProblem(request.problem)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateSolution(request.solution)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateMarketOpportunity(request.marketOpportunity)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        // Financial Information
        switch (validateFundingGoal(request.fundingGoal)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateCompanyValuation(request.companyValuation, request.fundingGoal)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateMinimumFunding(request.minimumFunding, request.fundingGoal)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateUseOfFunds(request.useOfFunds, request.fundingGoal)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        // Team and Milestones
        switch (validateTeamMembers(request.teamMembers)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateMilestones(request.milestones)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        // Media and Documentation
        switch (validatePitchDeckUrl(request.pitchDeckUrl)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateDemoVideoUrl(request.demoVideoUrl)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateProductImages(request.productImages)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        // Investment Information
        switch (validateMinInvestment(request.minInvestment, request.fundingGoal)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateMaxInvestment(request.maxInvestment, request.fundingGoal, request.minInvestment)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        // Project Metadata
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

        // Legal and Compliance
        switch (validateLegalStructure(request.legalStructure)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        switch (validateJurisdiction(request.jurisdiction)) {
            case (#err(error)) { return #err(error) };
            case (#ok(())) {};
        };

        #ok(());
    };

    // Validate project update request (same validation as create)
    public func validateProjectUpdateRequest(request : ProjectUpdateRequest) : ValidationResult {
        let createRequest : ProjectCreateRequest = {
            companyName = request.companyName;
            companyTagline = request.companyTagline;
            website = request.website;
            companyLogo = request.companyLogo;
            projectType = request.projectType;
            industry = request.industry;
            location = request.location;
            problem = request.problem;
            solution = request.solution;
            marketOpportunity = request.marketOpportunity;
            fundingGoal = request.fundingGoal;
            companyValuation = request.companyValuation;
            minimumFunding = request.minimumFunding;
            useOfFunds = request.useOfFunds;
            milestones = request.milestones;
            teamMembers = request.teamMembers;
            pitchDeckUrl = request.pitchDeckUrl;
            demoVideoUrl = request.demoVideoUrl;
            productImages = request.productImages;
            tags = request.tags;
            timeline = request.timeline;
            expectedROI = request.expectedROI;
            riskLevel = request.riskLevel;
            minInvestment = request.minInvestment;
            maxInvestment = request.maxInvestment;
            targetDate = request.targetDate;
            legalStructure = request.legalStructure;
            jurisdiction = request.jurisdiction;
        };
        validateProjectCreateRequest(createRequest);
    };
};
