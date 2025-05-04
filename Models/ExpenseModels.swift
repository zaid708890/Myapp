import Foundation
import SwiftUI

// Expense categories
enum ExpenseCategory: String, Codable, CaseIterable {
    case travel = "Travel"
    case accommodation = "Accommodation"
    case meals = "Meals"
    case equipment = "Equipment"
    case supplies = "Supplies"
    case transportation = "Transportation"
    case clientMeeting = "Client Meeting"
    case marketing = "Marketing"
    case software = "Software"
    case training = "Training"
    case other = "Other"
}

// Status of expense
enum ExpenseStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case approved = "Approved"
    case reimbursed = "Reimbursed"
    case rejected = "Rejected"
}

// Model for tracking expenses
struct CompanyExpense: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var amount: Double
    var category: ExpenseCategory
    var date: Date
    var paidBy: String  // Name of the person who paid
    var paidByEmployeeID: UUID  // ID of the employee who paid
    var approvedBy: String?
    var status: ExpenseStatus = .pending
    var reimbursementDate: Date?
    var attachmentURLs: [String] = []  // URLs to receipts or other documents
    var notes: String?
    
    // Payment details
    var paymentMethod: PaymentMethod
    var referenceNumber: String?
}

// Model for tracking Expense Reports
struct ExpenseReport: Identifiable, Codable {
    var id = UUID()
    var title: String
    var period: DatePeriod
    var employeeID: UUID
    var employeeName: String
    var expenseIDs: [UUID] = []
    var totalAmount: Double
    var status: ExpenseStatus = .pending
    var submissionDate: Date
    var approvalDate: Date?
    var approvedBy: String?
    var reimbursementDate: Date?
    var reimbursementMethod: PaymentMethod?
    var reimbursementReferenceNumber: String?
    var notes: String?
}

// Extension for formatting
extension CompanyExpense {
    var formattedAmount: String {
        return Formatters.formatCurrency(amount)
    }
    
    var formattedDate: String {
        return Formatters.formatDate(date)
    }
    
    var statusColor: Color {
        switch status {
        case .pending:
            return .yellow
        case .approved:
            return .blue
        case .reimbursed:
            return .green
        case .rejected:
            return .red
        }
    }
}

// Extension for formatting
extension ExpenseReport {
    var formattedTotalAmount: String {
        return Formatters.formatCurrency(totalAmount)
    }
    
    var formattedSubmissionDate: String {
        return Formatters.formatDate(submissionDate)
    }
    
    var statusColor: Color {
        switch status {
        case .pending:
            return .yellow
        case .approved:
            return .blue
        case .reimbursed:
            return .green
        case .rejected:
            return .red
        }
    }
} 