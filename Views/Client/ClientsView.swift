import SwiftUI

struct ClientsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddClientSheet = false
    
    var body: some View {
        NavigationView {
            List {
                // Summary section
                Section(header: Text("Summary")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Clients")
                                .font(.subheadline)
                            Text("\(dataManager.clients.count)")
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Total Contract Value")
                                .font(.subheadline)
                            Text(totalContractValue.formattedCurrency)
                                .font(.title2)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Paid")
                                .font(.subheadline)
                            Text(totalPaidAmount.formattedCurrency)
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Balance Due")
                                .font(.subheadline)
                            Text(totalBalanceAmount.formattedCurrency)
                                .font(.title2)
                                .foregroundColor(totalBalanceAmount > 0 ? .green : .primary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Client Statements section
                Section(header: Text("Client Statements")) {
                    NavigationLink(destination: ClientStatementsView()) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("View Client Statements")
                            
                            if !dataManager.clientStatements.isEmpty {
                                Spacer()
                                Text("\(dataManager.clientStatements.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Clients list
                Section(header: 
                    HStack {
                        Text("Clients")
                        Spacer()
                        Button(action: {
                            showingAddClientSheet.toggle()
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }
                ) {
                    if dataManager.clients.isEmpty {
                        Text("No clients added yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(Array(dataManager.clients.enumerated()), id: \.element.id) { index, client in
                            NavigationLink(destination: ClientDetailView(clientIndex: index)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(client.name)
                                        .font(.headline)
                                    
                                    Text(client.company)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Text("Projects: \(client.projects.count)")
                                            .font(.caption)
                                        
                                        Spacer()
                                        
                                        Text("Balance: \(client.totalBalanceAmount.formattedCurrency)")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteClient)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Clients")
            .toolbar {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddClientSheet) {
            AddClientView()
        }
    }
    
    private var totalContractValue: Double {
        dataManager.clients.reduce(0) { $0 + $1.totalContractAmount }
    }
    
    private var totalPaidAmount: Double {
        dataManager.clients.reduce(0) { $0 + $1.totalPaidAmount }
    }
    
    private var totalBalanceAmount: Double {
        dataManager.clients.reduce(0) { $0 + $1.totalBalanceAmount }
    }
    
    private func deleteClient(at offsets: IndexSet) {
        for offset in offsets {
            dataManager.deleteClient(at: offset)
        }
    }
}

struct ClientsView_Previews: PreviewProvider {
    static var previews: some View {
        ClientsView()
            .environmentObject(DataManager())
    }
} 