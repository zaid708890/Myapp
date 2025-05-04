import SwiftUI

struct ClientStatementsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingGenerateSheet = false
    @State private var selectedStatement: ClientStatement?
    @State private var showingStatementDetail = false
    
    var body: some View {
        List {
            Section(header: Text("Client Statements")) {
                if dataManager.clientStatements.isEmpty {
                    Text("No client statements generated yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(dataManager.clientStatements.sorted(by: { $0.generatedDate > $1.generatedDate })) { statement in
                        Button(action: {
                            selectedStatement = statement
                            showingStatementDetail = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(statement.clientName)
                                        .font(.headline)
                                    
                                    Text(statement.company)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Period: \(statement.period.formattedString)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Generated: \(Formatters.formatDate(statement.generatedDate))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text(statement.totalAmount.formattedCurrency)
                                        .font(.headline)
                                    
                                    Text("Due: \(statement.balanceDue.formattedCurrency)")
                                        .font(.caption)
                                        .foregroundColor(statement.balanceDue > 0 ? .green : .secondary)
                                }
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
                        Text("Generate New Statement")
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Client Statements")
        .sheet(isPresented: $showingGenerateSheet) {
            GenerateClientStatementView()
        }
        .sheet(isPresented: $showingStatementDetail) {
            if let statement = selectedStatement {
                ClientStatementDetailView(statement: statement)
            }
        }
    }
}

struct GenerateClientStatementView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    
    @State private var selectedClientIndex = 0
    @State private var startDate = Date().startOfMonth
    @State private var endDate = Date().endOfMonth
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var generatedStatement: ClientStatement?
    @State private var showingStatementDetail = false
    
    private var hasClients: Bool {
        return !dataManager.clients.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                if hasClients {
                    Section(header: Text("Client")) {
                        Picker("Select Client", selection: $selectedClientIndex) {
                            ForEach(0..<dataManager.clients.count, id: \.self) { index in
                                Text(dataManager.clients[index].name)
                                    .tag(index)
                            }
                        }
                    }
                    
                    Section(header: Text("Period")) {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                    
                    Section {
                        Button(action: generateStatement) {
                            Text("Generate Statement")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                } else {
                    Section {
                        Text("You need to add clients before generating statements")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .navigationTitle("Generate Statement")
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
            .sheet(isPresented: $showingStatementDetail) {
                if let statement = generatedStatement {
                    ClientStatementDetailView(statement: statement)
                }
            }
        }
    }
    
    private func generateStatement() {
        if startDate > endDate {
            alertMessage = "Start date must be before end date"
            showAlert = true
            return
        }
        
        if !hasClients {
            alertMessage = "You need to add clients first"
            showAlert = true
            return
        }
        
        // Create period and generate statement
        let period = DatePeriod(startDate: startDate, endDate: endDate)
        if let statement = dataManager.generateClientStatement(for: selectedClientIndex, period: period) {
            // Show the generated statement
            generatedStatement = statement
            showingStatementDetail = true
            
            // Close the generation form
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                presentationMode.wrappedValue.dismiss()
            }
        } else {
            alertMessage = "No payments found in this period"
            showAlert = true
        }
    }
}

struct ClientStatementDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let statement: ClientStatement
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Client Statement")) {
                    VStack(alignment: .center, spacing: 4) {
                        Text(statement.clientName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(statement.company)
                            .font(.subheadline)
                        
                        Text("Statement Period: \(statement.period.formattedString)")
                            .font(.headline)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Projects")) {
                    ForEach(statement.projectPayments) { projectPayment in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(projectPayment.projectName)
                                .font(.headline)
                            
                            HStack {
                                Text("Contract Amount")
                                Spacer()
                                Text(projectPayment.contractAmount.formattedCurrency)
                            }
                            
                            HStack {
                                Text("Paid Amount")
                                Spacer()
                                Text(projectPayment.paidAmount.formattedCurrency)
                            }
                            
                            HStack {
                                Text("Balance")
                                Spacer()
                                Text(projectPayment.balance.formattedCurrency)
                                    .foregroundColor(projectPayment.balance > 0 ? .green : .secondary)
                            }
                            
                            Divider()
                            
                            Text("Payments in Period:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ForEach(projectPayment.payments) { payment in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(Formatters.formatDate(payment.date))
                                            .font(.caption)
                                        
                                        Text(payment.type)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(payment.amount.formattedCurrency)
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Summary")) {
                    HStack {
                        Text("Total Contract Value")
                        Spacer()
                        Text(statement.totalAmount.formattedCurrency)
                    }
                    
                    HStack {
                        Text("Total Paid")
                        Spacer()
                        Text(statement.totalPaid.formattedCurrency)
                    }
                    
                    HStack {
                        Text("Balance Due")
                            .fontWeight(.bold)
                        Spacer()
                        Text(statement.balanceDue.formattedCurrency)
                            .fontWeight(.bold)
                            .foregroundColor(statement.balanceDue > 0 ? .green : .secondary)
                    }
                }
                
                Section(header: Text("Generated")) {
                    Text(Formatters.formatFullDate(statement.generatedDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Client Statement")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct ClientStatementsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ClientStatementsView()
                .environmentObject(DataManager())
        }
    }
} 