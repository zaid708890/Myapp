import SwiftUI

struct ExpenseManagementView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddExpenseSheet = false
    @State private var selectedExpenseIndex: Int?
    @State private var showingExpenseDetailSheet = false
    
    var body: some View {
        List {
            Section(header: Text("Company Expenses")) {
                if dataManager.filteredExpenses.isEmpty {
                    Text("No expenses recorded")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(Array(dataManager.filteredExpenses.enumerated()), id: \.element.id) { index, expense in
                        ExpenseRowView(expense: expense)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedExpenseIndex = index
                                showingExpenseDetailSheet = true
                            }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            dataManager.deleteCompanyExpense(at: index)
                        }
                    }
                }
            }
            
            Section {
                Button(action: {
                    showingAddExpenseSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New Expense")
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Expense Management")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddExpenseSheet) {
            NavigationView {
                AddExpenseView()
                    .environmentObject(dataManager)
                    .navigationTitle("Add Expense")
            }
        }
        .sheet(isPresented: $showingExpenseDetailSheet) {
            if let index = selectedExpenseIndex {
                NavigationView {
                    ExpenseDetailView(expense: dataManager.filteredExpenses[index])
                        .environmentObject(dataManager)
                        .navigationTitle("Expense Details")
                }
            }
        }
    }
}

struct ExpenseRowView: View {
    let expense: CompanyExpense
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(expense.title)
                    .font(.headline)
                Spacer()
                Text(expense.formattedAmount)
                    .font(.headline)
                    .foregroundColor(expense.status == .rejected ? .red : .primary)
            }
            
            HStack {
                Text(expense.category.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(expense.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Paid by: \(expense.paidBy)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(expense.status.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(expense.statusColor)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddExpenseView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var amount = ""
    @State private var category = ExpenseCategory.other
    @State private var date = Date()
    @State private var paymentMethod = PaymentMethod.cash
    @State private var referenceNumber = ""
    @State private var notes = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Expense Details")) {
                TextField("Title", text: $title)
                
                TextField("Description", text: $description)
                
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                
                Picker("Category", selection: $category) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
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
                Button(action: addExpense) {
                    Text("Save Expense")
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func addExpense() {
        guard !title.isEmpty else {
            alertMessage = "Please enter a title"
            showAlert = true
            return
        }
        
        guard let amountValue = Double(amount), amountValue > 0 else {
            alertMessage = "Please enter a valid amount"
            showAlert = true
            return
        }
        
        // Use the current employee's ID or default if none
        let employeeID = dataManager.filteredEmployees.first?.id ?? UUID()
        let employeeName = dataManager.filteredEmployees.first?.name ?? "Unknown"
        
        _ = dataManager.addCompanyExpense(
            title: title,
            description: description,
            amount: amountValue,
            category: category,
            date: date,
            paidBy: employeeName,
            paidByEmployeeID: employeeID,
            paymentMethod: paymentMethod,
            referenceNumber: referenceNumber.isEmpty ? nil : referenceNumber,
            notes: notes.isEmpty ? nil : notes
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct ExpenseDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @State var expense: CompanyExpense
    @State private var showingEditSheet = false
    @State private var showingApprovalSheet = false
    
    var body: some View {
        Form {
            Section(header: Text("Expense Information")) {
                HStack {
                    Text("Title")
                    Spacer()
                    Text(expense.title)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Description")
                    Spacer()
                    Text(expense.description)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(expense.formattedAmount)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Category")
                    Spacer()
                    Text(expense.category.rawValue)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Date")
                    Spacer()
                    Text(expense.formattedDate)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Payment Details")) {
                HStack {
                    Text("Paid By")
                    Spacer()
                    Text(expense.paidBy)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Payment Method")
                    Spacer()
                    Text(expense.paymentMethod.rawValue)
                        .foregroundColor(.secondary)
                }
                
                if let reference = expense.referenceNumber {
                    HStack {
                        Text("Reference")
                        Spacer()
                        Text(reference)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let notes = expense.notes {
                    HStack {
                        Text("Notes")
                        Spacer()
                        Text(notes)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Status Information")) {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(expense.status.rawValue)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(expense.statusColor)
                        .cornerRadius(4)
                }
                
                if let approvedBy = expense.approvedBy {
                    HStack {
                        Text("Approved By")
                        Spacer()
                        Text(approvedBy)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let reimbursementDate = expense.reimbursementDate {
                    HStack {
                        Text("Reimbursed On")
                        Spacer()
                        Text(Formatters.formatDate(reimbursementDate))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if expense.status == .pending {
                Section {
                    Button(action: {
                        showingApprovalSheet = true
                    }) {
                        Text("Approve or Reject")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .listRowInsets(EdgeInsets())
                .padding()
            } else if expense.status == .approved {
                Section {
                    Button(action: markAsReimbursed) {
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
        .sheet(isPresented: $showingApprovalSheet) {
            NavigationView {
                ExpenseApprovalView(expense: expense) { updatedExpense in
                    self.expense = updatedExpense
                    dataManager.updateCompanyExpense(updatedExpense)
                }
                .navigationTitle("Expense Approval")
            }
        }
    }
    
    private func markAsReimbursed() {
        var updatedExpense = expense
        updatedExpense.status = .reimbursed
        updatedExpense.reimbursementDate = Date()
        
        expense = updatedExpense
        dataManager.updateCompanyExpense(updatedExpense)
    }
}

struct ExpenseApprovalView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var approverName = ""
    @State var expense: CompanyExpense
    var onUpdate: (CompanyExpense) -> Void
    
    var body: some View {
        Form {
            Section(header: Text("Expense Information")) {
                HStack {
                    Text("Title")
                    Spacer()
                    Text(expense.title)
                }
                
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(expense.formattedAmount)
                }
                
                HStack {
                    Text("Paid By")
                    Spacer()
                    Text(expense.paidBy)
                }
            }
            
            Section(header: Text("Approval")) {
                TextField("Approver Name", text: $approverName)
            }
            
            Section {
                Button(action: {
                    approve()
                }) {
                    Text("Approve Expense")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    reject()
                }) {
                    Text("Reject Expense")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            .listRowInsets(EdgeInsets())
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func approve() {
        if !approverName.isEmpty {
            var updatedExpense = expense
            updatedExpense.status = .approved
            updatedExpense.approvedBy = approverName
            
            onUpdate(updatedExpense)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func reject() {
        if !approverName.isEmpty {
            var updatedExpense = expense
            updatedExpense.status = .rejected
            updatedExpense.approvedBy = approverName
            
            onUpdate(updatedExpense)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ExpenseManagementView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExpenseManagementView()
                .environmentObject(DataManager())
        }
    }
} 