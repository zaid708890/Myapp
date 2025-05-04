import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    @State private var name: String = ""
    @State private var position: String = ""
    @State private var monthlySalary: String = ""
    @State private var joinDate: Date = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Your Name", text: $name)
                    TextField("Position", text: $position)
                    
                    TextField("Monthly Salary", text: $monthlySalary)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Join Date", selection: $joinDate, displayedComponents: .date)
                }
                
                Section {
                    Button(action: saveChanges) {
                        Text("Save Changes")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(name.isEmpty || position.isEmpty || monthlySalary.isEmpty)
                }
                
                Section(header: Text("App Information")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear(perform: loadEmployeeData)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func loadEmployeeData() {
        name = dataManager.employee.name
        position = dataManager.employee.position
        monthlySalary = "\(dataManager.employee.monthlySalary)"
        joinDate = dataManager.employee.joinDate
    }
    
    private func saveChanges() {
        guard let salary = Double(monthlySalary) else {
            alertMessage = "Please enter a valid salary amount"
            showAlert = true
            return
        }
        
        guard salary >= 0 else {
            alertMessage = "Salary amount must be greater than or equal to zero"
            showAlert = true
            return
        }
        
        dataManager.updateEmployee(
            name: name,
            position: position,
            monthlySalary: salary,
            joinDate: joinDate
        )
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(DataManager())
    }
} 