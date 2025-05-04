import SwiftUI

struct AddClientView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var name: String = ""
    @State private var company: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Client Information")) {
                    TextField("Name", text: $name)
                    TextField("Company", text: $company)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("New Client")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveClient()
                }
                .disabled(name.isEmpty || company.isEmpty)
            )
        }
    }
    
    private func saveClient() {
        let client = Client(
            name: name,
            company: company,
            email: email,
            phone: phone
        )
        
        dataManager.addClient(client)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddClientView_Previews: PreviewProvider {
    static var previews: some View {
        AddClientView()
            .environmentObject(DataManager())
    }
} 