import Foundation

struct Company: Identifiable, Codable {
    var id = UUID()
    var name: String
    var address: String
    var phone: String
    var email: String
    var logo: String? // Store path to logo image
    var isActive: Bool = true
    var createdDate: Date
    
    // References to data IDs - used to filter data belonging to this company
    var employeeIDs: [UUID] = []
    var clientIDs: [UUID] = []
    var salarySlipIDs: [UUID] = []
    var clientStatementIDs: [UUID] = []
    var expenseIDs: [UUID] = [] // Track expense IDs
    var expenseReportIDs: [UUID] = [] // Track expense report IDs
    
    init(name: String, address: String, phone: String, email: String) {
        self.name = name
        self.address = address
        self.phone = phone
        self.email = email
        self.createdDate = Date()
    }
} 