import Foundation

struct Formatters {
    // Date formatters
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter
    }()
    
    // Currency formatters
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$" // Default
        return formatter
    }()
    
    static func formatCurrency(_ amount: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    static func formatDate(_ date: Date) -> String {
        return shortDateFormatter.string(from: date)
    }
    
    static func formatFullDate(_ date: Date) -> String {
        return fullDateFormatter.string(from: date)
    }
    
    static func formatMonthYear(_ date: Date) -> String {
        return monthYearFormatter.string(from: date)
    }
    
    static func formatDateRange(from: Date, to: Date?) -> String {
        let fromStr = formatDate(from)
        if let toDate = to {
            let toStr = formatDate(toDate)
            return "\(fromStr) - \(toStr)"
        }
        return "\(fromStr) - Present"
    }
}

// Extension to color code amounts (positive/negative)
extension Double {
    var isPositive: Bool {
        return self >= 0
    }
    
    var formattedCurrency: String {
        return Formatters.formatCurrency(self)
    }
} 