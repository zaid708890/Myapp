import SwiftUI

struct PersonalAccountView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTransactionSheet = false
    @State private var showingAddReimbursementSheet = false
    @State private var selectedTransaction: AccountTransaction?
    @State private var showingTransactionDetail = false
    @State private var dateFilter: DateFilterOption = .allTime
    @State private var showingDateRangeSelector = false
    @State private var customStartDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
    @State private var customEndDate = Date()
    
    enum DateFilterOption: String, CaseIterable {
        case allTime = "All Time"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case thisYear = "This Year"
        case custom = "Custom Range"
        
        var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
    }
    
    var filteredTransactions: [AccountTransaction] {
        guard let account = dataManager.personalAccount else { return [] }
        
        switch dateFilter {
        case .allTime:
            return dataManager.getPersonalAccountStatement()
        case .thisMonth:
            let start = Date().startOfMonth
            let end = Date().endOfMonth
            return dataManager.getPersonalAccountStatement(startDate: start, endDate: end)
        case .lastMonth:
            let start = Calendar.current.date(byAdding: .month, value: -1, to: Date().startOfMonth) ?? Date()
            let end = Calendar.current.date(byAdding: .day, value: -1, to: Date().startOfMonth) ?? Date()
            return dataManager.getPersonalAccountStatement(startDate: start, endDate: end)
        case .thisYear:
            let start = Date().startOfYear
            let end = Date().endOfYear
            return dataManager.getPersonalAccountStatement(startDate: start, endDate: end)
        case .custom:
            return dataManager.getPersonalAccountStatement(startDate: customStartDate, endDate: customEndDate)
        }
    }
    
    var pendingAmount: Double {
        filteredTransactions.filter { $0.status == .pending }.reduce(0) { $0 + $1.amount }
    }
    
    var reimbursedAmount: Double {
        filteredTransactions.filter { $0.status == .reimbursed }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        List {
            // Account Summary Section
            Section(header: Text("Account Summary")) {
                if let account = dataManager.personalAccount {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Pending (Unreimbursed)")
                                .font(.headline)
                            Spacer()
                            Text(Formatters.formatCurrency(pendingAmount))
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Reimbursed")
                                .font(.headline)
                            Spacer()
                            Text(Formatters.formatCurrency(reimbursedAmount))
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Net Account Balance")
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                            Text(account.formattedTotalBalance)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(account.totalBalance < 0 ? .green : .red)
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    Text("No account information available")
                }
            }
            
            // Date Filter Section
            Section(header: Text("Date Filter")) {
                Picker("Filter by", selection: $dateFilter) {
                    ForEach(DateFilterOption.allCases, id: \.self) { option in
                        Text(option.localizedName).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: dateFilter) { _ in
                    if dateFilter == .custom {
                        showingDateRangeSelector = true
                    }
                }
                
                if dateFilter == .custom {
                    Button("Set Custom Date Range") {
                        showingDateRangeSelector = true
                    }
                }
            }
            
            // Transactions Section
            Section(header: Text("Transactions")) {
                if filteredTransactions.isEmpty {
                    Text("No transactions in this period")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(filteredTransactions) { transaction in
                        TransactionRowView(transaction: transaction)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTransaction = transaction
                                showingTransactionDetail = true
                            }
                    }
                }
            }
            
            // Action Section
            Section {
                Button(action: {
                    showingAddTransactionSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Transaction")
                    }
                }
                
                Button(action: {
                    showingAddReimbursementSheet = true
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Record Reimbursement")
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Personal Account")
        .sheet(isPresented: $showingAddTransactionSheet) {
            NavigationView {
                AddTransactionView()
                    .environmentObject(dataManager)
                    .navigationTitle("Add Transaction")
            }
        }
        .sheet(isPresented: $showingAddReimbursementSheet) {
            NavigationView {
                AddReimbursementView()
                    .environmentObject(dataManager)
                    .navigationTitle("Record Reimbursement")
            }
        }
        .sheet(isPresented: $showingTransactionDetail) {
            if let transaction = selectedTransaction {
                NavigationView {
                    TransactionDetailView(transaction: transaction)
                        .environmentObject(dataManager)
                        .navigationTitle("Transaction Details")
                }
            }
        }
        .sheet(isPresented: $showingDateRangeSelector) {
            NavigationView {
                DateRangeSelectorView(startDate: $customStartDate, endDate: $customEndDate)
                    .navigationTitle("Custom Date Range")
            }
        }
    }
}

struct TransactionRowView: View {
    let transaction: AccountTransaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(transaction.description)
                    .font(.headline)
                Spacer()
                Text(transaction.formattedAmount)
                    .font(.headline)
                    .foregroundColor(transaction.amount < 0 ? .green : .red)
            }
            
            HStack {
                Text(transaction.type.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(transaction.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if let method = transaction.paymentMethod {
                    Text(method.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(transaction.status.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(transaction.statusColor)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TransactionDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    @State var transaction: AccountTransaction
    @State private var showingMarkReimbursedSheet = false
    
    var body: some View {
        Form {
            Section(header: Text("Transaction Details")) {
                HStack {
                    Text("Description")
                    Spacer()
                    Text(transaction.description)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(transaction.formattedAmount)
                        .foregroundColor(transaction.amount < 0 ? .green : .red)
                }
                
                HStack {
                    Text("Date")
                    Spacer()
                    Text(transaction.formattedDate)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Type")
                    Spacer()
                    Text(transaction.type.rawValue)
                        .foregroundColor(.secondary)
                }
                
                if let method = transaction.paymentMethod {
                    HStack {
                        Text("Payment Method")
                        Spacer()
                        Text(method.rawValue)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let reference = transaction.referenceNumber {
                    HStack {
                        Text("Reference Number")
                        Spacer()
                        Text(reference)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Status")) {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(transaction.status.rawValue)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(transaction.statusColor)
                        .cornerRadius(4)
                }
                
                if let date = transaction.reimbursementDate {
                    HStack {
                        Text("Reimbursement Date")
                        Spacer()
                        Text(Formatters.formatDate(date))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let notes = transaction.notes {
                Section(header: Text("Notes")) {
                    Text(notes)
                        .foregroundColor(.secondary)
                }
            }
            
            if transaction.status == .pending && transaction.amount > 0 {
                Section {
                    Button(action: {
                        showingMarkReimbursedSheet = true
                    }) {
                        Text("Mark as Reimbursed")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                .listRowInsets(EdgeInsets())
                .padding()
            }
        }
        .sheet(isPresented: $showingMarkReimbursedSheet) {
            NavigationView {
                MarkReimbursedView(transaction: transaction) { updatedTransaction in
                    self.transaction = updatedTransaction
                }
                .navigationTitle("Mark as Reimbursed")
            }
        }
    }
}

struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var description = ""
    @State private var amount = ""
    @State private var transactionType = TransactionType.expensePayment
    @State private var date = Date()
    @State private var paymentMethod = PaymentMethod.cash
    @State private var referenceNumber = ""
    @State private var notes = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Transaction Details")) {
                TextField("Description", text: $description)
                
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                
                Picker("Type", selection: $transactionType) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            
            Section(header: Text("Payment Details")) {
                Picker("Payment Method", selection: $paymentMethod) {
                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                
                TextField("Reference Number", text: $referenceNumber)
                
                TextField("Notes", text: $notes)
            }
            
            Section {
                Button(action: addTransaction) {
                    Text("Save Transaction")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .listRowInsets(EdgeInsets())
            .padding()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .navigationBarItems(
            leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
        )
    }
    
    private func addTransaction() {
        guard !description.isEmpty else {
            alertMessage = "Please enter a description"
            showAlert = true
            return
        }
        
        guard let amountValue = Double(amount), amountValue > 0 else {
            alertMessage = "Please enter a valid amount"
            showAlert = true
            return
        }
        
        _ = dataManager.addPersonalFundsTransaction(
            amount: amountValue,
            description: description,
            type: transactionType,
            date: date,
            paymentMethod: paymentMethod,
            referenceNumber: referenceNumber.isEmpty ? nil : referenceNumber,
            notes: notes.isEmpty ? nil : notes
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddReimbursementView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var amount = ""
    @State private var description = "Company Reimbursement"
    @State private var date = Date()
    @State private var paymentMethod = PaymentMethod.bankTransfer
    @State private var referenceNumber = ""
    @State private var notes = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Reimbursement Details")) {
                TextField("Amount Received", text: $amount)
                    .keyboardType(.decimalPad)
                
                TextField("Description", text: $description)
                
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            
            Section(header: Text("Payment Details")) {
                Picker("Payment Method", selection: $paymentMethod) {
                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                
                TextField("Reference Number", text: $referenceNumber)
                
                TextField("Notes", text: $notes)
            }
            
            Section {
                Button(action: addReimbursement) {
                    Text("Record Reimbursement")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            .listRowInsets(EdgeInsets())
            .padding()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .navigationBarItems(
            leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
        )
    }
    
    private func addReimbursement() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            alertMessage = "Please enter a valid amount"
            showAlert = true
            return
        }
        
        _ = dataManager.recordReimbursementToPersonalAccount(
            amount: amountValue,
            date: date,
            description: description,
            paymentMethod: paymentMethod,
            referenceNumber: referenceNumber.isEmpty ? nil : referenceNumber,
            notes: notes.isEmpty ? nil : notes
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct MarkReimbursedView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    @State var transaction: AccountTransaction
    var onUpdate: (AccountTransaction) -> Void
    
    @State private var reimbursementDate = Date()
    @State private var referenceNumber = ""
    
    var body: some View {
        Form {
            Section(header: Text("Transaction Information")) {
                HStack {
                    Text("Description")
                    Spacer()
                    Text(transaction.description)
                }
                
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(transaction.formattedAmount)
                }
            }
            
            Section(header: Text("Reimbursement Details")) {
                DatePicker("Reimbursement Date", selection: $reimbursementDate, displayedComponents: .date)
                
                TextField("Reference Number", text: $referenceNumber)
            }
            
            Section {
                Button(action: {
                    markAsReimbursed()
                }) {
                    Text("Mark as Reimbursed")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            .listRowInsets(EdgeInsets())
            .padding()
        }
        .navigationBarItems(
            leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
        )
    }
    
    private func markAsReimbursed() {
        dataManager.updatePersonalTransactionStatus(
            transactionID: transaction.id,
            status: .reimbursed,
            reimbursementDate: reimbursementDate
        )
        
        var updatedTransaction = transaction
        updatedTransaction.status = .reimbursed
        updatedTransaction.reimbursementDate = reimbursementDate
        if !referenceNumber.isEmpty {
            updatedTransaction.referenceNumber = referenceNumber
        }
        
        onUpdate(updatedTransaction)
        presentationMode.wrappedValue.dismiss()
    }
}

struct DateRangeSelectorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    var body: some View {
        Form {
            Section(header: Text("Date Range")) {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }
            
            Section {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Apply Date Range")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .listRowInsets(EdgeInsets())
            .padding()
        }
    }
}

// MARK: - Date Extensions
extension Date {
    var startOfYear: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components)!
    }
    
    var endOfYear: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 1
        components.day = -1
        return calendar.date(byAdding: components, to: self.startOfYear)!
    }
}

struct PersonalAccountView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PersonalAccountView()
                .environmentObject(DataManager())
        }
    }
} 