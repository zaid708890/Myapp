import SwiftUI

struct SalarySlipsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingGenerateSheet = false
    @State private var selectedSlip: SalarySlip?
    @State private var showingSlipDetail = false
    
    var body: some View {
        List {
            Section(header: Text("Salary Slips")) {
                if dataManager.salarySlips.isEmpty {
                    Text("No salary slips generated yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(dataManager.salarySlips.sorted(by: { $0.generatedDate > $1.generatedDate })) { slip in
                        Button(action: {
                            selectedSlip = slip
                            showingSlipDetail = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(slip.period.monthYear)
                                        .font(.headline)
                                    
                                    Text(slip.period.formattedString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Generated: \(Formatters.formatDate(slip.generatedDate))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(slip.netSalary.formattedCurrency)
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            Section {
                Button(action: {
                    showingGenerateSheet = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Generate New Salary Slip")
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Salary Slips")
        .sheet(isPresented: $showingGenerateSheet) {
            GenerateSalarySlipView()
        }
        .sheet(isPresented: $showingSlipDetail) {
            if let slip = selectedSlip {
                SalarySlipDetailView(salarySlip: slip)
            }
        }
    }
}

struct GenerateSalarySlipView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var startDate: Date = Date().startOfMonth
    @State private var endDate: Date = Date().endOfMonth
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showingSlipDetail = false
    @State private var generatedSlip: SalarySlip?
    
    // Payment details
    @State private var includePaymentDetails = false
    @State private var paymentMethod: PaymentMethod = .bankTransfer
    @State private var processedBy: String = ""
    @State private var referenceNumber: String = ""
    @State private var paymentDate: Date = Date()
    @State private var notes: String = ""
    @State private var trackAsExpense: Bool = true // Default to tracking as expense
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Period")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section(header: Text("Salary Details")) {
                    HStack {
                        Text("Employee")
                        Spacer()
                        Text(dataManager.employee.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Position")
                        Spacer()
                        Text(dataManager.employee.position)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Monthly Salary")
                        Spacer()
                        Text(dataManager.employee.monthlySalary.formattedCurrency)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Payment Details")) {
                    Toggle("Include Payment Information", isOn: $includePaymentDetails)
                    
                    if includePaymentDetails {
                        Picker("Payment Method", selection: $paymentMethod) {
                            ForEach(PaymentMethod.allCases, id: \.self) { method in
                                Text(method.rawValue).tag(method)
                            }
                        }
                        
                        DatePicker("Payment Date", selection: $paymentDate, displayedComponents: .date)
                        
                        TextField("Reference Number", text: $referenceNumber)
                        
                        TextField("Processed By", text: $processedBy)
                        
                        TextField("Notes", text: $notes)
                            .lineLimit(3)
                            
                        Toggle("Track as Company Expense", isOn: $trackAsExpense)
                        
                        if trackAsExpense {
                            Text("This payment will be recorded as a company expense")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(action: generateSlip) {
                        Text("Generate Salary Slip")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Generate Salary Slip")
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
            .sheet(isPresented: $showingSlipDetail) {
                if let slip = generatedSlip {
                    SalarySlipDetailView(salarySlip: slip)
                }
            }
        }
    }
    
    private func generateSlip() {
        if startDate > endDate {
            alertMessage = "Start date must be before end date"
            showAlert = true
            return
        }
        
        // Create period and generate slip
        let period = DatePeriod(startDate: startDate, endDate: endDate)
        
        if includePaymentDetails {
            if trackAsExpense {
                // Generate with expense tracking
                let slip = dataManager.generateSalarySlipWithAccountTracking(
                    for: period,
                    paymentMethod: paymentMethod,
                    processedBy: processedBy.isEmpty ? nil : processedBy,
                    paidFromPersonalFunds: true,
                    referenceNumber: referenceNumber.isEmpty ? nil : referenceNumber,
                    paymentDate: paymentDate,
                    notes: notes.isEmpty ? nil : notes
                )
                generatedSlip = slip
            } else {
                // Generate with payment details but no expense tracking
                let slip = dataManager.generateSalarySlip(
                    for: period,
                    paymentMethod: paymentMethod,
                    processedBy: processedBy.isEmpty ? nil : processedBy,
                    referenceNumber: referenceNumber.isEmpty ? nil : referenceNumber,
                    paymentDate: paymentDate,
                    notes: notes.isEmpty ? nil : notes
                )
                generatedSlip = slip
            }
        } else {
            // Generate without payment details
            let slip = dataManager.generateSalarySlip(for: period)
            generatedSlip = slip
        }
        
        // Show the generated slip
        showingSlipDetail = true
        
        // Close the generation form
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct SalarySlipDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let salarySlip: SalarySlip
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Salary Slip")) {
                    VStack(alignment: .center, spacing: 4) {
                        Text(salarySlip.employeeName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(salarySlip.position)
                            .font(.subheadline)
                        
                        Text("Salary Period: \(salarySlip.period.formattedString)")
                            .font(.headline)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Earnings")) {
                    HStack {
                        Text("Base Salary")
                        Spacer()
                        Text(salarySlip.baseSalary.formattedCurrency)
                    }
                    
                    HStack {
                        Text("Bonuses")
                        Spacer()
                        Text(salarySlip.bonuses.formattedCurrency)
                    }
                    
                    HStack {
                        Text("Total Earnings")
                            .fontWeight(.bold)
                        Spacer()
                        Text(salarySlip.totalEarnings.formattedCurrency)
                            .fontWeight(.bold)
                    }
                }
                
                Section(header: Text("Deductions")) {
                    HStack {
                        Text("Deductions")
                        Spacer()
                        Text(salarySlip.deductions.formattedCurrency)
                    }
                    
                    HStack {
                        Text("Advances")
                        Spacer()
                        Text(salarySlip.advances.formattedCurrency)
                    }
                    
                    HStack {
                        Text("Total Deductions")
                            .fontWeight(.bold)
                        Spacer()
                        Text(salarySlip.totalDeductions.formattedCurrency)
                            .fontWeight(.bold)
                    }
                }
                
                Section(header: Text("Net Salary")) {
                    HStack {
                        Text("Net Salary")
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                        Text(salarySlip.netSalary.formattedCurrency)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(salarySlip.netSalary > 0 ? .green : .red)
                    }
                }
                
                // Payment Information Section
                if salarySlip.paymentMethod != nil || salarySlip.processedBy != nil || 
                   salarySlip.referenceNumber != nil || salarySlip.paymentDate != nil {
                    Section(header: Text("Payment Information")) {
                        if let method = salarySlip.paymentMethod {
                            HStack {
                                Text("Payment Method")
                                Spacer()
                                Text(method)
                            }
                        }
                        
                        if let date = salarySlip.paymentDate {
                            HStack {
                                Text("Payment Date")
                                Spacer()
                                Text(Formatters.formatDate(date))
                            }
                        }
                        
                        if let reference = salarySlip.referenceNumber {
                            HStack {
                                Text("Reference Number")
                                Spacer()
                                Text(reference)
                            }
                        }
                        
                        if let processor = salarySlip.processedBy {
                            HStack {
                                Text("Processed By")
                                Spacer()
                                Text(processor)
                            }
                        }
                        
                        if let notes = salarySlip.notes, !notes.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Notes:")
                                    .font(.headline)
                                Text(notes)
                                    .font(.body)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
                
                Section(header: Text("Generated")) {
                    Text(Formatters.formatFullDate(salarySlip.generatedDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Salary Slip")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Date Extensions
extension Date {
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }
    
    var endOfMonth: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = 1
        components.day = -1
        return calendar.date(byAdding: components, to: self.startOfMonth)!
    }
}

struct SalarySlipsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SalarySlipsView()
                .environmentObject(DataManager())
        }
    }
} 