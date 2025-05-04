import SwiftUI

struct ExpenseReportListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddReportSheet = false
    @State private var selectedReportIndex: Int?
    @State private var showingReportDetailSheet = false
    
    var body: some View {
        List {
            Section(header: Text("Expense Reports")) {
                if dataManager.filteredExpenseReports.isEmpty {
                    Text("No expense reports created")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(Array(dataManager.filteredExpenseReports.enumerated()), id: \.element.id) { index, report in
                        ExpenseReportRowView(report: report)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedReportIndex = index
                                showingReportDetailSheet = true
                            }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            dataManager.deleteExpenseReport(at: index)
                        }
                    }
                }
            }
            
            Section {
                Button(action: {
                    showingAddReportSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Report")
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Expense Reports")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddReportSheet) {
            NavigationView {
                AddExpenseReportView()
                    .environmentObject(dataManager)
                    .navigationTitle("Create Expense Report")
            }
        }
        .sheet(isPresented: $showingReportDetailSheet) {
            if let index = selectedReportIndex {
                NavigationView {
                    ExpenseReportDetailView(report: dataManager.filteredExpenseReports[index])
                        .environmentObject(dataManager)
                        .navigationTitle("Report Details")
                }
            }
        }
    }
}

struct ExpenseReportRowView: View {
    let report: ExpenseReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(report.title)
                    .font(.headline)
                Spacer()
                Text(report.formattedTotalAmount)
                    .font(.headline)
                    .foregroundColor(report.status == .rejected ? .red : .primary)
            }
            
            HStack {
                Text(report.employeeName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(report.formattedSubmissionDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Period: \(Formatters.formatDate(report.period.startDate)) - \(Formatters.formatDate(report.period.endDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(report.status.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(report.statusColor)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddExpenseReportView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var title = ""
    @State private var selectedExpenseIDs: [UUID] = []
    @State private var startDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
    @State private var endDate = Date()
    @State private var notes = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private var availableExpenses: [CompanyExpense] {
        dataManager.filteredExpenses.filter { expense in
            expense.status == .pending && 
            expense.date >= startDate && 
            expense.date <= endDate
        }
    }
    
    private var totalAmount: Double {
        selectedExpenseIDs.reduce(0) { total, expenseID in
            if let expense = dataManager.companyExpenses.first(where: { $0.id == expenseID }) {
                return total + expense.amount
            }
            return total
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Report Details")) {
                TextField("Report Title", text: $title)
                
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                
                TextField("Notes", text: $notes)
                
                HStack {
                    Text("Total Amount")
                    Spacer()
                    Text(Formatters.formatCurrency(totalAmount))
                        .font(.headline)
                }
            }
            
            Section(header: Text("Select Expenses")) {
                if availableExpenses.isEmpty {
                    Text("No applicable expenses found in this period")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(availableExpenses) { expense in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(expense.title)
                                    .font(.headline)
                                Text(expense.category.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(expense.formattedDate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(expense.formattedAmount)
                                .font(.subheadline)
                            
                            Image(systemName: selectedExpenseIDs.contains(expense.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedExpenseIDs.contains(expense.id) ? .blue : .gray)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedExpenseIDs.contains(expense.id) {
                                selectedExpenseIDs.removeAll { $0 == expense.id }
                            } else {
                                selectedExpenseIDs.append(expense.id)
                            }
                        }
                    }
                }
            }
            
            Section {
                Button(action: createReport) {
                    Text("Create Report")
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
    
    private func createReport() {
        guard !title.isEmpty else {
            alertMessage = "Please enter a title"
            showAlert = true
            return
        }
        
        guard !selectedExpenseIDs.isEmpty else {
            alertMessage = "Please select at least one expense"
            showAlert = true
            return
        }
        
        guard startDate <= endDate else {
            alertMessage = "Start date must be before end date"
            showAlert = true
            return
        }
        
        // Use the current employee's ID or default if none
        let employeeID = dataManager.filteredEmployees.first?.id ?? UUID()
        let employeeName = dataManager.filteredEmployees.first?.name ?? "Unknown"
        
        let period = DatePeriod(startDate: startDate, endDate: endDate)
        
        _ = dataManager.createExpenseReport(
            title: title,
            period: period,
            employeeID: employeeID,
            employeeName: employeeName,
            expenseIDs: selectedExpenseIDs,
            notes: notes.isEmpty ? nil : notes
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct ExpenseReportDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @State var report: ExpenseReport
    @State private var showingApprovalSheet = false
    @State private var showingReimbursementSheet = false
    
    private var reportExpenses: [CompanyExpense] {
        report.expenseIDs.compactMap { expenseID in
            dataManager.companyExpenses.first(where: { $0.id == expenseID })
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Report Information")) {
                HStack {
                    Text("Title")
                    Spacer()
                    Text(report.title)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Employee")
                    Spacer()
                    Text(report.employeeName)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Total Amount")
                    Spacer()
                    Text(report.formattedTotalAmount)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Period")
                    Spacer()
                    Text("\(Formatters.formatDate(report.period.startDate)) - \(Formatters.formatDate(report.period.endDate))")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Submission Date")
                    Spacer()
                    Text(report.formattedSubmissionDate)
                        .foregroundColor(.secondary)
                }
                
                if let notes = report.notes {
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
                    Text(report.status.rawValue)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(report.statusColor)
                        .cornerRadius(4)
                }
                
                if let approvedBy = report.approvedBy {
                    HStack {
                        Text("Approved By")
                        Spacer()
                        Text(approvedBy)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let approvalDate = report.approvalDate {
                    HStack {
                        Text("Approval Date")
                        Spacer()
                        Text(Formatters.formatDate(approvalDate))
                            .foregroundColor(.secondary)
                    }
                }
                
                if let reimbursementDate = report.reimbursementDate {
                    HStack {
                        Text("Reimbursed On")
                        Spacer()
                        Text(Formatters.formatDate(reimbursementDate))
                            .foregroundColor(.secondary)
                    }
                }
                
                if let method = report.reimbursementMethod {
                    HStack {
                        Text("Payment Method")
                        Spacer()
                        Text(method.rawValue)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let reference = report.reimbursementReferenceNumber {
                    HStack {
                        Text("Reference")
                        Spacer()
                        Text(reference)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Expenses")) {
                if reportExpenses.isEmpty {
                    Text("No expenses found")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(reportExpenses) { expense in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(expense.title)
                                    .font(.headline)
                                Spacer()
                                Text(expense.formattedAmount)
                                    .font(.subheadline)
                            }
                            
                            Text(expense.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(expense.formattedDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            if report.status == .pending {
                Section {
                    Button(action: {
                        showingApprovalSheet = true
                    }) {
                        Text("Approve or Reject Report")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .listRowInsets(EdgeInsets())
                .padding()
            } else if report.status == .approved {
                Section {
                    Button(action: {
                        showingReimbursementSheet = true
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
        .sheet(isPresented: $showingApprovalSheet) {
            NavigationView {
                ExpenseReportApprovalView(report: report) { updatedReport in
                    self.report = updatedReport
                    dataManager.updateExpenseReport(updatedReport)
                }
                .navigationTitle("Report Approval")
            }
        }
        .sheet(isPresented: $showingReimbursementSheet) {
            NavigationView {
                ExpenseReportReimbursementView(report: report) { updatedReport in
                    self.report = updatedReport
                    dataManager.updateExpenseReport(updatedReport)
                }
                .navigationTitle("Mark Reimbursed")
            }
        }
    }
}

struct ExpenseReportApprovalView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var approverName = ""
    @State var report: ExpenseReport
    var onUpdate: (ExpenseReport) -> Void
    
    var body: some View {
        Form {
            Section(header: Text("Report Information")) {
                HStack {
                    Text("Title")
                    Spacer()
                    Text(report.title)
                }
                
                HStack {
                    Text("Employee")
                    Spacer()
                    Text(report.employeeName)
                }
                
                HStack {
                    Text("Total Amount")
                    Spacer()
                    Text(report.formattedTotalAmount)
                }
            }
            
            Section(header: Text("Approval")) {
                TextField("Approver Name", text: $approverName)
            }
            
            Section {
                Button(action: {
                    approve()
                }) {
                    Text("Approve Report")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    reject()
                }) {
                    Text("Reject Report")
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
            var updatedReport = report
            updatedReport.status = .approved
            updatedReport.approvedBy = approverName
            updatedReport.approvalDate = Date()
            
            onUpdate(updatedReport)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func reject() {
        if !approverName.isEmpty {
            var updatedReport = report
            updatedReport.status = .rejected
            updatedReport.approvedBy = approverName
            updatedReport.approvalDate = Date()
            
            onUpdate(updatedReport)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ExpenseReportReimbursementView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var paymentMethod = PaymentMethod.bankTransfer
    @State private var referenceNumber = ""
    @State private var reimbursementDate = Date()
    @State var report: ExpenseReport
    var onUpdate: (ExpenseReport) -> Void
    
    var body: some View {
        Form {
            Section(header: Text("Report Information")) {
                HStack {
                    Text("Employee")
                    Spacer()
                    Text(report.employeeName)
                }
                
                HStack {
                    Text("Total Amount")
                    Spacer()
                    Text(report.formattedTotalAmount)
                }
            }
            
            Section(header: Text("Reimbursement Details")) {
                DatePicker("Date", selection: $reimbursementDate, displayedComponents: .date)
                
                Picker("Payment Method", selection: $paymentMethod) {
                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                
                TextField("Reference Number", text: $referenceNumber)
            }
            
            Section {
                Button(action: {
                    reimburse()
                }) {
                    Text("Complete Reimbursement")
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func reimburse() {
        var updatedReport = report
        updatedReport.status = .reimbursed
        updatedReport.reimbursementDate = reimbursementDate
        updatedReport.reimbursementMethod = paymentMethod
        updatedReport.reimbursementReferenceNumber = referenceNumber.isEmpty ? nil : referenceNumber
        
        onUpdate(updatedReport)
        presentationMode.wrappedValue.dismiss()
    }
}

struct ExpenseReportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExpenseReportListView()
                .environmentObject(DataManager())
        }
    }
} 