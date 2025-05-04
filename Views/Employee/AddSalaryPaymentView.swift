import SwiftUI

struct AddSalaryPaymentView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var periodStart: Date = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
    @State private var periodEnd: Date = Date()
    @State private var deductions: String = "0"
    @State private var bonuses: String = "0"
    @State private var notes: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var paymentMethod: PaymentMethod = .bankTransfer
    @State private var referenceNumber: String = ""
    @State private var processedBy: String = ""
    @State private var trackAsExpense: Bool = true // Default to tracking as expense
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Payment Details")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Payment Date", selection: $date, displayedComponents: .date)
                    
                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    
                    TextField("Reference Number", text: $referenceNumber)
                    
                    TextField("Processed By", text: $processedBy)
                }
                
                Section(header: Text("Payment Period")) {
                    DatePicker("Start Date", selection: $periodStart, displayedComponents: .date)
                    DatePicker("End Date", selection: $periodEnd, displayedComponents: .date)
                }
                
                Section(header: Text("Additional")) {
                    TextField("Deductions", text: $deductions)
                        .keyboardType(.decimalPad)
                    
                    TextField("Bonuses", text: $bonuses)
                        .keyboardType(.decimalPad)
                    
                    TextField("Notes", text: $notes)
                }
                
                Section(header: Text("Expense Tracking")) {
                    Toggle("Track as Company Expense", isOn: $trackAsExpense)
                    
                    if trackAsExpense {
                        Text("This payment will be recorded as a company expense")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("New Salary Payment")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    savePayment()
                }
                .disabled(amount.isEmpty)
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func savePayment() {
        guard let paymentAmount = Double(amount) else {
            alertMessage = "Please enter a valid amount"
            showAlert = true
            return
        }
        
        guard paymentAmount > 0 else {
            alertMessage = "Amount must be greater than zero"
            showAlert = true
            return
        }
        
        let deductionAmount = Double(deductions) ?? 0
        let bonusAmount = Double(bonuses) ?? 0
        
        if trackAsExpense {
            // Use the enhanced method with expense tracking
            dataManager.addSalaryPaymentWithAccountTracking(
                amount: paymentAmount,
                date: date,
                periodStart: periodStart,
                periodEnd: periodEnd,
                bonuses: bonusAmount,
                deductions: deductionAmount,
                paymentMethod: paymentMethod,
                processedBy: processedBy,
                paidFromPersonalFunds: true, // Indicate this was paid from personal funds
                referenceNumber: referenceNumber.isEmpty ? nil : referenceNumber,
                notes: notes.isEmpty ? nil : notes
            )
        } else {
            // Use the existing method without expense tracking
            dataManager.addSalaryPayment(
                amount: paymentAmount,
                date: date,
                periodStart: periodStart,
                periodEnd: periodEnd,
                bonuses: bonusAmount,
                deductions: deductionAmount,
                paymentMethod: paymentMethod,
                processedBy: processedBy,
                referenceNumber: referenceNumber.isEmpty ? nil : referenceNumber,
                notes: notes.isEmpty ? nil : notes
            )
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddSalaryPaymentView_Previews: PreviewProvider {
    static var previews: some View {
        AddSalaryPaymentView()
            .environmentObject(DataManager())
    }
} 