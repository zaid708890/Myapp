import SwiftUI

struct EmployeePaymentView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var isAdvance: Bool = false
    @State private var reason: String = ""
    @State private var paymentMethod: PaymentMethod = .bankTransfer
    @State private var processedBy: String = ""
    @State private var referenceNumber: String = ""
    @State private var notes: String = ""
    
    // For salary payment
    @State private var periodStart: Date = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
    @State private var periodEnd: Date = Date()
    @State private var bonuses: String = ""
    @State private var deductions: String = ""
    
    // Alert state
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Payment Type")) {
                    Toggle("Salary Advance", isOn: $isAdvance)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                Section(header: Text("Payment Details")) {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    if isAdvance {
                        TextField("Reason for Advance", text: $reason)
                    } else {
                        DatePicker("Period Start", selection: $periodStart, displayedComponents: .date)
                        DatePicker("Period End", selection: $periodEnd, displayedComponents: .date)
                        
                        HStack {
                            Text("Bonuses")
                            Spacer()
                            TextField("0.00", text: $bonuses)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Deductions")
                            Spacer()
                            TextField("0.00", text: $deductions)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                
                Section(header: Text("Payment Method")) {
                    Picker("Method", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    TextField("Processed By", text: $processedBy)
                    
                    TextField("Reference Number", text: $referenceNumber)
                    
                    TextField("Notes", text: $notes)
                        .lineLimit(3)
                }
                
                Section {
                    Button(action: processPayment) {
                        Text(isAdvance ? "Add Salary Advance" : "Add Salary Payment")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(amount.isEmpty || (isAdvance && reason.isEmpty))
                }
            }
            .navigationTitle(isAdvance ? "Salary Advance" : "Salary Payment")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func processPayment() {
        guard let amountValue = Double(amount) else {
            alertTitle = "Invalid Amount"
            alertMessage = "Please enter a valid amount."
            showAlert = true
            return
        }
        
        if isAdvance {
            // Process as salary advance
            if reason.isEmpty {
                alertTitle = "Missing Information"
                alertMessage = "Please provide a reason for the advance."
                showAlert = true
                return
            }
            
            dataManager.addSalaryAdvance(
                amount: amountValue,
                date: date,
                reason: reason,
                paymentMethod: paymentMethod,
                processedBy: processedBy,
                referenceNumber: referenceNumber.isEmpty ? nil : referenceNumber,
                notes: notes.isEmpty ? nil : notes
            )
        } else {
            // Process as salary payment
            if periodStart >= periodEnd {
                alertTitle = "Invalid Period"
                alertMessage = "Period start date must be before period end date."
                showAlert = true
                return
            }
            
            let bonusesValue = Double(bonuses) ?? 0
            let deductionsValue = Double(deductions) ?? 0
            
            dataManager.addSalaryPayment(
                amount: amountValue,
                date: date,
                periodStart: periodStart,
                periodEnd: periodEnd,
                bonuses: bonusesValue,
                deductions: deductionsValue,
                paymentMethod: paymentMethod,
                processedBy: processedBy,
                referenceNumber: referenceNumber.isEmpty ? nil : referenceNumber,
                notes: notes.isEmpty ? nil : notes
            )
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct EmployeePaymentView_Previews: PreviewProvider {
    static var previews: some View {
        EmployeePaymentView()
            .environmentObject(DataManager())
    }
} 