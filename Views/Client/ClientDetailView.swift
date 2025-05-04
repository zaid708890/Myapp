import SwiftUI

struct ClientDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    let clientIndex: Int
    
    @State private var showingAddProjectSheet = false
    @State private var showingGenerateStatementSheet = false
    
    private var client: Client {
        dataManager.clients[clientIndex]
    }
    
    var body: some View {
        List {
            // Client info section
            Section(header: Text("Client Information")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(client.name)
                        .font(.headline)
                    
                    Text(client.company)
                        .font(.subheadline)
                    
                    if !client.email.isEmpty {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.secondary)
                            Text(client.email)
                        }
                    }
                    
                    if !client.phone.isEmpty {
                        HStack {
                            Image(systemName: "phone")
                                .foregroundColor(.secondary)
                            Text(client.phone)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Financial summary
            Section(header: Text("Financial Summary")) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Contract Value")
                            .font(.subheadline)
                        Text(client.totalContractAmount.formattedCurrency)
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Total Paid")
                            .font(.subheadline)
                        Text(client.totalPaidAmount.formattedCurrency)
                            .font(.headline)
                    }
                }
                .padding(.vertical, 4)
                
                HStack {
                    Text("Balance Due")
                        .font(.headline)
                    Spacer()
                    Text(client.totalBalanceAmount.formattedCurrency)
                        .font(.headline)
                        .foregroundColor(client.totalBalanceAmount > 0 ? .green : .primary)
                }
                .padding(.vertical, 4)
                
                Button(action: {
                    showingGenerateStatementSheet = true
                }) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("Generate Statement")
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            
            // Projects section
            Section(header: 
                HStack {
                    Text("Projects")
                    Spacer()
                    Button(action: {
                        showingAddProjectSheet.toggle()
                    }) {
                        Image(systemName: "plus.circle")
                    }
                }
            ) {
                if client.projects.isEmpty {
                    Text("No projects added yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(Array(client.projects.enumerated()), id: \.element.id) { projectIndex, project in
                        NavigationLink(destination: ProjectDetailView(clientIndex: clientIndex, projectIndex: projectIndex)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.name)
                                    .font(.headline)
                                
                                Text(project.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                HStack {
                                    Text(Formatters.formatDateRange(from: project.startDate, to: project.endDate))
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    Text(project.isCompleted ? "Completed" : "In Progress")
                                        .font(.caption)
                                        .padding(4)
                                        .background(project.isCompleted ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))
                                        .cornerRadius(4)
                                }
                                
                                HStack {
                                    Text("Contract: \(project.contractAmount.formattedCurrency)")
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    Text("Balance: \(project.balanceAmount.formattedCurrency)")
                                        .font(.caption)
                                        .foregroundColor(project.balanceAmount > 0 ? .green : .primary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(client.name)
        .sheet(isPresented: $showingAddProjectSheet) {
            AddProjectView(clientIndex: clientIndex)
        }
        .sheet(isPresented: $showingGenerateStatementSheet) {
            ClientStatementGeneratorView(clientIndex: clientIndex)
        }
    }
}

struct ClientStatementGeneratorView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager
    let clientIndex: Int
    
    @State private var startDate = Date().startOfMonth
    @State private var endDate = Date().endOfMonth
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var generatedStatement: ClientStatement?
    @State private var showingStatementDetail = false
    
    private var client: Client {
        dataManager.clients[clientIndex]
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Client")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(client.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Company")
                        Spacer()
                        Text(client.company)
                            .foregroundColor(.secondary)
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
        
        // Create period and generate statement
        let period = DatePeriod(startDate: startDate, endDate: endDate)
        if let statement = dataManager.generateClientStatement(for: clientIndex, period: period) {
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

struct ClientDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager()
        return NavigationView {
            ClientDetailView(clientIndex: 0)
                .environmentObject(dataManager)
        }
    }
} 