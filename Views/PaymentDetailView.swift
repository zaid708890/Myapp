import SwiftUI

struct PaymentDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    
    enum PaymentDetailType {
        case salaryAdvance(SalaryAdvance)
        case salaryPayment(SalaryPayment)
        case projectPayment(ProjectPayment)
    }
    
    let paymentType: PaymentDetailType
    let title: String
    
    init(paymentType: PaymentDetailType, title: String? = nil) {
        self.paymentType = paymentType
        switch paymentType {
        case .salaryAdvance:
            self.title = title ?? "Salary Advance Details"
        case .salaryPayment:
            self.title = title ?? "Salary Payment Details"
        case .projectPayment:
            self.title = title ?? "Project Payment Details"
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Common payment details
                Section(header: Text("Payment Information")) {
                    HStack {
                        Text("Amount")
                        Spacer()
                        Text(Formatters.formatCurrency(getAmount()))
                            .bold()
                    }
                    
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(Formatters.formatDate(getDate()))
                    }
                    
                    HStack {
                        Text("Payment Method")
                        Spacer()
                        Text(getPaymentMethod())
                    }
                    
                    if let reference = getReferenceNumber() {
                        HStack {
                            Text("Reference Number")
                            Spacer()
                            Text(reference)
                        }
                    }
                }
                
                // Payment-specific details
                switch paymentType {
                case .salaryAdvance(let advance):
                    Section(header: Text("Advance Details")) {
                        HStack {
                            Text("Reason")
                            Spacer()
                            Text(advance.reason)
                        }
                        
                        if !advance.processedBy.isEmpty {
                            HStack {
                                Text("Processed By")
                                Spacer()
                                Text(advance.processedBy)
                            }
                        }
                        
                        if let notes = advance.notes, !notes.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Notes:")
                                    .font(.headline)
                                Text(notes)
                                    .font(.body)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    
                case .salaryPayment(let payment):
                    Section(header: Text("Salary Details")) {
                        HStack {
                            Text("Period")
                            Spacer()
                            Text("\(Formatters.formatDate(payment.periodStart)) - \(Formatters.formatDate(payment.periodEnd))")
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("Bonuses")
                            Spacer()
                            Text(Formatters.formatCurrency(payment.bonuses))
                        }
                        
                        HStack {
                            Text("Deductions")
                            Spacer()
                            Text(Formatters.formatCurrency(payment.deductions))
                        }
                        
                        HStack {
                            Text("Net Amount")
                            Spacer()
                            Text(Formatters.formatCurrency(payment.amount))
                                .bold()
                        }
                        
                        if !payment.processedBy.isEmpty {
                            HStack {
                                Text("Processed By")
                                Spacer()
                                Text(payment.processedBy)
                            }
                        }
                        
                        if let notes = payment.notes, !notes.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Notes:")
                                    .font(.headline)
                                Text(notes)
                                    .font(.body)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    
                case .projectPayment(let payment):
                    Section(header: Text("Payment Details")) {
                        HStack {
                            Text("Payment Type")
                            Spacer()
                            Text(payment.paymentType.rawValue)
                        }
                        
                        if let invoiceNumber = payment.invoiceNumber, !invoiceNumber.isEmpty {
                            HStack {
                                Text("Invoice Number")
                                Spacer()
                                Text(invoiceNumber)
                            }
                        }
                        
                        if let receivedBy = payment.receivedBy, !receivedBy.isEmpty {
                            HStack {
                                Text("Received By")
                                Spacer()
                                Text(receivedBy)
                            }
                        }
                        
                        if let receivedFrom = payment.receivedFrom, !receivedFrom.isEmpty {
                            HStack {
                                Text("Received From")
                                Spacer()
                                Text(receivedFrom)
                            }
                        }
                        
                        if let verifiedBy = payment.verifiedBy, !verifiedBy.isEmpty {
                            HStack {
                                Text("Verified By")
                                Spacer()
                                Text(verifiedBy)
                            }
                        }
                        
                        if !payment.notes.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Notes:")
                                    .font(.headline)
                                Text(payment.notes)
                                    .font(.body)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    
                    // Bank transfer details if available
                    if let bankDetails = payment.bankDetails {
                        Section(header: Text("Bank Transfer Details")) {
                            HStack {
                                Text("Bank Name")
                                Spacer()
                                Text(bankDetails.bankName)
                            }
                            
                            HStack {
                                Text("Account Number")
                                Spacer()
                                Text(bankDetails.accountNumber)
                            }
                            
                            HStack {
                                Text("Transfer Date")
                                Spacer()
                                Text(Formatters.formatDate(bankDetails.transferDate))
                            }
                            
                            if let branchCode = bankDetails.branchCode, !branchCode.isEmpty {
                                HStack {
                                    Text("Branch Code")
                                    Spacer()
                                    Text(branchCode)
                                }
                            }
                            
                            if let swiftCode = bankDetails.swiftCode, !swiftCode.isEmpty {
                                HStack {
                                    Text("SWIFT Code")
                                    Spacer()
                                    Text(swiftCode)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // Helper functions to get common properties
    private func getAmount() -> Double {
        switch paymentType {
        case .salaryAdvance(let advance):
            return advance.amount
        case .salaryPayment(let payment):
            return payment.amount
        case .projectPayment(let payment):
            return payment.amount
        }
    }
    
    private func getDate() -> Date {
        switch paymentType {
        case .salaryAdvance(let advance):
            return advance.date
        case .salaryPayment(let payment):
            return payment.date
        case .projectPayment(let payment):
            return payment.date
        }
    }
    
    private func getPaymentMethod() -> String {
        switch paymentType {
        case .salaryAdvance(let advance):
            return advance.paymentMethod.rawValue
        case .salaryPayment(let payment):
            return payment.paymentMethod.rawValue
        case .projectPayment(let payment):
            return payment.paymentMethod.rawValue
        }
    }
    
    private func getReferenceNumber() -> String? {
        switch paymentType {
        case .salaryAdvance(let advance):
            return advance.referenceNumber
        case .salaryPayment(let payment):
            return payment.referenceNumber
        case .projectPayment(let payment):
            return payment.referenceNumber
        }
    }
}

struct PaymentDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PaymentDetailView(paymentType: .salaryAdvance(
                SalaryAdvance(
                    amount: 1000,
                    date: Date(),
                    reason: "Emergency expense",
                    paymentMethod: .bankTransfer,
                    processedBy: "John Manager",
                    referenceNumber: "ADV-001",
                    notes: "Approved due to medical emergency"
                )
            ))
            
            PaymentDetailView(paymentType: .salaryPayment(
                SalaryPayment(
                    amount: 5000,
                    date: Date(),
                    periodStart: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                    periodEnd: Date(),
                    bonuses: 500,
                    deductions: 200,
                    paymentMethod: .bankTransfer,
                    processedBy: "Jane HR",
                    referenceNumber: "SAL-001",
                    notes: "Monthly salary with performance bonus"
                )
            ))
            
            PaymentDetailView(paymentType: .projectPayment(
                ProjectPayment(
                    amount: 2500,
                    date: Date(),
                    notes: "Milestone payment for Phase 1",
                    paymentType: .milestone,
                    referenceNumber: "PMT-001",
                    paymentMethod: .bankTransfer,
                    receivedBy: "Finance Dept",
                    receivedFrom: "Client XYZ",
                    verifiedBy: "Project Manager",
                    bankDetails: BankTransferDetails(
                        bankName: "ABC Bank",
                        accountNumber: "1234567890",
                        transferDate: Date(),
                        branchCode: "ABC-123",
                        swiftCode: "ABCXYZ"
                    ),
                    invoiceNumber: "INV-2023-001"
                )
            ))
        }
    }
} 