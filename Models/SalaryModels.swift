import Foundation

struct SalaryAdvance: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var date: Date
    var reason: String
    var isPaid: Bool = false
}

struct SalaryPayment: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var date: Date
    var periodStart: Date
    var periodEnd: Date
    var deductions: Double = 0
    var bonuses: Double = 0
    var notes: String = ""
}

struct Leave: Identifiable, Codable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var reason: String
    var isPaid: Bool
    
    var durationInDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
}

struct DutyRecord: Identifiable, Codable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var notes: String = ""
    
    var durationInDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
} 