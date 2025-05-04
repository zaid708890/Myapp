import SwiftUI

struct AddProjectView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    let clientIndex: Int
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days ahead
    @State private var hasEndDate: Bool = true
    @State private var contractAmount: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Details")) {
                    TextField("Project Name", text: $name)
                    
                    TextField("Description", text: $description)
                    
                    TextField("Contract Amount", text: $contractAmount)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Project Timeline")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    Toggle("Has End Date", isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveProject()
                }
                .disabled(name.isEmpty || contractAmount.isEmpty)
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
    
    private func saveProject() {
        guard let amount = Double(contractAmount) else {
            alertMessage = "Please enter a valid contract amount"
            showAlert = true
            return
        }
        
        guard amount > 0 else {
            alertMessage = "Contract amount must be greater than zero"
            showAlert = true
            return
        }
        
        if hasEndDate && endDate < startDate {
            alertMessage = "End date must be after start date"
            showAlert = true
            return
        }
        
        var project = Project(
            name: name,
            description: description,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            contractAmount: amount,
            payments: []
        )
        
        dataManager.addProject(to: clientIndex, project: project)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddProjectView_Previews: PreviewProvider {
    static var previews: some View {
        AddProjectView(clientIndex: 0)
            .environmentObject(DataManager())
    }
} 