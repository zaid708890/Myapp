import SwiftUI

struct AddDutyRecordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(7 * 24 * 60 * 60) // 1 week from now
    @State private var notes: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Duty Period")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    
                    TextField("Notes", text: $notes)
                }
                
                Section {
                    Text("Duration: \(dutyDuration) days")
                        .font(.headline)
                }
            }
            .navigationTitle("Record Duty Period")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveDutyRecord()
                }
                .disabled(!isValidDateRange)
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
    
    private var dutyDuration: Int {
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    private func saveDutyRecord() {
        guard isValidDateRange else {
            alertMessage = "End date must be after start date"
            showAlert = true
            return
        }
        
        let dutyRecord = DutyRecord(
            startDate: startDate,
            endDate: endDate,
            notes: notes
        )
        
        dataManager.addDutyRecord(dutyRecord)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddDutyRecordView_Previews: PreviewProvider {
    static var previews: some View {
        AddDutyRecordView()
            .environmentObject(DataManager())
    }
} 