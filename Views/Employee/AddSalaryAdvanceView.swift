import SwiftUI

struct AddSalaryAdvanceView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var amount: String = ""
    @State private var reason: String = ""
    @State private var date: Date = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Advance Details")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Reason", text: $reason)
                }
            }
            .navigationTitle("New Salary Advance")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveAdvance()
                }
                .disabled(amount.isEmpty || reason.isEmpty)
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
    
    private func saveAdvance() {
        guard let advanceAmount = Double(amount) else {
            alertMessage = "Please enter a valid amount"
            showAlert = true
            return
        }
        
        guard advanceAmount > 0 else {
            alertMessage = "Amount must be greater than zero"
            showAlert = true
            return
        }
        
        let advance = SalaryAdvance(
            amount: advanceAmount,
            date: date,
            reason: reason
        )
        
        dataManager.addSalaryAdvance(advance)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddSalaryAdvanceView_Previews: PreviewProvider {
    static var previews: some View {
        AddSalaryAdvanceView()
            .environmentObject(DataManager())
    }
} 