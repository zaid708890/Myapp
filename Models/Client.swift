import Foundation

struct Client: Identifiable, Codable {
    var id = UUID()
    var name: String
    var company: String
    var companyDescription: String?
    var email: String
    var phone: String
    
    // Company details
    var companyAddress: Address
    var gstNumber: String?
    var taxIdentificationNumber: String?
    var registrationNumber: String?
    var website: String?
    var industry: String?
    
    // Contact persons information
    var contactPersons: [ContactPerson]
    
    // Projects
    var projects: [Project]
    
    init(name: String, company: String, email: String, phone: String, companyAddress: Address = Address()) {
        self.name = name
        self.company = company
        self.email = email
        self.phone = phone
        self.companyAddress = companyAddress
        self.contactPersons = []
        self.projects = []
    }
    
    var totalContractAmount: Double {
        return projects.reduce(0) { $0 + $1.contractAmount }
    }
    
    var totalPaidAmount: Double {
        return projects.reduce(0) { $0 + $1.totalPaidAmount }
    }
    
    var totalBalanceAmount: Double {
        return totalContractAmount - totalPaidAmount
    }
}

// Contact Person
struct ContactPerson: Identifiable, Codable {
    var id = UUID()
    var name: String
    var position: String
    var phone: String
    var email: String
    var isPrimary: Bool
    var notes: String?
}

struct Project: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var startDate: Date
    var endDate: Date?
    var contractAmount: Double
    var payments: [ProjectPayment]
    
    // Additional project details
    var projectManager: String?
    var contractReference: String?
    var contractDate: Date?
    var milestones: [ProjectMilestone]?
    var status: ProjectStatus
    
    init(name: String, description: String, startDate: Date, endDate: Date?, contractAmount: Double, payments: [ProjectPayment] = []) {
        self.name = name
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.contractAmount = contractAmount
        self.payments = payments
        self.status = .active
        self.milestones = []
    }
    
    var totalPaidAmount: Double {
        return payments.reduce(0) { $0 + $1.amount }
    }
    
    var balanceAmount: Double {
        return contractAmount - totalPaidAmount
    }
    
    var isCompleted: Bool {
        return status == .completed || (endDate != nil && Date() >= endDate!)
    }
}

// Project milestone
struct ProjectMilestone: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var dueDate: Date
    var amount: Double
    var isCompleted: Bool
    var completionDate: Date?
}

// Project status
enum ProjectStatus: String, Codable, CaseIterable {
    case proposed = "Proposed"
    case active = "Active"
    case onHold = "On Hold"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

struct ProjectPayment: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var date: Date
    var notes: String
    var paymentType: PaymentType
    var referenceNumber: String?
    var paymentMethod: PaymentMethod
    
    // New fields for tracking who handled the payment
    var receivedBy: String?
    var receivedFrom: String?
    var verifiedBy: String?
    var bankDetails: BankTransferDetails?
    var invoiceNumber: String?
    
    enum PaymentType: String, Codable, CaseIterable {
        case advance = "Advance"
        case milestone = "Milestone Payment"
        case final = "Final Payment"
    }
    
    enum PaymentMethod: String, Codable, CaseIterable {
        case cash = "Cash"
        case bankTransfer = "Bank Transfer"
        case check = "Check"
        case creditCard = "Credit Card"
        case onlinePayment = "Online Payment"
        case other = "Other"
    }
}

// Bank transfer details
struct BankTransferDetails: Codable {
    var bankName: String
    var accountNumber: String
    var transferDate: Date
    var branchCode: String?
    var swiftCode: String?
} 