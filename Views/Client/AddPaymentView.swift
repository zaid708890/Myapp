import SwiftUI

struct AddPaymentView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    let clientIndex: Int
    let projectIndex: Int
    
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var paymentType: ProjectPayment.PaymentType = .milestone
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var project: Project {
        dataManager.clients[clientIndex].projects[projectIndex]
    }
    
    var remainingBalance: Double {
        project.balanceAmount
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Payment Details")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Payment Date", selection: $date, displayedComponents: .date)
                    
                    Picker("Payment Type", selection: $paymentType) {
                        ForEach(ProjectPayment.PaymentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    TextField("Notes", text: $notes)
                }
                
                Section(header: Text("Project Balance")) {
                    HStack {
                        Text("Remaining Balance")
                            .font(.headline)
                        Spacer()
                        Text(remainingBalance.formattedCurrency)
                            .font(.headline)
                            .foregroundColor(remainingBalance > 0 ? .green : .primary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Payment")
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
        
        // Allow exceeding the contract amount deliberately
        // But warn the user if they're about to exceed it
        if paymentAmount > remainingBalance {
            alertMessage = "Warning: This payment exceeds the remaining balance. The project will be overpaid."
            showAlert = true
            return
        }
        
        let payment = ProjectPayment(
            amount: paymentAmount,
            date: date,
            notes: notes,
            paymentType: paymentType
        )
        
        dataManager.addPayment(to: clientIndex, projectIndex: projectIndex, payment: payment)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddPaymentView_Previews: PreviewProvider {
    static var previews: some View {
        AddPaymentView(clientIndex: 0, projectIndex: 0)
            .environmentObject(DataManager())
    }
} 