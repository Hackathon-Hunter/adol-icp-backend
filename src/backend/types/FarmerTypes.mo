import Principal "mo:base/Principal";

module {
    public type FarmerId = Principal;

    public type VerificationStatus = {
        #Pending;
        #InReview;
        #Approved;
        #Rejected;
    };

    public type DocumentType = {
        #GovernmentID;
        #SelfiePhoto;
        #LandCertificate;
        #BusinessLicense;
    };

    public type Document = {
        documentType : DocumentType;
        fileName : Text;
        fileHash : Text;
        uploadedAt : Int;
    };

    public type FarmerProfile = {
        farmerId : FarmerId;
        fullName : Text;
        email : Text;
        phoneNumber : Text;
        governmentId : Text;
        registrationDate : Int;
        verificationStatus : VerificationStatus;
        documents : [Document];
        isActive : Bool;
        lastUpdated : Int;
    };

    public type RegisterFarmerRequest = {
        fullName : Text;
        email : Text;
        phoneNumber : Text;
        governmentId : Text;
    };

    public type UploadDocumentRequest = {
        documentType : DocumentType;
        fileName : Text;
        fileHash : Text;
    };

    public type FarmerRegistrationResult = {
        #Success : FarmerId;
        #AlreadyRegistered : FarmerId;
        #InvalidData : Text;
        #Error : Text;
    };

    public type FarmerStats = {
        totalFarmers : Nat;
        pendingVerification : Nat;
        approvedFarmers : Nat;
        rejectedFarmers : Nat;
    };
};
