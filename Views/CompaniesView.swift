import SwiftUI

struct CompaniesView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddCompanySheet = false
    @State private var showingEditCompanySheet = false
    @State private var selectedCompanyIndex = 0
    
    var body: some View {
        List {
            Section(header: Text("Active Company")) {
                if let activeCompany = dataManager.activeCompany {
                    CompanySummaryView(company: activeCompany)
                } else {
                    Text("No active company selected")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            Section(header: 
                HStack {
                    Text("All Companies")
                    Spacer()
                    Button(action: {
                        showingAddCompanySheet = true
                    }) {
                        Image(systemName: "plus.circle")
                    }
                }
            ) {
                ForEach(Array(dataManager.companies.enumerated()), id: \.element.id) { index, company in
                    Button(action: {
                        if company.id != dataManager.activeCompanyID {
                            dataManager.switchActiveCompany(to: company.id)
                        } else {
                            selectedCompanyIndex = index
                            showingEditCompanySheet = true
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(company.name)
                                    .font(.headline)
                                
                                Text(company.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if company.id == dataManager.activeCompanyID {
                                    Text("Active")
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.green.opacity(0.3))
                                        .cornerRadius(4)
                                }
                            }
                            
                            Spacer()
                            
                            if company.id == dataManager.activeCompanyID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Text("Tap to switch")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteCompany)
            }
            
            Section(header: Text("Data Summary")) {
                if let activeCompany = dataManager.activeCompany {
                    HStack {
                        Text("Employees")
                        Spacer()
                        Text("\(dataManager.filteredEmployees.count)")
                    }
                    
                    HStack {
                        Text("Clients")
                        Spacer()
                        Text("\(dataManager.filteredClients.count)")
                    }
                    
                    HStack {
                        Text("Salary Slips")
                        Spacer()
                        Text("\(dataManager.filteredSalarySlips.count)")
                    }
                    
                    HStack {
                        Text("Client Statements")
                        Spacer()
                        Text("\(dataManager.filteredClientStatements.count)")
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Manage Companies")
        .sheet(isPresented: $showingAddCompanySheet) {
            AddCompanyView()
        }
        .sheet(isPresented: $showingEditCompanySheet) {
            if selectedCompanyIndex < dataManager.companies.count {
                EditCompanyView(company: dataManager.companies[selectedCompanyIndex])
            }
        }
    }
    
    private func deleteCompany(at offsets: IndexSet) {
        for offset in offsets {
            // Don't allow deleting the active company
            if dataManager.companies[offset].id != dataManager.activeCompanyID {
                dataManager.deleteCompany(at: offset)
            }
        }
    }
}

struct CompanySummaryView: View {
    let company: Company
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(company.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(company.address)
                .font(.subheadline)
            
            HStack {
                Image(systemName: "phone")
                    .foregroundColor(.secondary)
                Text(company.phone)
            }
            .font(.caption)
            
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(.secondary)
                Text(company.email)
            }
            .font(.caption)
            
            Text("Created: \(Formatters.formatDate(company.createdDate))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct AddCompanyView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Company Information")) {
                    TextField("Company Name", text: $name)
                    TextField("Address", text: $address)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section {
                    Button(action: saveCompany) {
                        Text("Add Company")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(name.isEmpty || address.isEmpty)
                }
            }
            .navigationTitle("New Company")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
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
    
    private func saveCompany() {
        if name.isEmpty || address.isEmpty {
            alertMessage = "Company name and address are required"
            showAlert = true
            return
        }
        
        let newCompany = Company(
            name: name,
            address: address,
            phone: phone,
            email: email
        )
        
        dataManager.addCompany(newCompany)
        presentationMode.wrappedValue.dismiss()
    }
}

struct EditCompanyView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    var company: Company
    
    @State private var name: String
    @State private var address: String
    @State private var phone: String
    @State private var email: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(company: Company) {
        self.company = company
        _name = State(initialValue: company.name)
        _address = State(initialValue: company.address)
        _phone = State(initialValue: company.phone)
        _email = State(initialValue: company.email)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Company Information")) {
                    TextField("Company Name", text: $name)
                    TextField("Address", text: $address)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section {
                    Button(action: updateCompany) {
                        Text("Save Changes")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(name.isEmpty || address.isEmpty)
                }
            }
            .navigationTitle("Edit Company")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
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
    
    private func updateCompany() {
        if name.isEmpty || address.isEmpty {
            alertMessage = "Company name and address are required"
            showAlert = true
            return
        }
        
        var updatedCompany = company
        updatedCompany.name = name
        updatedCompany.address = address
        updatedCompany.phone = phone
        updatedCompany.email = email
        
        dataManager.updateCompany(updatedCompany)
        presentationMode.wrappedValue.dismiss()
    }
}

struct CompaniesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CompaniesView()
                .environmentObject(DataManager())
        }
    }
} 