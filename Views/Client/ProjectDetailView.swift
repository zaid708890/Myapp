import SwiftUI

struct ProjectDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    let clientIndex: Int
    let projectIndex: Int
    
    @State private var showingAddPaymentSheet = false
    
    private var project: Project {
        dataManager.clients[clientIndex].projects[projectIndex]
    }
    
    var body: some View {
        List {
            // Project info section
            Section(header: Text("Project Information")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(project.name)
                        .font(.headline)
                    
                    Text(project.description)
                        .font(.subheadline)
                    
                    Text("Timeline: \(Formatters.formatDateRange(from: project.startDate, to: project.endDate))")
                        .font(.caption)
                    
                    HStack {
                        Text("Status:")
                            .font(.caption)
                        Text(project.isCompleted ? "Completed" : "In Progress")
                            .font(.caption)
                            .padding(4)
                            .background(project.isCompleted ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))
                            .cornerRadius(4)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Financial summary
            Section(header: Text("Financial Summary")) {
                HStack {
                    Text("Contract Amount")
                        .font(.subheadline)
                    Spacer()
                    Text(project.contractAmount.formattedCurrency)
                        .font(.headline)
                }
                .padding(.vertical, 4)
                
                HStack {
                    Text("Total Paid")
                        .font(.subheadline)
                    Spacer()
                    Text(project.totalPaidAmount.formattedCurrency)
                        .font(.headline)
                }
                .padding(.vertical, 4)
                
                HStack {
                    Text("Balance")
                        .font(.headline)
                    Spacer()
                    Text(project.balanceAmount.formattedCurrency)
                        .font(.headline)
                        .foregroundColor(project.balanceAmount > 0 ? .green : .primary)
                }
                .padding(.vertical, 4)
            }
            
            // Payments section
            Section(header: 
                HStack {
                    Text("Payments")
                    Spacer()
                    Button(action: {
                        showingAddPaymentSheet.toggle()
                    }) {
                        Image(systemName: "plus.circle")
                    }
                }
            ) {
                if project.payments.isEmpty {
                    Text("No payments recorded yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(project.payments.sorted(by: { $0.date > $1.date })) { payment in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(Formatters.formatDate(payment.date))
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text(payment.amount.formattedCurrency)
                                    .font(.headline)
                            }
                            
                            HStack {
                                Text(payment.paymentType.rawValue)
                                    .font(.caption)
                                    .padding(4)
                                    .background(
                                        payment.paymentType == .advance ? Color.blue.opacity(0.3) :
                                            payment.paymentType == .milestone ? Color.orange.opacity(0.3) :
                                            Color.green.opacity(0.3)
                                    )
                                    .cornerRadius(4)
                                
                                if !payment.notes.isEmpty {
                                    Text("Note: \(payment.notes)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(project.name)
        .sheet(isPresented: $showingAddPaymentSheet) {
            AddPaymentView(clientIndex: clientIndex, projectIndex: projectIndex)
        }
    }
}

struct ProjectDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager()
        return NavigationView {
            ProjectDetailView(clientIndex: 0, projectIndex: 0)
                .environmentObject(dataManager)
        }
    }
} 