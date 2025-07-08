import Time "mo:base/Time";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";

import FarmerTypes "../types/FarmerTypes";
import Validation "../utils/Validation";
import FarmerStorage "../storage/FarmerStorage";

module {

    public class FarmerService(storage : FarmerStorage.FarmerStorage) {

        public func registerFarmer(
            farmerId : FarmerTypes.FarmerId,
            request : FarmerTypes.RegisterFarmerRequest,
        ) : FarmerTypes.FarmerRegistrationResult {

            // Check if farmer is already registered
            switch (storage.getFarmer(farmerId)) {
                case (?existingFarmer) {
                    return #AlreadyRegistered(farmerId);
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

            if (not Validation.isValidPhone(request.phoneNumber)) {
                return #InvalidData("Phone number must be between 10 and 15 digits");
            };

            if (not Validation.isValidGovernmentId(request.governmentId)) {
                return #InvalidData("Government ID must be between 5 and 50 characters");
            };

            // Check for duplicate email
            switch (storage.getFarmerByEmail(request.email)) {
                case (?existingFarmerId) {
                    return #InvalidData("Email address is already registered");
                };
                case null {};
            };

            // Check for duplicate government ID
            switch (storage.getFarmerByGovernmentId(request.governmentId)) {
                case (?existingFarmerId) {
                    return #InvalidData("Government ID is already registered");
                };
                case null {};
            };

            // Create farmer profile
            let farmerProfile : FarmerTypes.FarmerProfile = {
                farmerId = farmerId;
                fullName = request.fullName;
                email = request.email;
                phoneNumber = request.phoneNumber;
                governmentId = request.governmentId;
                registrationDate = Time.now();
                verificationStatus = #Pending;
                documents = [];
                isActive = true;
                lastUpdated = Time.now();
            };

            // Store farmer profile
            storage.putFarmer(farmerId, farmerProfile);

            Debug.print("New farmer registered: " # request.fullName # " (" # Principal.toText(farmerId) # ")");

            #Success(farmerId);
        };

        public func uploadDocument(
            farmerId : FarmerTypes.FarmerId,
            request : FarmerTypes.UploadDocumentRequest,
        ) : Result.Result<(), Text> {

            // Check if farmer is registered
            switch (storage.getFarmer(farmerId)) {
                case null {
                    return #err("Farmer not registered. Please register first.");
                };
                case (?farmer) {
                    // Validate file data
                    if (not Validation.isValidFileName(request.fileName)) {
                        return #err("Invalid file name");
                    };

                    if (not Validation.isValidFileHash(request.fileHash)) {
                        return #err("Invalid file hash");
                    };

                    // Create document record
                    let document : FarmerTypes.Document = {
                        documentType = request.documentType;
                        fileName = request.fileName;
                        fileHash = request.fileHash;
                        uploadedAt = Time.now();
                    };

                    // Add document to farmer's profile
                    let updatedDocuments = Array.append<FarmerTypes.Document>(farmer.documents, [document]);
                    let updatedFarmer : FarmerTypes.FarmerProfile = {
                        farmer with
                        documents = updatedDocuments;
                        lastUpdated = Time.now();
                    };

                    storage.updateFarmer(farmerId, updatedFarmer);

                    Debug.print("Document uploaded for farmer: " # Principal.toText(farmerId));
                    #ok(());
                };
            };
        };

        public func updateVerificationStatus(
            farmerId : FarmerTypes.FarmerId,
            newStatus : FarmerTypes.VerificationStatus,
        ) : Result.Result<(), Text> {

            switch (storage.getFarmer(farmerId)) {
                case null {
                    return #err("Farmer not found");
                };
                case (?farmer) {
                    let updatedFarmer : FarmerTypes.FarmerProfile = {
                        farmer with
                        verificationStatus = newStatus;
                        lastUpdated = Time.now();
                    };

                    storage.updateFarmer(farmerId, updatedFarmer);

                    Debug.print("Farmer verification status updated: " # Principal.toText(farmerId));
                    #ok(());
                };
            };
        };

        public func updateFarmerProfile(
            farmerId : FarmerTypes.FarmerId,
            fullName : ?Text,
            email : ?Text,
            phoneNumber : ?Text,
        ) : Result.Result<(), Text> {

            switch (storage.getFarmer(farmerId)) {
                case null {
                    return #err("Farmer not registered");
                };
                case (?farmer) {
                    var updatedFarmer = farmer;

                    // Update full name if provided
                    switch (fullName) {
                        case (?name) {
                            if (not Validation.isValidName(name)) {
                                return #err("Invalid full name");
                            };
                            updatedFarmer := {
                                updatedFarmer with fullName = name
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

                            // Check if email is already taken by another farmer
                            switch (storage.getFarmerByEmail(newEmail)) {
                                case (?existingFarmerId) {
                                    if (not Principal.equal(existingFarmerId, farmerId)) {
                                        return #err("Email already taken");
                                    };
                                };
                                case null {};
                            };

                            updatedFarmer := {
                                updatedFarmer with email = newEmail
                            };
                        };
                        case null {};
                    };

                    // Update phone number if provided
                    switch (phoneNumber) {
                        case (?phone) {
                            if (not Validation.isValidPhone(phone)) {
                                return #err("Invalid phone number");
                            };
                            updatedFarmer := {
                                updatedFarmer with phoneNumber = phone
                            };
                        };
                        case null {};
                    };

                    // Update last modified timestamp
                    updatedFarmer := {
                        updatedFarmer with lastUpdated = Time.now()
                    };

                    storage.updateFarmer(farmerId, updatedFarmer);

                    Debug.print("Farmer profile updated: " # Principal.toText(farmerId));
                    #ok(());
                };
            };
        };

        public func isFarmerVerified(farmerId : FarmerTypes.FarmerId) : Bool {
            switch (storage.getFarmer(farmerId)) {
                case null { false };
                case (?farmer) {
                    farmer.verificationStatus == #Approved and farmer.isActive
                };
            };
        };

        public func getFarmersByStatus(status : FarmerTypes.VerificationStatus) : [FarmerTypes.FarmerProfile] {
            let allFarmers = storage.getAllFarmers();
            Array.filter(
                allFarmers,
                func(farmer : FarmerTypes.FarmerProfile) : Bool {
                    farmer.verificationStatus == status;
                },
            );
        };

        public func getFarmerStats() : FarmerTypes.FarmerStats {
            let allFarmers = storage.getAllFarmers();

            let pendingFarmers = Array.filter(
                allFarmers,
                func(farmer : FarmerTypes.FarmerProfile) : Bool {
                    farmer.verificationStatus == #Pending;
                },
            );

            let approvedFarmers = Array.filter(
                allFarmers,
                func(farmer : FarmerTypes.FarmerProfile) : Bool {
                    farmer.verificationStatus == #Approved;
                },
            );

            let rejectedFarmers = Array.filter(
                allFarmers,
                func(farmer : FarmerTypes.FarmerProfile) : Bool {
                    farmer.verificationStatus == #Rejected;
                },
            );

            {
                totalFarmers = allFarmers.size();
                pendingVerification = pendingFarmers.size();
                approvedFarmers = approvedFarmers.size();
                rejectedFarmers = rejectedFarmers.size();
            };
        };
    };
};
