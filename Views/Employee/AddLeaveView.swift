import SwiftUI

struct AddLeaveView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(24 * 60 * 60) // Next day
    @State private var reason: String = ""
    @State private var isPaid: Bool = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Leave Details")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    
                    TextField("Reason", text: $reason)
                    
                    Toggle("Paid Leave", isOn: $isPaid)
                }
                
                Section {
                    Text("Duration: \(leaveDuration) days")
                        .font(.headline)
                }
            }
            .navigationTitle("Request Leave")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveLeave()
                }
                .disabled(reason.isEmpty || !isValidDateRange)
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
    
    private var isValidDateRange: Bool {
        return startDate <= endDate
    }
    
    private var leaveDuration: Int {
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    private func saveLeave() {
        guard isValidDateRange else {
            alertMessage = "End date must be after start date"
            showAlert = true
            return
        }
        
        let leave = Leave(
            startDate: startDate,
            endDate: endDate,
            reason: reason,
            isPaid: isPaid
        )
        
        dataManager.addLeave(leave)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddLeaveView_Previews: PreviewProvider {
    static var previews: some View {
        AddLeaveView()
            .environmentObject(DataManager())
    }
} 