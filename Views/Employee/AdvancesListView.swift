import SwiftUI

struct AdvancesListView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        List {
            Section(header: Text("Total Advances")) {
                HStack {
                    Text("Total Amount")
                        .font(.headline)
                    Spacer()
                    Text(dataManager.employee.totalSalaryAdvance.formattedCurrency)
                        .font(.headline)
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("All Advances")) {
                if dataManager.employee.salaryAdvances.isEmpty {
                    Text("No advances recorded")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(dataManager.employee.salaryAdvances.sorted(by: { $0.date > $1.date })) { advance in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(Formatters.formatFullDate(advance.date))
                                    .font(.subheadline)
                                Spacer()
                                Text(advance.amount.formattedCurrency)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Reason:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(advance.reason)
                                    .font(.caption)
                            }
                            
                            Text(advance.isPaid ? "Paid" : "Unpaid")
                                .font(.caption)
                                .padding(4)
                                .background(advance.isPaid ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                                .cornerRadius(4)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Salary Advances")
    }
}

struct AdvancesListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdvancesListView()
                .environmentObject(DataManager())
        }
    }
} 