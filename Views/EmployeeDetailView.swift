import SwiftUI

struct EmployeeDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    var employeeIndex: Int?
    var isEditing: Bool
    
    @State private var name: String = ""
    @State private var gender: Gender = .notSpecified
    @State private var dateOfBirth: Date = Date().addingTimeInterval(-25 * 365 * 24 * 60 * 60) // 25 years ago
    @State private var showDateOfBirth: Bool = false
    @State private var position: String = ""
    @State private var monthlySalary: Double = 0.0
    @State private var joinDate: Date = Date()
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var alternatePhone: String = ""
    
    // Address fields
    @State private var street: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var postalCode: String = ""
    @State private var country: String = ""
    
    // Emergency contact fields
    @State private var showingEmergencyContactSheet = false
    @State private var emergencyContactName: String = ""
    @State private var emergencyContactRelationship: String = ""
    @State private var emergencyContactPhone: String = ""
    @State private var emergencyContactEmail: String = ""
    
    // Identification fields
    @State private var showingIdentificationSheet = false
    @State private var identificationType: Identification.IdentificationType = .passport
    @State private var identificationNumber: String = ""
    @State private var issuedDate: Date = Date()
    @State private var expiryDate: Date = Date().addingTimeInterval(5 * 365 * 24 * 60 * 60) // 5 years from now
    
    // Sections visibility
    @State private var showBasicInfo = true
    @State private var showContactInfo = true
    @State private var showAddressInfo = true
    @State private var showEmergencyContact = true
    @State private var showIdentificationInfo = true
    
    // Alerts
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Tabs
    @State private var selectedTab: Int = 0
    
    // Initialize view
    init(employeeIndex: Int? = nil, isEditing: Bool = false) {
        self.employeeIndex = employeeIndex
        self.isEditing = isEditing
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Basic Information Tab
            Form {
                DisclosureGroup(
                    isExpanded: $showBasicInfo,
                    content: {
                        TextField("Full Name", text: $name)
                        
                        Picker("Gender", selection: $gender) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }
                        
                        Toggle("Add Date of Birth", isOn: $showDateOfBirth)
                        
                        if showDateOfBirth {
                            DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                        }
                        
                        TextField("Position", text: $position)
                        
                        HStack {
                            Text("Monthly Salary")
                            Spacer()
                            TextField("Amount", value: $monthlySalary, formatter: Formatters.currencyFormatter)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        DatePicker("Join Date", selection: $joinDate, displayedComponents: .date)
                    },
                    label: {
                        Label("Basic Information", systemImage: "person.fill")
                    }
                )
                
                DisclosureGroup(
                    isExpanded: $showContactInfo,
                    content: {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        TextField("Phone", text: $phone)
                            .keyboardType(.phonePad)
                        
                        TextField("Alternate Phone (Optional)", text: $alternatePhone)
                            .keyboardType(.phonePad)
                    },
                    label: {
                        Label("Contact Information", systemImage: "phone.fill")
                    }
                )
                
                DisclosureGroup(
                    isExpanded: $showAddressInfo,
                    content: {
                        TextField("Street", text: $street)
                        TextField("City", text: $city)
                        TextField("State/Province", text: $state)
                        TextField("Postal Code", text: $postalCode)
                            .keyboardType(.numberPad)
                        TextField("Country", text: $country)
                    },
                    label: {
                        Label("Address", systemImage: "location.fill")
                    }
                )
                
                if isEditing {
                    Button(action: saveEmployee) {
                        Text("Save Changes")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(name.isEmpty || position.isEmpty)
                } else {
                    Button(action: addEmployee) {
                        Text("Add Employee")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(name.isEmpty || position.isEmpty)
                }
            }
            .tabItem {
                Label("Basic Info", systemImage: "person")
            }
            .tag(0)
            
            // Emergency Contact Tab
            if isEditing {
                Form {
                    Section(header: Text("Emergency Contact")) {
                        if let employeeIndex = employeeIndex,
                           let emergencyContact = dataManager.filteredEmployees[employeeIndex].emergencyContact {
                            // Show existing emergency contact
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name: \(emergencyContact.name)")
                                Text("Relationship: \(emergencyContact.relationship)")
                                Text("Phone: \(emergencyContact.phone)")
                                if let email = emergencyContact.email {
                                    Text("Email: \(email)")
                                }
                            }
                            
                            Button("Edit Emergency Contact") {
                                // Pre-fill emergency contact fields
                                emergencyContactName = emergencyContact.name
                                emergencyContactRelationship = emergencyContact.relationship
                                emergencyContactPhone = emergencyContact.phone
                                emergencyContactEmail = emergencyContact.email ?? ""
                                showingEmergencyContactSheet = true
                            }
                        } else {
                            Text("No emergency contact information added")
                                .foregroundColor(.secondary)
                                .italic()
                            
                            Button("Add Emergency Contact") {
                                showingEmergencyContactSheet = true
                            }
                        }
                    }
                }
                .tabItem {
                    Label("Emergency", systemImage: "exclamationmark.shield")
                }
                .tag(1)
                
                // Identification Documents Tab
                Form {
                    Section(header: HStack {
                        Text("Identification Documents")
                        Spacer()
                        Button(action: {
                            // Reset identification fields
                            identificationType = .passport
                            identificationNumber = ""
                            issuedDate = Date()
                            expiryDate = Date().addingTimeInterval(5 * 365 * 24 * 60 * 60)
                            showingIdentificationSheet = true
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }) {
                        if let employeeIndex = employeeIndex {
                            let identifications = dataManager.filteredEmployees[employeeIndex].identifications
                            
                            if identifications.isEmpty {
                                Text("No identification documents added")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                ForEach(identifications) { identification in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Type: \(identification.type.rawValue)")
                                            .font(.headline)
                                        Text("Number: \(identification.documentNumber)")
                                        
                                        if let issuedDate = identification.issuedDate {
                                            Text("Issued Date: \(Formatters.formatDate(issuedDate))")
                                                .font(.caption)
                                        }
                                        
                                        if let expiryDate = identification.expiryDate {
                                            Text("Expiry Date: \(Formatters.formatDate(expiryDate))")
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
                .tabItem {
                    Label("Identification", systemImage: "doc.text")
                }
                .tag(2)
            }
        }
        .onAppear(perform: loadEmployeeData)
        .navigationTitle(isEditing ? "Edit Employee" : "Add Employee")
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingEmergencyContactSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Emergency Contact Information")) {
                        TextField("Name", text: $emergencyContactName)
                        TextField("Relationship", text: $emergencyContactRelationship)
                        TextField("Phone", text: $emergencyContactPhone)
                            .keyboardType(.phonePad)
                        TextField("Email (Optional)", text: $emergencyContactEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                .navigationTitle("Emergency Contact")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingEmergencyContactSheet = false
                    },
                    trailing: Button("Save") {
                        saveEmergencyContact()
                        showingEmergencyContactSheet = false
                    }
                    .disabled(emergencyContactName.isEmpty || emergencyContactRelationship.isEmpty || emergencyContactPhone.isEmpty)
                )
            }
        }
        .sheet(isPresented: $showingIdentificationSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Identification Information")) {
                        Picker("Type", selection: $identificationType) {
                            ForEach(Identification.IdentificationType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        
                        TextField("Document Number", text: $identificationNumber)
                        
                        DatePicker("Issued Date", selection: $issuedDate, displayedComponents: .date)
                        
                        DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                    }
                }
                .navigationTitle("Identification Document")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingIdentificationSheet = false
                    },
                    trailing: Button("Save") {
                        saveIdentification()
                        showingIdentificationSheet = false
                    }
                    .disabled(identificationNumber.isEmpty)
                )
            }
        }
    }
    
    // Load employee data if editing
    private func loadEmployeeData() {
        if isEditing, let index = employeeIndex, index < dataManager.filteredEmployees.count {
            let employee = dataManager.filteredEmployees[index]
            
            // Basic information
            name = employee.name
            gender = employee.gender
            if let dob = employee.dateOfBirth {
                dateOfBirth = dob
                showDateOfBirth = true
            }
            position = employee.position
            monthlySalary = employee.monthlySalary
            joinDate = employee.joinDate
            
            // Contact information
            email = employee.email
            phone = employee.phone
            alternatePhone = employee.alternatePhone ?? ""
            
            // Address information
            street = employee.address.street
            city = employee.address.city
            state = employee.address.state
            postalCode = employee.address.postalCode
            country = employee.address.country
        }
    }
    
    // Save a new employee
    private func addEmployee() {
        // Validate required fields
        guard !name.isEmpty, !position.isEmpty else {
            alertTitle = "Missing Information"
            alertMessage = "Name and position are required."
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
        
        // Create employee
        let employee = Employee(
            name: name,
            gender: gender,
            position: position,
            monthlySalary: monthlySalary,
            joinDate: joinDate,
            email: email,
            phone: phone,
            address: address
        )
        
        // Set optional fields
        if showDateOfBirth {
            var updatedEmployee = employee
            updatedEmployee.dateOfBirth = dateOfBirth
            dataManager.addEmployee(updatedEmployee)
        } else {
            dataManager.addEmployee(employee)
        }
        
        if !alternatePhone.isEmpty {
            if let index = dataManager.filteredEmployees.firstIndex(where: { $0.id == employee.id }) {
                var updatedEmployee = dataManager.filteredEmployees[index]
                updatedEmployee.alternatePhone = alternatePhone
                dataManager.updateEmployee(updatedEmployee)
            }
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    // Save changes to an existing employee
    private func saveEmployee() {
        guard let index = employeeIndex, index < dataManager.filteredEmployees.count else {
            alertTitle = "Error"
            alertMessage = "Employee not found."
            showAlert = true
            return
        }
        
        // Validate required fields
        guard !name.isEmpty, !position.isEmpty else {
            alertTitle = "Missing Information"
            alertMessage = "Name and position are required."
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
        
        // Update employee
        dataManager.updateEmployeeDetails(
            at: index,
            name: name,
            gender: gender,
            dateOfBirth: showDateOfBirth ? dateOfBirth : nil,
            position: position,
            monthlySalary: monthlySalary,
            joinDate: joinDate,
            email: email,
            phone: phone,
            alternatePhone: alternatePhone.isEmpty ? nil : alternatePhone,
            address: address
        )
        
        presentationMode.wrappedValue.dismiss()
    }
    
    // Save emergency contact
    private func saveEmergencyContact() {
        guard let index = employeeIndex, index < dataManager.filteredEmployees.count else { return }
        
        let emergencyContact = EmergencyContact(
            name: emergencyContactName,
            relationship: emergencyContactRelationship,
            phone: emergencyContactPhone,
            email: emergencyContactEmail.isEmpty ? nil : emergencyContactEmail
        )
        
        dataManager.addEmployeeEmergencyContact(at: index, emergencyContact: emergencyContact)
    }
    
    // Save identification
    private func saveIdentification() {
        guard let index = employeeIndex, index < dataManager.filteredEmployees.count else { return }
        
        let identification = Identification(
            type: identificationType,
            documentNumber: identificationNumber,
            issuedDate: issuedDate,
            expiryDate: expiryDate
        )
        
        dataManager.addEmployeeIdentification(at: index, identification: identification)
    }
}

struct EmployeeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EmployeeDetailView(isEditing: false)
                .environmentObject(DataManager())
        }
    }
} 