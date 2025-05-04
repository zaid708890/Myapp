import Foundation

struct Employee: Identifiable, Codable {
    var id = UUID()
    var name: String
    var gender: Gender
    var dateOfBirth: Date?
    var position: String
    var monthlySalary: Double
    var joinDate: Date
    
    // Contact information
    var email: String
    var phone: String
    var alternatePhone: String?
    
    // Address information
    var address: Address
    
    // Additional details
    var emergencyContact: EmergencyContact?
    var identifications: [Identification]
    
    // For tracking salary advances and balances
    var salaryAdvances: [SalaryAdvance]
    var salaryHistory: [SalaryPayment]
    
    // For tracking duty days and leaves
    var leaves: [Leave]
    var dutyRecords: [DutyRecord]
    
    init(name: String, gender: Gender = .notSpecified, position: String, monthlySalary: Double, joinDate: Date,
         email: String = "", phone: String = "", address: Address = Address()) {
        self.name = name
        self.gender = gender
        self.position = position
        self.monthlySalary = monthlySalary
        self.joinDate = joinDate
        self.email = email
        self.phone = phone
        self.address = address
        self.identifications = []
        self.salaryAdvances = []
        self.salaryHistory = []
        self.leaves = []
        self.dutyRecords = []
    }
    
    var totalSalaryAdvance: Double {
        return salaryAdvances.reduce(0) { $0 + $1.amount }
    }
    
    var totalSalaryPaid: Double {
        return salaryHistory.reduce(0) { $0 + $1.amount }
    }
    
    var currentSalaryBalance: Double {
        let totalEarned = calculateTotalEarnedSalary()
        return totalEarned - totalSalaryPaid - totalSalaryAdvance
    }
    
    private func calculateTotalEarnedSalary() -> Double {
        // Calculate salary based on join date, current date, and leaves
        // This is a simplified calculation
        guard let totalMonths = Calendar.current.dateComponents([.month], 
                                                from: joinDate, 
                                                to: Date()).month else {
            return 0
        }
        
        return Double(totalMonths) * monthlySalary
    }
}

// Gender enumeration
enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case notSpecified = "Not Specified"
}

// Address structure
struct Address: Codable {
    var street: String = ""
    var city: String = ""
    var state: String = ""
    var postalCode: String = ""
    var country: String = ""
    
    var formattedAddress: String {
        var components: [String] = []
        if !street.isEmpty { components.append(street) }
        if !city.isEmpty { components.append(city) }
        if !state.isEmpty { components.append(state) }
        if !postalCode.isEmpty { components.append(postalCode) }
        if !country.isEmpty { components.append(country) }
        
        return components.joined(separator: ", ")
    }
}

// Emergency Contact
struct EmergencyContact: Codable {
    var name: String
    var relationship: String
    var phone: String
    var email: String?
}

// Identification documents
struct Identification: Identifiable, Codable {
    var id = UUID()
    var type: IdentificationType
    var documentNumber: String
    var issuedDate: Date?
    var expiryDate: Date?
    
    enum IdentificationType: String, Codable, CaseIterable {
        case passport = "Passport"
        case drivingLicense = "Driving License"
        case nationalID = "National ID"
        case socialSecurity = "Social Security"
        case other = "Other"
    }
}

// Payment method enumeration - for tracking how payments are made
enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "Cash"
    case bankTransfer = "Bank Transfer"
    case check = "Check"
    case wallet = "Digital Wallet"
    case creditCard = "Credit Card"
    case other = "Other"
}

// Structure for tracking salary advances
struct SalaryAdvance: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var date: Date
    var reason: String
    var paymentMethod: PaymentMethod = .bankTransfer
    var processedBy: String = ""
    var referenceNumber: String?
    var notes: String?
}

// Structure for tracking salary payments
struct SalaryPayment: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var date: Date
    var periodStart: Date
    var periodEnd: Date
    var bonuses: Double = 0
    var deductions: Double = 0
    var paymentMethod: PaymentMethod = .bankTransfer
    var processedBy: String = ""
    var referenceNumber: String?
    var notes: String?
}

// Structure for tracking employee leaves
struct Leave: Identifiable, Codable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var reason: String
    var isPaid: Bool
    var approvedBy: String?
    var notes: String?
}

// Structure for tracking duty records
struct DutyRecord: Identifiable, Codable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var notes: String?
    var overtime: Double = 0 // Hours of overtime
    var verifiedBy: String?
} 