import Foundation

struct SalarySlip: Identifiable, Codable {
    var id = UUID()
    var employeeName: String
    var position: String
    var period: DatePeriod
    var baseSalary: Double
    var bonuses: Double
    var deductions: Double
    var advances: Double
    var generatedDate: Date
    
    // Payment information
    var paymentMethod: String?
    var processedBy: String?
    var referenceNumber: String?
    var paymentDate: Date?
    var notes: String?
    
    var totalEarnings: Double {
        return baseSalary + bonuses
    }
    
    var totalDeductions: Double {
        return deductions + advances
    }
    
    var netSalary: Double {
        return totalEarnings - totalDeductions
    }
}

struct ClientStatement: Identifiable, Codable {
    var id = UUID()
    var clientName: String
    var company: String
    var period: DatePeriod
    var projectPayments: [ProjectPaymentSummary]
    var generatedDate: Date
    
    var totalAmount: Double {
        return projectPayments.reduce(0) { $0 + $1.amount }
    }
    
    var totalPaid: Double {
        return projectPayments.reduce(0) { $0 + $1.paidAmount }
    }
    
    var balanceDue: Double {
        return totalAmount - totalPaid
    }
}

struct ProjectPaymentSummary: Identifiable, Codable {
    var id = UUID()
    var projectName: String
    var contractAmount: Double
    var paidAmount: Double
    var payments: [PaymentRecord]
    
    var balance: Double {
        return contractAmount - paidAmount
    }
}

struct PaymentRecord: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var date: Date
    var type: String
}

struct DatePeriod: Codable, Hashable {
    var startDate: Date
    var endDate: Date
    
    var formattedString: String {
        return "\(Formatters.formatDate(startDate)) - \(Formatters.formatDate(endDate))"
    }
    
    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: startDate)
    }
} 