import Foundation
import Combine

class DataManager: ObservableObject {
    // Published properties for company and business data
    @Published var companies: [Company] = []
    @Published var activeCompanyID: UUID?
    
    @Published var employees: [Employee] = []
    @Published var clients: [Client] = []
    @Published var salarySlips: [SalarySlip] = []
    @Published var clientStatements: [ClientStatement] = []
    @Published var companyExpenses: [CompanyExpense] = []
    @Published var expenseReports: [ExpenseReport] = []
    @Published var personalAccount: AccountBalance?
    
    // File paths for data storage
    private let companiesFileName = "companies.json"
    private let employeesFileName = "employees.json"
    private let clientsFileName = "clients.json"
    private let salarySlipsFileName = "salary_slips.json"
    private let clientStatementsFileName = "client_statements.json"
    private let expensesFileName = "company_expenses.json"
    private let expenseReportsFileName = "expense_reports.json"
    private let accountBalanceFileName = "account_balance.json"
    private let activeCompanyKey = "activeCompanyID"
    
    // Keys for UserDefaults
    private let hasInitializedKey = "hasInitializedData"
    
    init() {
        // Load companies first
        self.companies = loadCompanies() ?? []
        
        // If no companies exist, create a default one
        if companies.isEmpty {
            let defaultCompany = Company(
                name: "My Company",
                address: "123 Main Street",
                phone: "555-1234",
                email: "contact@mycompany.com"
            )
            companies.append(defaultCompany)
            saveCompanies()
        }
        
        // Get active company from UserDefaults or default to first company
        if let savedCompanyIDString = UserDefaults.standard.string(forKey: activeCompanyKey),
           let savedCompanyID = UUID(uuidString: savedCompanyIDString) {
            self.activeCompanyID = savedCompanyID
        } else {
            self.activeCompanyID = companies.first?.id
            UserDefaults.standard.set(activeCompanyID?.uuidString, forKey: activeCompanyKey)
        }
        
        // Load all data
        self.employees = loadEmployees() ?? []
        self.clients = loadClients() ?? []
        self.salarySlips = loadSalarySlips() ?? []
        self.clientStatements = loadClientStatements() ?? []
        self.companyExpenses = loadExpenses() ?? []
        self.expenseReports = loadExpenseReports() ?? []
        self.personalAccount = loadAccountBalance()
        
        // Create a default personal account if none exists
        if self.personalAccount == nil {
            self.personalAccount = AccountBalance(ownerName: "My Account")
            saveAccountBalance()
        }
        
        // Initialize with sample data if first launch
        if !UserDefaults.standard.bool(forKey: hasInitializedKey) {
            initializeWithSampleData()
            UserDefaults.standard.set(true, forKey: hasInitializedKey)
            saveData()
        }
    }
    
    // MARK: - Company Management
    
    var activeCompany: Company? {
        guard let id = activeCompanyID else { return nil }
        return companies.first { $0.id == id }
    }
    
    func switchActiveCompany(to companyID: UUID) {
        guard companies.contains(where: { $0.id == companyID }) else { return }
        activeCompanyID = companyID
        UserDefaults.standard.set(companyID.uuidString, forKey: activeCompanyKey)
        // Save this as an observable change
        objectWillChange.send()
    }
    
    func addCompany(_ company: Company) {
        companies.append(company)
        saveCompanies()
    }
    
    func updateCompany(_ company: Company) {
        if let index = companies.firstIndex(where: { $0.id == company.id }) {
            companies[index] = company
            saveCompanies()
        }
    }
    
    func deleteCompany(at index: Int) {
        // Don't allow deletion if this is the only company
        guard companies.count > 1, index < companies.count else { return }
        
        let companyToDelete = companies[index]
        
        // If deleting active company, switch to another one
        if companyToDelete.id == activeCompanyID {
            // Find another company to make active
            let newActiveCompany = companies.first { $0.id != companyToDelete.id }
            if let newActiveID = newActiveCompany?.id {
                switchActiveCompany(to: newActiveID)
            }
        }
        
        // Remove company
        companies.remove(at: index)
        saveCompanies()
    }
    
    // MARK: - Filtered Data Getters
    
    var filteredEmployees: [Employee] {
        guard let activeCompany = activeCompany else { return [] }
        return employees.filter { activeCompany.employeeIDs.contains($0.id) }
    }
    
    var filteredClients: [Client] {
        guard let activeCompany = activeCompany else { return [] }
        return clients.filter { activeCompany.clientIDs.contains($0.id) }
    }
    
    var filteredSalarySlips: [SalarySlip] {
        guard let activeCompany = activeCompany else { return [] }
        return salarySlips.filter { activeCompany.salarySlipIDs.contains($0.id) }
    }
    
    var filteredClientStatements: [ClientStatement] {
        guard let activeCompany = activeCompany else { return [] }
        return clientStatements.filter { activeCompany.clientStatementIDs.contains($0.id) }
    }
    
    // MARK: - Helper to get current employee
    
    var employee: Employee {
        if let firstEmployee = filteredEmployees.first {
            return firstEmployee
        } else {
            // Create a default employee if none exists
            let newEmployee = Employee(
                name: "Your Name",
                position: "Your Position",
                monthlySalary: 0.0,
                joinDate: Date()
            )
            addEmployee(newEmployee)
            return newEmployee
        }
    }
    
    // MARK: - Data Operations
    
    func saveData() {
        saveCompanies()
        saveEmployees()
        saveClients()
        saveSalarySlips()
        saveClientStatements()
        saveExpenses()
        saveExpenseReports()
        saveAccountBalance()
    }
    
    // MARK: - Employee Operations
    
    func addEmployee(_ employee: Employee) {
        employees.append(employee)
        
        // Add reference to company
        if var company = activeCompany {
            company.employeeIDs.append(employee.id)
            updateCompany(company)
        }
        
        saveEmployees()
    }
    
    func updateEmployee(_ employee: Employee) {
        if let index = employees.firstIndex(where: { $0.id == employee.id }) {
            employees[index] = employee
            saveEmployees()
        }
    }
    
    func deleteEmployee(at index: Int) {
        let filteredEmployees = self.filteredEmployees
        guard index < filteredEmployees.count else { return }
        
        // Find and remove from master list
        let employeeToDelete = filteredEmployees[index]
        if let masterIndex = employees.firstIndex(where: { $0.id == employeeToDelete.id }) {
            employees.remove(at: masterIndex)
        }
        
        // Remove ID from company
        if var company = activeCompany, let idIndex = company.employeeIDs.firstIndex(of: employeeToDelete.id) {
            company.employeeIDs.remove(at: idIndex)
            updateCompany(company)
        }
        
        saveEmployees()
    }
    
    func updateEmployeeDetails(at index: Int, 
                             name: String, 
                             gender: Gender,
                             dateOfBirth: Date?,
                             position: String, 
                             monthlySalary: Double, 
                             joinDate: Date,
                             email: String,
                             phone: String,
                             alternatePhone: String?,
                             address: Address) {
        
        let filteredEmployees = self.filteredEmployees
        guard index < filteredEmployees.count else { return }
        
        var employee = filteredEmployees[index]
        
        // Update basic information
        employee.name = name
        employee.gender = gender
        employee.dateOfBirth = dateOfBirth
        employee.position = position
        employee.monthlySalary = monthlySalary
        employee.joinDate = joinDate
        
        // Update contact information
        employee.email = email
        employee.phone = phone
        employee.alternatePhone = alternatePhone
        
        // Update address
        employee.address = address
        
        // Update in master list
        if let masterIndex = employees.firstIndex(where: { $0.id == employee.id }) {
            employees[masterIndex] = employee
            saveEmployees()
        }
    }
    
    func addEmployeeEmergencyContact(at employeeIndex: Int, emergencyContact: EmergencyContact) {
        let filteredEmployees = self.filteredEmployees
        guard employeeIndex < filteredEmployees.count else { return }
        
        var employee = filteredEmployees[employeeIndex]
        employee.emergencyContact = emergencyContact
        
        if let masterIndex = employees.firstIndex(where: { $0.id == employee.id }) {
            employees[masterIndex] = employee
            saveEmployees()
        }
    }
    
    func addEmployeeIdentification(at employeeIndex: Int, identification: Identification) {
        let filteredEmployees = self.filteredEmployees
        guard employeeIndex < filteredEmployees.count else { return }
        
        var employee = filteredEmployees[employeeIndex]
        employee.identifications.append(identification)
        
        if let masterIndex = employees.firstIndex(where: { $0.id == employee.id }) {
            employees[masterIndex] = employee
            saveEmployees()
        }
    }
    
    // MARK: - Employee Payment Operations
    
    func addSalaryAdvance(amount: Double, 
                        date: Date, 
                        reason: String,
                        paymentMethod: PaymentMethod = .bankTransfer,
                        processedBy: String = "",
                        referenceNumber: String? = nil,
                        notes: String? = nil) {
        
        if var employee = filteredEmployees.first {
            let advance = SalaryAdvance(
                amount: amount,
                date: date,
                reason: reason,
                paymentMethod: paymentMethod,
                processedBy: processedBy,
                referenceNumber: referenceNumber,
                notes: notes
            )
            
            employee.salaryAdvances.append(advance)
            
            if let index = employees.firstIndex(where: { $0.id == employee.id }) {
                employees[index] = employee
                saveEmployees()
            }
        }
    }
    
    func addSalaryPayment(amount: Double,
                        date: Date,
                        periodStart: Date,
                        periodEnd: Date,
                        bonuses: Double = 0,
                        deductions: Double = 0,
                        paymentMethod: PaymentMethod = .bankTransfer,
                        processedBy: String = "",
                        referenceNumber: String? = nil,
                        notes: String? = nil) {
        
        if var employee = filteredEmployees.first {
            let payment = SalaryPayment(
                amount: amount,
                date: date,
                periodStart: periodStart,
                periodEnd: periodEnd,
                bonuses: bonuses,
                deductions: deductions,
                paymentMethod: paymentMethod,
                processedBy: processedBy,
                referenceNumber: referenceNumber,
                notes: notes
            )
            
            employee.salaryHistory.append(payment)
            
            if let index = employees.firstIndex(where: { $0.id == employee.id }) {
                employees[index] = employee
                saveEmployees()
            }
        }
    }
    
    func addLeave(startDate: Date,
                endDate: Date,
                reason: String,
                isPaid: Bool,
                approvedBy: String? = nil,
                notes: String? = nil) {
        
        if var employee = filteredEmployees.first {
            let leave = Leave(
                startDate: startDate,
                endDate: endDate,
                reason: reason,
                isPaid: isPaid,
                approvedBy: approvedBy,
                notes: notes
            )
            
            employee.leaves.append(leave)
            
            if let index = employees.firstIndex(where: { $0.id == employee.id }) {
                employees[index] = employee
                saveEmployees()
            }
        }
    }
    
    func addDutyRecord(startDate: Date,
                     endDate: Date,
                     notes: String? = nil,
                     overtime: Double = 0,
                     verifiedBy: String? = nil) {
        
        if var employee = filteredEmployees.first {
            let dutyRecord = DutyRecord(
                startDate: startDate,
                endDate: endDate,
                notes: notes,
                overtime: overtime,
                verifiedBy: verifiedBy
            )
            
            employee.dutyRecords.append(dutyRecord)
            
            if let index = employees.firstIndex(where: { $0.id == employee.id }) {
                employees[index] = employee
                saveEmployees()
            }
        }
    }
    
    // MARK: - Client Operations
    
    func addClient(_ client: Client) {
        clients.append(client)
        
        // Add reference to company
        if var company = activeCompany {
            company.clientIDs.append(client.id)
            updateCompany(company)
        }
        
        saveClients()
    }
    
    func updateClientDetails(at index: Int, 
                           name: String,
                           company: String,
                           companyDescription: String?,
                           email: String,
                           phone: String,
                           companyAddress: Address,
                           gstNumber: String?,
                           taxIdentificationNumber: String?,
                           registrationNumber: String?,
                           website: String?,
                           industry: String?) {
        
        let filteredClients = self.filteredClients
        guard index < filteredClients.count else { return }
        
        var client = filteredClients[index]
        
        // Update basic information
        client.name = name
        client.company = company
        client.companyDescription = companyDescription
        client.email = email
        client.phone = phone
        
        // Update company details
        client.companyAddress = companyAddress
        client.gstNumber = gstNumber
        client.taxIdentificationNumber = taxIdentificationNumber
        client.registrationNumber = registrationNumber
        client.website = website
        client.industry = industry
        
        // Update in master list
        if let masterIndex = clients.firstIndex(where: { $0.id == client.id }) {
            clients[masterIndex] = client
            saveClients()
        }
    }
    
    func addContactPerson(to clientIndex: Int, contactPerson: ContactPerson) {
        let filteredClients = self.filteredClients
        guard clientIndex < filteredClients.count else { return }
        
        var client = filteredClients[clientIndex]
        client.contactPersons.append(contactPerson)
        
        // Update in master list
        if let masterIndex = clients.firstIndex(where: { $0.id == client.id }) {
            clients[masterIndex] = client
            saveClients()
        }
    }
    
    func updateContactPerson(at clientIndex: Int, contactPersonIndex: Int, contactPerson: ContactPerson) {
        let filteredClients = self.filteredClients
        guard clientIndex < filteredClients.count else { return }
        
        var client = filteredClients[clientIndex]
        guard contactPersonIndex < client.contactPersons.count else { return }
        
        client.contactPersons[contactPersonIndex] = contactPerson
        
        // Update in master list
        if let masterIndex = clients.firstIndex(where: { $0.id == client.id }) {
            clients[masterIndex] = client
            saveClients()
        }
    }
    
    func deleteContactPerson(at clientIndex: Int, contactPersonIndex: Int) {
        let filteredClients = self.filteredClients
        guard clientIndex < filteredClients.count else { return }
        
        var client = filteredClients[clientIndex]
        guard contactPersonIndex < client.contactPersons.count else { return }
        
        client.contactPersons.remove(at: contactPersonIndex)
        
        // Update in master list
        if let masterIndex = clients.firstIndex(where: { $0.id == client.id }) {
            clients[masterIndex] = client
            saveClients()
        }
    }

    func addProjectWithDetails(to clientIndex: Int, 
                              name: String,
                              description: String,
                              startDate: Date,
                              endDate: Date?,
                              contractAmount: Double,
                              projectManager: String?,
                              contractReference: String?,
                              contractDate: Date?,
                              status: ProjectStatus = .active) {
        
        let filteredClients = self.filteredClients
        guard clientIndex < filteredClients.count else { return }
        
        var project = Project(
            name: name,
            description: description,
            startDate: startDate,
            endDate: endDate,
            contractAmount: contractAmount
        )
        
        // Set additional details
        project.projectManager = projectManager
        project.contractReference = contractReference
        project.contractDate = contractDate
        project.status = status
        
        // Find the client in the master list
        let client = filteredClients[clientIndex]
        if let masterIndex = clients.firstIndex(where: { $0.id == client.id }) {
            clients[masterIndex].projects.append(project)
            saveClients()
        }
    }
    
    func addProjectMilestone(to clientIndex: Int, projectIndex: Int, milestone: ProjectMilestone) {
        let filteredClients = self.filteredClients
        guard clientIndex < filteredClients.count else { return }
        
        let client = filteredClients[clientIndex]
        guard projectIndex < client.projects.count else { return }
        
        // Find the client in the master list
        if let masterIndex = clients.firstIndex(where: { $0.id == client.id }) {
            if clients[masterIndex].projects[projectIndex].milestones == nil {
                clients[masterIndex].projects[projectIndex].milestones = []
            }
            clients[masterIndex].projects[projectIndex].milestones?.append(milestone)
            saveClients()
        }
    }
    
    func addDetailedPayment(to clientIndex: Int, 
                           projectIndex: Int, 
                           amount: Double,
                           date: Date,
                           notes: String,
                           paymentType: ProjectPayment.PaymentType,
                           referenceNumber: String?,
                           paymentMethod: ProjectPayment.PaymentMethod) {
        
        let filteredClients = self.filteredClients
        guard clientIndex < filteredClients.count else { return }
        
        let client = filteredClients[clientIndex]
        guard projectIndex < client.projects.count else { return }
        
        let payment = ProjectPayment(
            amount: amount,
            date: date,
            notes: notes,
            paymentType: paymentType,
            referenceNumber: referenceNumber,
            paymentMethod: paymentMethod
        )
        
        // Find the client in the master list
        if let masterIndex = clients.firstIndex(where: { $0.id == client.id }) {
            clients[masterIndex].projects[projectIndex].payments.append(payment)
            saveClients()
        }
    }
    
    // MARK: - Client Payment Operations

    func addDetailedClientPayment(to clientIndex: Int, 
                               projectIndex: Int, 
                               amount: Double,
                               date: Date,
                               notes: String,
                               paymentType: ProjectPayment.PaymentType,
                               paymentMethod: ProjectPayment.PaymentMethod,
                               referenceNumber: String? = nil,
                               receivedBy: String? = nil,
                               receivedFrom: String? = nil,
                               verifiedBy: String? = nil,
                               invoiceNumber: String? = nil,
                               bankDetails: BankTransferDetails? = nil) {
        
        let filteredClients = self.filteredClients
        guard clientIndex < filteredClients.count else { return }
        
        let client = filteredClients[clientIndex]
        guard projectIndex < client.projects.count else { return }
        
        var payment = ProjectPayment(
            amount: amount,
            date: date,
            notes: notes,
            paymentType: paymentType,
            paymentMethod: paymentMethod
        )
        
        // Set additional payment details
        payment.referenceNumber = referenceNumber
        payment.receivedBy = receivedBy
        payment.receivedFrom = receivedFrom
        payment.verifiedBy = verifiedBy
        payment.invoiceNumber = invoiceNumber
        payment.bankDetails = bankDetails
        
        // Find the client in the master list
        if let masterIndex = clients.firstIndex(where: { $0.id == client.id }) {
            clients[masterIndex].projects[projectIndex].payments.append(payment)
            saveClients()
        }
    }
    
    func addBankTransferPayment(to clientIndex: Int,
                              projectIndex: Int,
                              amount: Double,
                              date: Date,
                              notes: String,
                              paymentType: ProjectPayment.PaymentType,
                              bankName: String,
                              accountNumber: String,
                              transferDate: Date,
                              branchCode: String? = nil,
                              swiftCode: String? = nil,
                              receivedBy: String? = nil,
                              verifiedBy: String? = nil,
                              invoiceNumber: String? = nil) {
        
        let bankDetails = BankTransferDetails(
            bankName: bankName,
            accountNumber: accountNumber,
            transferDate: transferDate,
            branchCode: branchCode,
            swiftCode: swiftCode
        )
        
        addDetailedClientPayment(
            to: clientIndex,
            projectIndex: projectIndex,
            amount: amount,
            date: date,
            notes: notes,
            paymentType: paymentType,
            paymentMethod: .bankTransfer,
            receivedBy: receivedBy,
            verifiedBy: verifiedBy,
            invoiceNumber: invoiceNumber,
            bankDetails: bankDetails
        )
    }
    
    // MARK: - Generate Statements
    
    func generateSalarySlip(for period: DatePeriod, 
                         paymentMethod: PaymentMethod? = nil,
                         processedBy: String? = nil,
                         referenceNumber: String? = nil,
                         paymentDate: Date? = nil,
                         notes: String? = nil) -> SalarySlip {
        // Calculate base salary for the period
        let daysInPeriod = Calendar.current.dateComponents([.day], from: period.startDate, to: period.endDate).day ?? 0
        let totalMonthDays = 30.0 // Simplified assumption for a month
        let baseSalary = (Double(daysInPeriod) / totalMonthDays) * employee.monthlySalary
        
        // Calculate advances taken during this period
        let advancesInPeriod = employee.salaryAdvances.filter { 
            $0.date >= period.startDate && $0.date <= period.endDate
        }
        let advanceTotal = advancesInPeriod.reduce(0) { $0 + $1.amount }
        
        // Calculate bonuses and deductions from salary payments in this period
        let paymentsInPeriod = employee.salaryHistory.filter {
            $0.periodStart >= period.startDate && $0.periodEnd <= period.endDate
        }
        
        let bonusesTotal = paymentsInPeriod.reduce(0) { $0 + $1.bonuses }
        let deductionsTotal = paymentsInPeriod.reduce(0) { $0 + $1.deductions }
        
        // Get payment method details
        var paymentMethodString: String? = nil
        if let method = paymentMethod {
            paymentMethodString = method.rawValue
        } else if let lastPayment = paymentsInPeriod.last {
            // Use the most recent payment's method if available
            paymentMethodString = lastPayment.paymentMethod.rawValue
        }
        
        // Get processor information
        var processorString: String? = nil
        if let processor = processedBy, !processor.isEmpty {
            processorString = processor
        } else if let lastPayment = paymentsInPeriod.last, !lastPayment.processedBy.isEmpty {
            // Use the most recent payment's processor if available
            processorString = lastPayment.processedBy
        }
        
        // Create the salary slip
        let salarySlip = SalarySlip(
            employeeName: employee.name,
            position: employee.position,
            period: period,
            baseSalary: baseSalary,
            bonuses: bonusesTotal,
            deductions: deductionsTotal,
            advances: advanceTotal,
            generatedDate: Date(),
            paymentMethod: paymentMethodString,
            processedBy: processorString,
            referenceNumber: referenceNumber,
            paymentDate: paymentDate,
            notes: notes
        )
        
        // Save the generated slip
        salarySlips.append(salarySlip)
        
        // Add reference to company
        if var company = activeCompany {
            company.salarySlipIDs.append(salarySlip.id)
            updateCompany(company)
        }
        
        saveSalarySlips()
        
        return salarySlip
    }
    
    func generateClientStatement(for clientIndex: Int, period: DatePeriod) -> ClientStatement? {
        let filteredClients = self.filteredClients
        guard clientIndex < filteredClients.count else { return nil }
        
        let client = filteredClients[clientIndex]
        var projectPayments: [ProjectPaymentSummary] = []
        
        // Process each project
        for project in client.projects {
            // Filter payments in this period
            let paymentsInPeriod = project.payments.filter {
                $0.date >= period.startDate && $0.date <= period.endDate
            }
            
            // If there are payments in this period, add to the statement
            if !paymentsInPeriod.isEmpty {
                let paymentRecords = paymentsInPeriod.map { payment in
                    PaymentRecord(
                        id: UUID(),
                        amount: payment.amount,
                        date: payment.date,
                        type: payment.paymentType.rawValue
                    )
                }
                
                let paidAmount = paymentsInPeriod.reduce(0) { $0 + $1.amount }
                
                let summary = ProjectPaymentSummary(
                    id: UUID(),
                    projectName: project.name,
                    contractAmount: project.contractAmount,
                    paidAmount: paidAmount,
                    payments: paymentRecords
                )
                
                projectPayments.append(summary)
            }
        }
        
        // Only generate a statement if there are payments
        if !projectPayments.isEmpty {
            let statement = ClientStatement(
                id: UUID(),
                clientName: client.name,
                company: client.company,
                period: period,
                projectPayments: projectPayments,
                generatedDate: Date()
            )
            
            // Save the generated statement
            clientStatements.append(statement)
            
            // Add reference to company
            if var company = activeCompany {
                company.clientStatementIDs.append(statement.id)
                updateCompany(company)
            }
            
            saveClientStatements()
            
            return statement
        }
        
        return nil
    }
    
    // MARK: - Data Persistence
    
    private func saveCompanies() {
        do {
            let data = try JSONEncoder().encode(companies)
            try data.write(to: getDocumentsDirectory().appendingPathComponent(companiesFileName))
        } catch {
            print("Failed to save companies data: \(error)")
        }
    }
    
    private func saveEmployees() {
        do {
            let data = try JSONEncoder().encode(employees)
            try data.write(to: getDocumentsDirectory().appendingPathComponent(employeesFileName))
        } catch {
            print("Failed to save employees data: \(error)")
        }
    }
    
    private func saveClients() {
        do {
            let data = try JSONEncoder().encode(clients)
            try data.write(to: getDocumentsDirectory().appendingPathComponent(clientsFileName))
        } catch {
            print("Failed to save clients data: \(error)")
        }
    }
    
    private func saveSalarySlips() {
        do {
            let data = try JSONEncoder().encode(salarySlips)
            try data.write(to: getDocumentsDirectory().appendingPathComponent(salarySlipsFileName))
        } catch {
            print("Failed to save salary slips: \(error)")
        }
    }
    
    private func saveClientStatements() {
        do {
            let data = try JSONEncoder().encode(clientStatements)
            try data.write(to: getDocumentsDirectory().appendingPathComponent(clientStatementsFileName))
        } catch {
            print("Failed to save client statements: \(error)")
        }
    }
    
    private func saveExpenses() {
        do {
            let data = try JSONEncoder().encode(companyExpenses)
            try data.write(to: getDocumentsDirectory().appendingPathComponent(expensesFileName))
        } catch {
            print("Failed to save company expenses: \(error)")
        }
    }
    
    private func saveExpenseReports() {
        do {
            let data = try JSONEncoder().encode(expenseReports)
            try data.write(to: getDocumentsDirectory().appendingPathComponent(expenseReportsFileName))
        } catch {
            print("Failed to save expense reports: \(error)")
        }
    }
    
    private func saveAccountBalance() {
        if let account = personalAccount {
            do {
                let data = try JSONEncoder().encode(account)
                try data.write(to: getDocumentsDirectory().appendingPathComponent(accountBalanceFileName))
            } catch {
                print("Failed to save account balance: \(error)")
            }
        }
    }
    
    private func loadCompanies() -> [Company]? {
        do {
            let fileURL = getDocumentsDirectory().appendingPathComponent(companiesFileName)
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([Company].self, from: data)
        } catch {
            print("Failed to load companies data: \(error)")
            return nil
        }
    }
    
    private func loadEmployees() -> [Employee]? {
        do {
            let fileURL = getDocumentsDirectory().appendingPathComponent(employeesFileName)
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([Employee].self, from: data)
        } catch {
            print("Failed to load employees data: \(error)")
            return nil
        }
    }
    
    private func loadClients() -> [Client]? {
        do {
            let fileURL = getDocumentsDirectory().appendingPathComponent(clientsFileName)
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([Client].self, from: data)
        } catch {
            print("Failed to load clients data: \(error)")
            return nil
        }
    }
    
    private func loadSalarySlips() -> [SalarySlip]? {
        do {
            let fileURL = getDocumentsDirectory().appendingPathComponent(salarySlipsFileName)
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([SalarySlip].self, from: data)
        } catch {
            print("Failed to load salary slips: \(error)")
            return nil
        }
    }
    
    private func loadClientStatements() -> [ClientStatement]? {
        do {
            let fileURL = getDocumentsDirectory().appendingPathComponent(clientStatementsFileName)
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([ClientStatement].self, from: data)
        } catch {
            print("Failed to load client statements: \(error)")
            return nil
        }
    }
    
    private func loadExpenses() -> [CompanyExpense]? {
        do {
            let fileURL = getDocumentsDirectory().appendingPathComponent(expensesFileName)
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([CompanyExpense].self, from: data)
        } catch {
            print("Failed to load company expenses: \(error)")
            return nil
        }
    }
    
    private func loadExpenseReports() -> [ExpenseReport]? {
        do {
            let fileURL = getDocumentsDirectory().appendingPathComponent(expenseReportsFileName)
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([ExpenseReport].self, from: data)
        } catch {
            print("Failed to load expense reports: \(error)")
            return nil
        }
    }
    
    private func loadAccountBalance() -> AccountBalance? {
        do {
            let fileURL = getDocumentsDirectory().appendingPathComponent(accountBalanceFileName)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                return try JSONDecoder().decode(AccountBalance.self, from: data)
            } else {
                return nil
            }
        } catch {
            print("Failed to load account balance: \(error)")
            return nil
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // MARK: - Sample Data
    
    private func initializeWithSampleData() {
        guard let company = activeCompany else { return }
        
        // Sample employee
        let employee = Employee(
            name: "John Doe",
            position: "Software Developer",
            monthlySalary: 5000,
            joinDate: Date().addingTimeInterval(-180 * 24 * 60 * 60) // 180 days ago
        )
        
        // Sample salary advance
        let advance = SalaryAdvance(
            amount: 1000,
            date: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30 days ago
            reason: "Personal expenses"
        )
        
        // Sample salary payment
        let payment = SalaryPayment(
            amount: 5000,
            date: Date().addingTimeInterval(-15 * 24 * 60 * 60), // 15 days ago
            periodStart: Date().addingTimeInterval(-45 * 24 * 60 * 60), // 45 days ago
            periodEnd: Date().addingTimeInterval(-15 * 24 * 60 * 60) // 15 days ago
        )
        
        // Sample leave
        let leave = Leave(
            startDate: Date().addingTimeInterval(-10 * 24 * 60 * 60), // 10 days ago
            endDate: Date().addingTimeInterval(-8 * 24 * 60 * 60), // 8 days ago
            reason: "Personal leave",
            isPaid: true
        )
        
        // Sample duty record
        let dutyRecord = DutyRecord(
            startDate: Date().addingTimeInterval(-60 * 24 * 60 * 60), // 60 days ago
            endDate: Date()
        )
        
        // Add to employee
        employee.salaryAdvances.append(advance)
        employee.salaryHistory.append(payment)
        employee.leaves.append(leave)
        employee.dutyRecords.append(dutyRecord)
        
        // Add employee to the data
        addEmployee(employee)
        
        // Sample client and project
        let projectPayment = ProjectPayment(
            amount: 2000,
            date: Date().addingTimeInterval(-20 * 24 * 60 * 60), // 20 days ago
            notes: "Initial payment",
            paymentType: .advance
        )
        
        var project = Project(
            name: "Website Redesign",
            description: "Complete redesign of company website",
            startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30 days ago
            endDate: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days from now
            contractAmount: 5000,
            payments: []
        )
        
        project.payments.append(projectPayment)
        
        var client = Client(
            name: "John Smith",
            company: "ABC Corporation",
            email: "john@example.com",
            phone: "555-1234"
        )
        
        client.projects.append(project)
        addClient(client)
        
        // Generate sample statements
        let lastMonthStart = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        let samplePeriod = DatePeriod(
            startDate: lastMonthStart,
            endDate: Date()
        )
        
        // Sample salary slip
        let sampleSlip = SalarySlip(
            employeeName: employee.name,
            position: employee.position,
            period: samplePeriod,
            baseSalary: 5000,
            bonuses: 500,
            deductions: 200,
            advances: 1000,
            generatedDate: Date()
        )
        salarySlips.append(sampleSlip)
        
        // Add reference to company
        if var updatedCompany = activeCompany {
            updatedCompany.salarySlipIDs.append(sampleSlip.id)
            updateCompany(updatedCompany)
        }
        
        // Sample client statement (if we have clients with payments)
        if !filteredClients.isEmpty {
            let projectSummary = ProjectPaymentSummary(
                id: UUID(),
                projectName: project.name,
                contractAmount: project.contractAmount,
                paidAmount: projectPayment.amount,
                payments: [
                    PaymentRecord(
                        id: UUID(),
                        amount: projectPayment.amount,
                        date: projectPayment.date,
                        type: projectPayment.paymentType.rawValue
                    )
                ]
            )
            
            let clientStatement = ClientStatement(
                id: UUID(),
                clientName: client.name,
                company: client.company,
                period: samplePeriod,
                projectPayments: [projectSummary],
                generatedDate: Date()
            )
            
            clientStatements.append(clientStatement)
            
            // Add reference to company
            if var updatedCompany = activeCompany {
                updatedCompany.clientStatementIDs.append(clientStatement.id)
                updateCompany(updatedCompany)
            }
        }
    }
    
    // MARK: - Company Expense Operations
    
    var filteredExpenses: [CompanyExpense] {
        guard let activeCompany = activeCompany else { return [] }
        return companyExpenses.filter { activeCompany.expenseIDs.contains($0.id) }
    }
    
    var filteredExpenseReports: [ExpenseReport] {
        guard let activeCompany = activeCompany else { return [] }
        return expenseReports.filter { activeCompany.expenseReportIDs.contains($0.id) }
    }
    
    func addCompanyExpense(title: String, 
                         description: String, 
                         amount: Double, 
                         category: ExpenseCategory, 
                         date: Date, 
                         paidBy: String, 
                         paidByEmployeeID: UUID, 
                         paymentMethod: PaymentMethod,
                         referenceNumber: String? = nil,
                         notes: String? = nil) -> CompanyExpense {
        
        let expense = CompanyExpense(
            title: title,
            description: description,
            amount: amount,
            category: category,
            date: date,
            paidBy: paidBy,
            paidByEmployeeID: paidByEmployeeID,
            paymentMethod: paymentMethod,
            referenceNumber: referenceNumber,
            notes: notes
        )
        
        companyExpenses.append(expense)
        
        // Add reference to company
        if var company = activeCompany {
            company.expenseIDs.append(expense.id)
            updateCompany(company)
        }
        
        saveExpenses()
        return expense
    }
    
    func updateCompanyExpense(_ expense: CompanyExpense) {
        if let index = companyExpenses.firstIndex(where: { $0.id == expense.id }) {
            companyExpenses[index] = expense
            saveExpenses()
        }
    }
    
    func deleteCompanyExpense(at index: Int) {
        let filteredExpenses = self.filteredExpenses
        guard index < filteredExpenses.count else { return }
        
        // Find and remove from master list
        let expenseToDelete = filteredExpenses[index]
        if let masterIndex = companyExpenses.firstIndex(where: { $0.id == expenseToDelete.id }) {
            companyExpenses.remove(at: masterIndex)
        }
        
        // Remove ID from company
        if var company = activeCompany, let idIndex = company.expenseIDs.firstIndex(of: expenseToDelete.id) {
            company.expenseIDs.remove(at: idIndex)
            updateCompany(company)
        }
        
        saveExpenses()
    }
    
    func approveExpense(at index: Int, approvedBy: String) {
        let filteredExpenses = self.filteredExpenses
        guard index < filteredExpenses.count else { return }
        
        var expense = filteredExpenses[index]
        expense.status = .approved
        expense.approvedBy = approvedBy
        
        updateCompanyExpense(expense)
    }
    
    func markExpenseAsReimbursed(at index: Int, date: Date) {
        let filteredExpenses = self.filteredExpenses
        guard index < filteredExpenses.count else { return }
        
        var expense = filteredExpenses[index]
        expense.status = .reimbursed
        expense.reimbursementDate = date
        
        updateCompanyExpense(expense)
    }
    
    func rejectExpense(at index: Int, approvedBy: String) {
        let filteredExpenses = self.filteredExpenses
        guard index < filteredExpenses.count else { return }
        
        var expense = filteredExpenses[index]
        expense.status = .rejected
        expense.approvedBy = approvedBy
        
        updateCompanyExpense(expense)
    }
    
    // MARK: - Expense Report Operations
    
    func createExpenseReport(title: String, 
                           period: DatePeriod, 
                           employeeID: UUID, 
                           employeeName: String,
                           expenseIDs: [UUID] = [],
                           notes: String? = nil) -> ExpenseReport {
        
        // Calculate total from all included expenses
        let totalAmount = expenseIDs.reduce(0.0) { total, expenseID in
            if let expense = companyExpenses.first(where: { $0.id == expenseID }) {
                return total + expense.amount
            }
            return total
        }
        
        let report = ExpenseReport(
            title: title,
            period: period,
            employeeID: employeeID,
            employeeName: employeeName,
            expenseIDs: expenseIDs,
            totalAmount: totalAmount,
            submissionDate: Date(),
            notes: notes
        )
        
        expenseReports.append(report)
        
        // Add reference to company
        if var company = activeCompany {
            company.expenseReportIDs.append(report.id)
            updateCompany(company)
        }
        
        saveExpenseReports()
        return report
    }
    
    func updateExpenseReport(_ report: ExpenseReport) {
        if let index = expenseReports.firstIndex(where: { $0.id == report.id }) {
            expenseReports[index] = report
            saveExpenseReports()
        }
    }
    
    func deleteExpenseReport(at index: Int) {
        let filteredReports = self.filteredExpenseReports
        guard index < filteredReports.count else { return }
        
        // Find and remove from master list
        let reportToDelete = filteredReports[index]
        if let masterIndex = expenseReports.firstIndex(where: { $0.id == reportToDelete.id }) {
            expenseReports.remove(at: masterIndex)
        }
        
        // Remove ID from company
        if var company = activeCompany, let idIndex = company.expenseReportIDs.firstIndex(of: reportToDelete.id) {
            company.expenseReportIDs.remove(at: idIndex)
            updateCompany(company)
        }
        
        saveExpenseReports()
    }
    
    func approveExpenseReport(at index: Int, approvedBy: String) {
        let filteredReports = self.filteredExpenseReports
        guard index < filteredReports.count else { return }
        
        var report = filteredReports[index]
        report.status = .approved
        report.approvedBy = approvedBy
        report.approvalDate = Date()
        
        updateExpenseReport(report)
    }
    
    func markExpenseReportAsReimbursed(at index: Int, 
                                   date: Date, 
                                   method: PaymentMethod, 
                                   referenceNumber: String? = nil) {
        let filteredReports = self.filteredExpenseReports
        guard index < filteredReports.count else { return }
        
        var report = filteredReports[index]
        report.status = .reimbursed
        report.reimbursementDate = date
        report.reimbursementMethod = method
        report.reimbursementReferenceNumber = referenceNumber
        
        updateExpenseReport(report)
    }
    
    func addExpenseToReport(expenseID: UUID, reportIndex: Int) {
        let filteredReports = self.filteredExpenseReports
        guard reportIndex < filteredReports.count else { return }
        
        var report = filteredReports[reportIndex]
        
        // Only add if not already in the report
        if !report.expenseIDs.contains(expenseID) {
            report.expenseIDs.append(expenseID)
            
            // Recalculate total amount
            if let expense = companyExpenses.first(where: { $0.id == expenseID }) {
                report.totalAmount += expense.amount
            }
            
            updateExpenseReport(report)
        }
    }
    
    func removeExpenseFromReport(expenseIndex: Int, reportIndex: Int) {
        let filteredReports = self.filteredExpenseReports
        guard reportIndex < filteredReports.count else { return }
        
        var report = filteredReports[reportIndex]
        guard expenseIndex < report.expenseIDs.count else { return }
        
        let expenseID = report.expenseIDs[expenseIndex]
        report.expenseIDs.remove(at: expenseIndex)
        
        // Recalculate total amount
        if let expense = companyExpenses.first(where: { $0.id == expenseID }) {
            report.totalAmount -= expense.amount
        }
        
        updateExpenseReport(report)
    }
    
    // MARK: - Personal Account Management
    
    func addPersonalFundsTransaction(amount: Double,
                                  description: String,
                                  type: TransactionType,
                                  date: Date = Date(),
                                  relatedExpenseID: UUID? = nil,
                                  relatedEmployeeID: UUID? = nil,
                                  paymentMethod: PaymentMethod? = nil,
                                  referenceNumber: String? = nil,
                                  notes: String? = nil) -> AccountTransaction {
        
        guard var account = personalAccount else {
            // Create a new account if one doesn't exist
            self.personalAccount = AccountBalance(ownerName: "My Account")
            return addPersonalFundsTransaction(amount: amount, 
                                           description: description, 
                                           type: type, 
                                           date: date, 
                                           relatedExpenseID: relatedExpenseID, 
                                           relatedEmployeeID: relatedEmployeeID, 
                                           paymentMethod: paymentMethod, 
                                           referenceNumber: referenceNumber, 
                                           notes: notes)
        }
        
        let transaction = AccountTransaction(
            date: date,
            amount: amount,
            description: description,
            type: type,
            relatedExpenseID: relatedExpenseID,
            relatedEmployeeID: relatedEmployeeID,
            paymentMethod: paymentMethod,
            referenceNumber: referenceNumber,
            notes: notes
        )
        
        account.addTransaction(transaction)
        personalAccount = account
        saveAccountBalance()
        
        return transaction
    }
    
    func updatePersonalTransactionStatus(transactionID: UUID, 
                                      status: TransactionStatus, 
                                      reimbursementDate: Date? = nil) {
        guard var account = personalAccount else { return }
        account.updateTransactionStatus(id: transactionID, 
                                     status: status, 
                                     reimbursementDate: reimbursementDate)
        personalAccount = account
        saveAccountBalance()
    }
    
    func getPersonalAccountStatement(startDate: Date? = nil, endDate: Date? = nil) -> [AccountTransaction] {
        guard let account = personalAccount else { return [] }
        
        // If no dates specified, return all transactions
        if startDate == nil && endDate == nil {
            return account.transactions.sorted(by: { $0.date > $1.date })
        }
        
        // Filter by date range
        return account.transactions.filter { transaction in
            var includeTransaction = true
            
            if let start = startDate {
                includeTransaction = includeTransaction && transaction.date >= start
            }
            
            if let end = endDate {
                includeTransaction = includeTransaction && transaction.date <= end
            }
            
            return includeTransaction
        }.sorted(by: { $0.date > $1.date })
    }
    
    // MARK: - Enhanced Salary Payment with Personal Account Tracking
    
    func addSalaryPaymentWithAccountTracking(
                        amount: Double,
                        date: Date,
                        periodStart: Date,
                        periodEnd: Date,
                        employeeID: UUID? = nil,
                        bonuses: Double = 0,
                        deductions: Double = 0,
                        paymentMethod: PaymentMethod = .bankTransfer,
                        processedBy: String = "",
                        paidFromPersonalFunds: Bool = false,
                        referenceNumber: String? = nil,
                        notes: String? = nil) {
        
        // Use the specified employee ID or default to the first employee
        let targetEmployeeID = employeeID ?? filteredEmployees.first?.id
        
        guard let employeeID = targetEmployeeID else { return }
        
        // Find the employee
        guard let employeeIndex = employees.firstIndex(where: { $0.id == employeeID }) else { return }
        let employee = employees[employeeIndex]
        
        // 1. Record the salary payment in employee's history using existing method
        addSalaryPayment(
            amount: amount,
            date: date,
            periodStart: periodStart,
            periodEnd: periodEnd,
            bonuses: bonuses,
            deductions: deductions,
            paymentMethod: paymentMethod,
            processedBy: processedBy,
            referenceNumber: referenceNumber,
            notes: notes
        )
        
        // 2. Track the payment as a company expense
        let expense = recordSalaryPaymentAsExpense(
            employeeID: employeeID,
            employeeName: employee.name,
            amount: amount + bonuses - deductions,
            date: date,
            paymentMethod: paymentMethod,
            referenceNumber: referenceNumber
        )
        
        // 3. Add to personal account if paid from personal funds
        if paidFromPersonalFunds {
            let totalAmount = amount + bonuses - deductions
            let description = "Salary payment to \(employee.name)"
            let transactionNotes = notes ?? "Salary period: \(Formatters.formatDate(periodStart)) - \(Formatters.formatDate(periodEnd))"
            
            _ = addPersonalFundsTransaction(
                amount: totalAmount, // Positive amount means money spent
                description: description,
                type: .salaryPayment,
                date: date,
                relatedExpenseID: expense.id,
                relatedEmployeeID: employeeID,
                paymentMethod: paymentMethod,
                referenceNumber: referenceNumber,
                notes: transactionNotes
            )
        }
    }
    
    // Enhanced expense tracking with personal funds
    func addCompanyExpenseWithPersonalFunds(
                         title: String, 
                         description: String, 
                         amount: Double, 
                         category: ExpenseCategory, 
                         date: Date, 
                         paidBy: String, 
                         paidByEmployeeID: UUID, 
                         paymentMethod: PaymentMethod,
                         paidFromPersonalFunds: Bool = false,
                         referenceNumber: String? = nil,
                         notes: String? = nil) -> CompanyExpense {
        
        // Record the company expense
        let expense = addCompanyExpense(
            title: title,
            description: description,
            amount: amount,
            category: category,
            date: date,
            paidBy: paidBy,
            paidByEmployeeID: paidByEmployeeID,
            paymentMethod: paymentMethod,
            referenceNumber: referenceNumber,
            notes: notes
        )
        
        // Add to personal account if paid from personal funds
        if paidFromPersonalFunds {
            _ = addPersonalFundsTransaction(
                amount: amount, // Positive amount means money spent
                description: title,
                type: .expensePayment,
                date: date,
                relatedExpenseID: expense.id,
                relatedEmployeeID: paidByEmployeeID,
                paymentMethod: paymentMethod,
                referenceNumber: referenceNumber,
                notes: notes
            )
        }
        
        return expense
    }
    
    // Record company reimbursement to personal account
    func recordReimbursementToPersonalAccount(
                         amount: Double,
                         date: Date = Date(),
                         description: String = "Company Reimbursement",
                         paymentMethod: PaymentMethod = .bankTransfer,
                         referenceNumber: String? = nil,
                         notes: String? = nil) -> AccountTransaction {
        
        return addPersonalFundsTransaction(
            amount: -amount, // Negative amount means money received
            description: description,
            type: .companyReimbursement,
            date: date,
            paymentMethod: paymentMethod,
            referenceNumber: referenceNumber,
            notes: notes
        )
    }
    
    // Generate a salary slip with personal account tracking
    func generateSalarySlipWithAccountTracking(
                         for period: DatePeriod,
                         employeeID: UUID? = nil,
                         paymentMethod: PaymentMethod = .bankTransfer,
                         processedBy: String = "",
                         paidFromPersonalFunds: Bool = false,
                         referenceNumber: String? = nil,
                         paymentDate: Date? = Date(),
                         notes: String? = nil) -> SalarySlip {
        
        // Use the specified employee ID or default to the first employee
        let targetEmployeeID = employeeID ?? filteredEmployees.first?.id
        
        guard let employeeID = targetEmployeeID,
              let employee = employees.first(where: { $0.id == employeeID }) else {
            // Fall back to standard method if employee not found
            return generateSalarySlip(for: period, 
                                    paymentMethod: paymentMethod,
                                    processedBy: processedBy,
                                    referenceNumber: referenceNumber,
                                    paymentDate: paymentDate,
                                    notes: notes)
        }
        
        // Generate the salary slip using the existing method
        let salarySlip = generateSalarySlip(
            for: period,
            paymentMethod: paymentMethod,
            processedBy: processedBy,
            referenceNumber: referenceNumber,
            paymentDate: paymentDate,
            notes: notes
        )
        
        // Track the payment as a company expense
        if let payDate = paymentDate {
            let expense = recordSalaryPaymentAsExpense(
                employeeID: employeeID,
                employeeName: employee.name,
                amount: salarySlip.netSalary,
                date: payDate,
                paymentMethod: paymentMethod,
                referenceNumber: referenceNumber
            )
            
            // Add to personal account if paid from personal funds
            if paidFromPersonalFunds {
                let description = "Salary payment to \(employee.name) per slip"
                let transactionNotes = notes ?? "Salary period: \(Formatters.formatDate(period.startDate)) - \(Formatters.formatDate(period.endDate))"
                
                _ = addPersonalFundsTransaction(
                    amount: salarySlip.netSalary,
                    description: description,
                    type: .salaryPayment,
                    date: payDate,
                    relatedExpenseID: expense.id,
                    relatedEmployeeID: employeeID,
                    paymentMethod: paymentMethod,
                    referenceNumber: referenceNumber,
                    notes: transactionNotes
                )
            }
        }
        
        return salarySlip
    }
    
    // MARK: - Helper Functions for Salary as Expense
    
    func recordSalaryPaymentAsExpense(employeeID: UUID, 
                                    employeeName: String,
                                    amount: Double,
                                    date: Date,
                                    paymentMethod: PaymentMethod,
                                    referenceNumber: String? = nil) -> CompanyExpense {
        
        return addCompanyExpense(
            title: "Salary Payment",
            description: "Salary payment for \(employeeName)",
            amount: amount,
            category: .other, // You might want to add a specific category for salaries
            date: date,
            paidBy: activeCompany?.name ?? "Company",
            paidByEmployeeID: employeeID,
            paymentMethod: paymentMethod,
            referenceNumber: referenceNumber,
            notes: "Regular salary payment"
        )
    }
    
    func rejectExpenseReport(at index: Int, approvedBy: String) {
        let filteredReports = self.filteredExpenseReports
        guard index < filteredReports.count else { return }
        
        var report = filteredReports[index]
        report.status = .rejected
        report.approvedBy = approvedBy
        report.approvalDate = Date()
        
        updateExpenseReport(report)
    }
} 