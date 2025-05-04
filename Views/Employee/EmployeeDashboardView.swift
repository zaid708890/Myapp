import SwiftUI

struct EmployeeDashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddAdvanceSheet = false
    @State private var showingAddPaymentSheet = false
    @State private var showingAddLeaveSheet = false
    @State private var showingAddDutySheet = false
    
    var body: some View {
        NavigationView {
            List {
                // Summary section
                Section(header: Text("Summary")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome, \(dataManager.employee.name)")
                            .font(.headline)
                        
                        Text("Position: \(dataManager.employee.position)")
                            .font(.subheadline)
                        
                        Text("Monthly Salary: \(dataManager.employee.monthlySalary.formattedCurrency)")
                            .font(.subheadline)
                        
                        Text("Join Date: \(Formatters.formatFullDate(dataManager.employee.joinDate))")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 8)
                    
                    // Balance information
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Salary Balance")
                                .font(.headline)
                            Text(dataManager.employee.currentSalaryBalance.formattedCurrency)
                                .font(.title2)
                                .foregroundColor(dataManager.employee.currentSalaryBalance.isPositive ? .green : .red)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingAddPaymentSheet.toggle()
                        }) {
                            Text("Add Payment")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Salary Slips section
                Section(header: Text("Salary Slips")) {
                    NavigationLink(destination: SalarySlipsView()) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("View Salary Slips")
                            
                            if !dataManager.salarySlips.isEmpty {
                                Spacer()
                                Text("\(dataManager.salarySlips.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Salary Advances
                Section(header: 
                    HStack {
                        Text("Salary Advances")
                        Spacer()
                        Button(action: {
                            showingAddAdvanceSheet.toggle()
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }
                ) {
                    if dataManager.employee.salaryAdvances.isEmpty {
                        Text("No advances recorded")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(dataManager.employee.salaryAdvances.sorted(by: { $0.date > $1.date })) { advance in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(Formatters.formatDate(advance.date))
                                        .font(.subheadline)
                                    Text(advance.reason)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(advance.amount.formattedCurrency)
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    NavigationLink(destination: AdvancesListView()) {
                        Text("View All Advances")
                    }
                }
                
                // Duty and Leave Management
                Section(header: Text("Duty & Leave Management")) {
                    Button(action: {
                        showingAddDutySheet.toggle()
                    }) {
                        Label("Record Duty Period", systemImage: "calendar.badge.clock")
                    }
                    
                    Button(action: {
                        showingAddLeaveSheet.toggle()
                    }) {
                        Label("Request Leave", systemImage: "figure.walk")
                    }
                    
                    NavigationLink(destination: DutyCalendarView()) {
                        Label("View Duty Calendar", systemImage: "calendar")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Employee Dashboard")
        }
        .sheet(isPresented: $showingAddAdvanceSheet) {
            AddSalaryAdvanceView()
        }
        .sheet(isPresented: $showingAddPaymentSheet) {
            AddSalaryPaymentView()
        }
        .sheet(isPresented: $showingAddLeaveSheet) {
            AddLeaveView()
        }
        .sheet(isPresented: $showingAddDutySheet) {
            AddDutyRecordView()
        }
    }
}

struct EmployeeDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        EmployeeDashboardView()
            .environmentObject(DataManager())
    }
} 