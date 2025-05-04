import SwiftUI

// Generic payment protocol to allow display of different payment types
protocol PaymentDisplayable {
    var id: UUID { get }
    var amount: Double { get }
    var date: Date { get }
    var paymentMethodString: String { get }
    var referenceNumber: String? { get }
    var processorName: String? { get }
}

// Extension to make SalaryAdvance conform to PaymentDisplayable
extension SalaryAdvance: PaymentDisplayable {
    var paymentMethodString: String {
        return paymentMethod.rawValue
    }
    
    var processorName: String? {
        return processedBy.isEmpty ? nil : processedBy
    }
}

// Extension to make SalaryPayment conform to PaymentDisplayable
extension SalaryPayment: PaymentDisplayable {
    var paymentMethodString: String {
        return paymentMethod.rawValue
    }
    
    var processorName: String? {
        return processedBy.isEmpty ? nil : processedBy
    }
}

// Extension to make ProjectPayment conform to PaymentDisplayable
extension ProjectPayment: PaymentDisplayable {
    var paymentMethodString: String {
        return paymentMethod.rawValue
    }
    
    var processorName: String? {
        return receivedBy
    }
}

struct PaymentHistoryView<T: PaymentDisplayable>: View {
    let payments: [T]
    let title: String
    let emptyMessage: String
    let onSelect: ((T) -> Void)?
    
    init(payments: [T], title: String = "Payment History", emptyMessage: String = "No payment records found", onSelect: ((T) -> Void)? = nil) {
        self.payments = payments
        self.title = title
        self.emptyMessage = emptyMessage
        self.onSelect = onSelect
    }
    
    var body: some View {
        Section(header: Text(title)) {
            if payments.isEmpty {
                Text(emptyMessage)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(payments, id: \.id) { payment in
                    paymentRow(for: payment)
                }
            }
        }
    }
    
    private func paymentRow(for payment: T) -> some View {
        Button(action: {
            if let onSelect = onSelect {
                onSelect(payment)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(Formatters.formatCurrency(payment.amount))
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(Formatters.formatDate(payment.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Method: \(payment.paymentMethodString)")
                        .font(.caption)
                    
                    if let reference = payment.referenceNumber, !reference.isEmpty {
                        Text("Ref: \(reference)")
                            .font(.caption)
                    }
                    
                    if let processor = payment.processorName, !processor.isEmpty {
                        Text("Processed by: \(processor)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if onSelect != nil {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Specialized view for salary advances
struct SalaryAdvanceHistoryView: View {
    let advances: [SalaryAdvance]
    let onSelect: ((SalaryAdvance) -> Void)?
    
    var body: some View {
        PaymentHistoryView(
            payments: advances,
            title: "Salary Advances",
            emptyMessage: "No salary advances found",
            onSelect: onSelect
        )
    }
}

// Specialized view for salary payments
struct SalaryPaymentHistoryView: View {
    let payments: [SalaryPayment]
    let onSelect: ((SalaryPayment) -> Void)?
    
    var body: some View {
        PaymentHistoryView(
            payments: payments,
            title: "Salary Payments",
            emptyMessage: "No salary payments found",
            onSelect: onSelect
        )
    }
}

// Specialized view for project payments
struct ProjectPaymentHistoryView: View {
    let payments: [ProjectPayment]
    let onSelect: ((ProjectPayment) -> Void)?
    
    var body: some View {
        PaymentHistoryView(
            payments: payments,
            title: "Project Payments",
            emptyMessage: "No project payments found",
            onSelect: onSelect
        )
    }
}

// Preview
struct PaymentHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            SalaryAdvanceHistoryView(
                advances: [
                    SalaryAdvance(
                        amount: 1000,
                        date: Date(),
                        reason: "Emergency",
                        paymentMethod: .bankTransfer,
                        processedBy: "John Manager",
                        referenceNumber: "ADV-001"
                    )
                ],
                onSelect: nil
            )
            
            SalaryPaymentHistoryView(
                payments: [
                    SalaryPayment(
                        amount: 5000,
                        date: Date(),
                        periodStart: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                        periodEnd: Date(),
                        bonuses: 500,
                        deductions: 200,
                        paymentMethod: .bankTransfer,
                        processedBy: "Jane HR",
                        referenceNumber: "SAL-001"
                    )
                ],
                onSelect: nil
            )
        }
        .listStyle(InsetGroupedListStyle())
    }
} 