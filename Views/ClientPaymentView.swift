import SwiftUI

struct ClientPaymentView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    let clientIndex: Int
    let projectIndex: Int
    
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var paymentType: ProjectPayment.PaymentType = .milestone
    @State private var paymentMethod: ProjectPayment.PaymentMethod = .bankTransfer
    @State private var referenceNumber: String = ""
    @State private var receivedBy: String = ""
    @State private var receivedFrom: String = ""
    @State private var verifiedBy: String = ""
    @State private var invoiceNumber: String = ""
    
    // Bank transfer details
    @State private var showBankDetails: Bool = false
    @State private var bankName: String = ""
    @State private var accountNumber: String = ""
    @State private var transferDate: Date = Date()
    @State private var branchCode: String = ""
    @State private var swiftCode: String = ""
    
    // Alert state
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Payment Details")) {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    Picker("Payment Type", selection: $paymentType) {
                        ForEach(ProjectPayment.PaymentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    TextField("Invoice Number", text: $invoiceNumber)
                    
                    TextField("Notes", text: $notes)
                        .lineLimit(3)
                }
                
                Section(header: Text("Payment Method")) {
                    Picker("Method", selection: $paymentMethod) {
                        ForEach(ProjectPayment.PaymentMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: paymentMethod) { newValue in
                        if newValue == .bankTransfer {
                            showBankDetails = true
                        } else {
                            showBankDetails = false
                        }
                    }
                    
                    TextField("Reference Number", text: $referenceNumber)
                }
                
                Section(header: Text("Processed By")) {
                    TextField("Received By", text: $receivedBy)
                    
                    TextField("Received From", text: $receivedFrom)
                    
                    TextField("Verified By", text: $verifiedBy)
                }
                
                if showBankDetails {
                    Section(header: Text("Bank Transfer Details")) {
                        TextField("Bank Name", text: $bankName)
                        
                        TextField("Account Number", text: $accountNumber)
                        
                        DatePicker("Transfer Date", selection: $transferDate, displayedComponents: .date)
                        
                        TextField("Branch Code (Optional)", text: $branchCode)
                        
                        TextField("SWIFT Code (Optional)", text: $swiftCode)
                    }
                }
                
                Section {
                    Button(action: processPayment) {
                        Text("Add Payment")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(amount.isEmpty || notes.isEmpty || (showBankDetails && (bankName.isEmpty || accountNumber.isEmpty)))
                }
            }
            .navigationTitle("Add Payment")
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
        
        if paymentMethod == .bankTransfer {
            // Process bank transfer payment
            if bankName.isEmpty || accountNumber.isEmpty {
                alertTitle = "Missing Bank Information"
                alertMessage = "Please provide bank name and account number."
                showAlert = true
                return
            }
            
            dataManager.addBankTransferPayment(
                to: clientIndex,
                projectIndex: projectIndex,
                amount: amountValue,
                date: date,
                notes: notes,
                paymentType: paymentType,
                bankName: bankName,
                accountNumber: accountNumber,
                transferDate: transferDate,
                branchCode: branchCode.isEmpty ? nil : branchCode,
                swiftCode: swiftCode.isEmpty ? nil : swiftCode,
                receivedBy: receivedBy.isEmpty ? nil : receivedBy,
                verifiedBy: verifiedBy.isEmpty ? nil : verifiedBy,
                invoiceNumber: invoiceNumber.isEmpty ? nil : invoiceNumber
            )
        } else {
            // Process regular payment
            dataManager.addDetailedClientPayment(
                to: clientIndex,
                projectIndex: projectIndex,
                amount: amountValue,
                date: date,
                notes: notes,
                paymentType: paymentType,
                paymentMethod: paymentMethod,
                referenceNumber: referenceNumber.isEmpty ? nil : referenceNumber,
                receivedBy: receivedBy.isEmpty ? nil : receivedBy,
                receivedFrom: receivedFrom.isEmpty ? nil : receivedFrom,
                verifiedBy: verifiedBy.isEmpty ? nil : verifiedBy,
                invoiceNumber: invoiceNumber.isEmpty ? nil : invoiceNumber
            )
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct ClientPaymentView_Previews: PreviewProvider {
    static var previews: some View {
        ClientPaymentView(clientIndex: 0, projectIndex: 0)
            .environmentObject(DataManager())
    }
} 