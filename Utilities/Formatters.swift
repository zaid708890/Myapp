import Foundation

struct Formatters {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    static func formatDateTime(_ date: Date) -> String {
        return dateTimeFormatter.string(from: date)
    }
    
    static func formatCurrency(_ amount: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    static func formatNumber(_ number: Double) -> String {
        return decimalFormatter.string(from: NSNumber(value: number)) ?? "0"
    }
    
    static func formatPercent(_ value: Double) -> String {
        return percentFormatter.string(from: NSNumber(value: value)) ?? "0%"
    }
    
    static func formatDateRange(_ startDate: Date, _ endDate: Date) -> String {
        return "\(formatDate(startDate)) - \(formatDate(endDate))"
    }
    
    static func formatPhoneNumber(_ phoneNumber: String) -> String {
        // Basic phone formatting
        let digitsOnly = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if digitsOnly.count == 10 {
            let area = digitsOnly.prefix(3)
            let prefix = digitsOnly.dropFirst(3).prefix(3)
            let number = digitsOnly.dropFirst(6)
            return "(\(area)) \(prefix)-\(number)"
        } else {
            return phoneNumber
        }
    }
    
    static func formatGSTNumber(_ gstNumber: String) -> String {
        // Basic GST number formatting (depending on your country's format)
        return gstNumber.uppercased()
    }
} 