import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Employee dashboard
            EmployeeDashboardView()
                .tabItem {
                    Label("Employee", systemImage: "person.fill")
                }
                .tag(0)
            
            // Clients dashboard
            ClientsView()
                .tabItem {
                    Label("Clients", systemImage: "person.3.fill")
                }
                .tag(1)
            
            // Expenses dashboard
            ExpensesTabView()
                .tabItem {
                    Label("Expenses", systemImage: "dollarsign.square.fill")
                }
                .tag(2)
            
            // Settings view
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

struct ExpensesTabView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: ExpenseManagementView()) {
                    HStack {
                        Image(systemName: "dollarsign.circle")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text("Expense Management")
                                .font(.headline)
                            Text("Record and manage expenses")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                NavigationLink(destination: ExpenseReportListView()) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text("Expense Reports")
                                .font(.headline)
                            Text("Generate and manage expense reports")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                NavigationLink(destination: PersonalAccountView()) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .foregroundColor(.purple)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text("Personal Account")
                                .font(.headline)
                            Text("Track personal funds used for company expenses")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Finances")
        }
    }
} 