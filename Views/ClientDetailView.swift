import SwiftUI

struct ClientDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    var clientIndex: Int?
    var isEditing: Bool
    
    // Company information
    @State private var name: String = ""
    @State private var company: String = ""
    @State private var companyDescription: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    
    // Company details
    @State private var street: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var postalCode: String = ""
    @State private var country: String = ""
    @State private var gstNumber: String = ""
    @State private var taxID: String = ""
    @State private var registrationNumber: String = ""
    @State private var website: String = ""
    @State private var industry: String = ""
    
    // Contact person
    @State private var showingContactPersonSheet = false
    @State private var contactPersonName: String = ""
    @State private var contactPersonPosition: String = ""
    @State private var contactPersonPhone: String = ""
    @State private var contactPersonEmail: String = ""
    @State private var contactPersonIsPrimary: Bool = false
    @State private var contactPersonNotes: String = ""
    @State private var editingContactPersonIndex: Int?
    
    // Sections visibility
    @State private var showCompanyInfo = true
    @State private var showCompanyDetails = true
    @State private var showContactPersons = true
    
    // Alerts
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Tabs
    @State private var selectedTab: Int = 0
    
    // Initialize view
    init(clientIndex: Int? = nil, isEditing: Bool = false) {
        self.clientIndex = clientIndex
        self.isEditing = isEditing
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Basic Company Info Tab
            Form {
                DisclosureGroup(
                    isExpanded: $showCompanyInfo,
                    content: {
                        TextField("Contact Person Name", text: $name)
                        TextField("Company Name", text: $company)
                        
                        TextField("Company Description", text: $companyDescription)
                            .lineLimit(3)
                        
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        TextField("Phone", text: $phone)
                            .keyboardType(.phonePad)
                    },
                    label: {
                        Label("Company Information", systemImage: "building.2.fill")
                    }
                )
                
                DisclosureGroup(
                    isExpanded: $showCompanyDetails,
                    content: {
                        Group {
                            TextField("Street", text: $street)
                            TextField("City", text: $city)
                            TextField("State/Province", text: $state)
                            TextField("Postal Code", text: $postalCode)
                                .keyboardType(.numberPad)
                            TextField("Country", text: $country)
                        }
                        
                        Divider()
                        
                        Group {
                            TextField("GST Number", text: $gstNumber)
                            TextField("Tax Identification Number", text: $taxID)
                            TextField("Registration Number", text: $registrationNumber)
                            TextField("Website", text: $website)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                            TextField("Industry", text: $industry)
                        }
                    },
                    label: {
                        Label("Company Details", systemImage: "building.columns.fill")
                    }
                )
                
                if isEditing {
                    Button(action: saveClient) {
                        Text("Save Changes")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(name.isEmpty || company.isEmpty)
                } else {
                    Button(action: addClient) {
                        Text("Add Client")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(name.isEmpty || company.isEmpty)
                }
            }
            .tabItem {
                Label("Company", systemImage: "building")
            }
            .tag(0)
            
            // Contact Persons Tab
            if isEditing {
                Form {
                    Section(header: HStack {
                        Text("Contact Persons")
                        Spacer()
                        Button(action: {
                            // Reset contact person fields
                            contactPersonName = ""
                            contactPersonPosition = ""
                            contactPersonPhone = ""
                            contactPersonEmail = ""
                            contactPersonIsPrimary = false
                            contactPersonNotes = ""
                            editingContactPersonIndex = nil
                            showingContactPersonSheet = true
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }) {
                        if let clientIndex = clientIndex {
                            let contactPersons = dataManager.filteredClients[clientIndex].contactPersons
                            
                            if contactPersons.isEmpty {
                                Text("No contact persons added")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                ForEach(Array(contactPersons.enumerated()), id: \.element.id) { index, contactPerson in
                                    Button(action: {
                                        // Pre-fill contact person fields for editing
                                        contactPersonName = contactPerson.name
                                        contactPersonPosition = contactPerson.position
                                        contactPersonPhone = contactPerson.phone
                                        contactPersonEmail = contactPerson.email
                                        contactPersonIsPrimary = contactPerson.isPrimary
                                        contactPersonNotes = contactPerson.notes ?? ""
                                        editingContactPersonIndex = index
                                        showingContactPersonSheet = true
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(contactPerson.name)
                                                    .font(.headline)
                                                
                                                Text(contactPerson.position)
                                                    .font(.subheadline)
                                                
                                                HStack {
                                                    Image(systemName: "phone")
                                                    Text(contactPerson.phone)
                                                }
                                                .font(.caption)
                                                
                                                HStack {
                                                    Image(systemName: "envelope")
                                                    Text(contactPerson.email)
                                                }
                                                .font(.caption)
                                                
                                                if contactPerson.isPrimary {
                                                    Text("Primary Contact")
                                                        .font(.caption)
                                                        .padding(4)
                                                        .background(Color.green.opacity(0.3))
                                                        .cornerRadius(4)
                                                }
                                                
                                                if let notes = contactPerson.notes, !notes.isEmpty {
                                                    Text("Notes: \(notes)")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        dataManager.deleteContactPerson(at: clientIndex, contactPersonIndex: index)
                                    }
                                }
                            }
                        }
                    }
                }
                .tabItem {
                    Label("Contacts", systemImage: "person.3")
                }
                .tag(1)
            }
        }
        .onAppear(perform: loadClientData)
        .navigationTitle(isEditing ? "Edit Client" : "Add Client")
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingContactPersonSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Contact Person Information")) {
                        TextField("Name", text: $contactPersonName)
                        TextField("Position", text: $contactPersonPosition)
                        TextField("Phone", text: $contactPersonPhone)
                            .keyboardType(.phonePad)
                        TextField("Email", text: $contactPersonEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        Toggle("Primary Contact", isOn: $contactPersonIsPrimary)
                        
                        TextField("Notes (Optional)", text: $contactPersonNotes)
                            .lineLimit(3)
                    }
                }
                .navigationTitle(editingContactPersonIndex == nil ? "Add Contact Person" : "Edit Contact Person")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingContactPersonSheet = false
                    },
                    trailing: Button("Save") {
                        saveContactPerson()
                        showingContactPersonSheet = false
                    }
                    .disabled(contactPersonName.isEmpty || contactPersonPhone.isEmpty || contactPersonEmail.isEmpty)
                )
            }
        }
    }
    
    // Load client data if editing
    private func loadClientData() {
        if isEditing, let index = clientIndex, index < dataManager.filteredClients.count {
            let client = dataManager.filteredClients[index]
            
            // Basic information
            name = client.name
            company = client.company
            companyDescription = client.companyDescription ?? ""
            email = client.email
            phone = client.phone
            
            // Company address
            street = client.companyAddress.street
            city = client.companyAddress.city
            state = client.companyAddress.state
            postalCode = client.companyAddress.postalCode
            country = client.companyAddress.country
            
            // Company details
            gstNumber = client.gstNumber ?? ""
            taxID = client.taxIdentificationNumber ?? ""
            registrationNumber = client.registrationNumber ?? ""
            website = client.website ?? ""
            industry = client.industry ?? ""
        }
    }
    
    // Save a new client
    private func addClient() {
        // Validate required fields
        guard !name.isEmpty, !company.isEmpty else {
            alertTitle = "Missing Information"
            alertMessage = "Contact person name and company name are required."
            showAlert = true
            return
        }
        
        // Create address
        let address = Address(
            street: street,
            city: city,
            state: state,
            postalCode: postalCode,
            country: country
        )
        
        // Create client
        var client = Client(
            name: name,
            company: company,
            email: email,
            phone: phone,
            companyAddress: address
        )
        
        // Set optional fields
        client.companyDescription = companyDescription.isEmpty ? nil : companyDescription
        client.gstNumber = gstNumber.isEmpty ? nil : gstNumber
        client.taxIdentificationNumber = taxID.isEmpty ? nil : taxID
        client.registrationNumber = registrationNumber.isEmpty ? nil : registrationNumber
        client.website = website.isEmpty ? nil : website
        client.industry = industry.isEmpty ? nil : industry
        
        dataManager.addClient(client)
        presentationMode.wrappedValue.dismiss()
    }
    
    // Save changes to an existing client
    private func saveClient() {
        guard let index = clientIndex, index < dataManager.filteredClients.count else {
            alertTitle = "Error"
            alertMessage = "Client not found."
            showAlert = true
            return
        }
        
        // Validate required fields
        guard !name.isEmpty, !company.isEmpty else {
            alertTitle = "Missing Information"
            alertMessage = "Contact person name and company name are required."
            showAlert = true
            return
        }
        
        // Create address
        let address = Address(
            street: street,
            city: city,
            state: state,
            postalCode: postalCode,
            country: country
        )
        
        // Update client
        dataManager.updateClientDetails(
            at: index,
            name: name,
            company: company,
            companyDescription: companyDescription.isEmpty ? nil : companyDescription,
            email: email,
            phone: phone,
            companyAddress: address,
            gstNumber: gstNumber.isEmpty ? nil : gstNumber,
            taxIdentificationNumber: taxID.isEmpty ? nil : taxID,
            registrationNumber: registrationNumber.isEmpty ? nil : registrationNumber,
            website: website.isEmpty ? nil : website,
            industry: industry.isEmpty ? nil : industry
        )
        
        presentationMode.wrappedValue.dismiss()
    }
    
    // Save contact person
    private func saveContactPerson() {
        guard let index = clientIndex, index < dataManager.filteredClients.count else { return }
        
        let contactPerson = ContactPerson(
            name: contactPersonName,
            position: contactPersonPosition,
            phone: contactPersonPhone,
            email: contactPersonEmail,
            isPrimary: contactPersonIsPrimary,
            notes: contactPersonNotes.isEmpty ? nil : contactPersonNotes
        )
        
        if let editingIndex = editingContactPersonIndex {
            // Update existing
            dataManager.updateContactPerson(at: index, contactPersonIndex: editingIndex, contactPerson: contactPerson)
        } else {
            // Add new
            dataManager.addContactPerson(to: index, contactPerson: contactPerson)
        }
    }
}

struct ClientDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ClientDetailView(isEditing: false)
                .environmentObject(DataManager())
        }
    }
} 