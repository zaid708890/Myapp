import SwiftUI

struct DutyCalendarView: View {
    @EnvironmentObject var dataManager: DataManager
    
    // State for keeping track of the selected month
    @State private var selectedDate = Date()
    
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Start week on Sunday
        return calendar
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Month navigation
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    Text(monthYearFormatter.string(from: selectedDate))
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                
                // Calendar
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(daysInMonth(), id: \.self) { day in
                        if day.day != 0 {
                            DayView(day: day, 
                                    dutyRecords: dataManager.employee.dutyRecords,
                                    leaves: dataManager.employee.leaves)
                        } else {
                            Text("")
                        }
                    }
                }
                .padding(.horizontal)
                
                // Legend
                HStack(spacing: 20) {
                    HStack {
                        Circle()
                            .fill(Color.green.opacity(0.5))
                            .frame(width: 12, height: 12)
                        Text("Duty Day")
                            .font(.caption)
                    }
                    
                    HStack {
                        Circle()
                            .fill(Color.red.opacity(0.5))
                            .frame(width: 12, height: 12)
                        Text("Leave")
                            .font(.caption)
                    }
                }
                .padding()
                
                Divider()
                
                // List of duty periods
                VStack(alignment: .leading, spacing: 16) {
                    Text("Duty Periods")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if dataManager.employee.dutyRecords.isEmpty {
                        Text("No duty periods recorded")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.horizontal)
                    } else {
                        ForEach(dataManager.employee.dutyRecords.sorted(by: { $0.startDate > $1.startDate })) { record in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(Formatters.formatDateRange(from: record.startDate, to: record.endDate))
                                        .font(.subheadline)
                                    
                                    Text("\(record.durationInDays) days")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if !record.notes.isEmpty {
                                        Text(record.notes)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                }
                
                // List of leaves
                VStack(alignment: .leading, spacing: 16) {
                    Text("Leaves")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if dataManager.employee.leaves.isEmpty {
                        Text("No leaves recorded")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.horizontal)
                    } else {
                        ForEach(dataManager.employee.leaves.sorted(by: { $0.startDate > $1.startDate })) { leave in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(Formatters.formatDateRange(from: leave.startDate, to: leave.endDate))
                                        .font(.subheadline)
                                    
                                    Text("\(leave.durationInDays) days • \(leave.isPaid ? "Paid" : "Unpaid")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(leave.reason)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "figure.walk")
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Duty Calendar")
    }
    
    // Date utilities
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    private let daysOfWeek = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    
    private func daysInMonth() -> [CalendarDay] {
        let monthRange = calendar.range(of: .day, in: .month, for: selectedDate)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        
        var days: [CalendarDay] = []
        
        // Add empty days for first week
        for _ in 1..<firstWeekday {
            days.append(CalendarDay(day: 0, date: Date()))
        }
        
        // Add days of the month
        for day in monthRange {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay)!
            days.append(CalendarDay(day: day, date: date))
        }
        
        return days
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

// Helper struct for calendar days
struct CalendarDay: Hashable {
    let day: Int
    let date: Date
}

// Day view within the calendar
struct DayView: View {
    let day: CalendarDay
    let dutyRecords: [DutyRecord]
    let leaves: [Leave]
    
    private var isLeaveDay: Bool {
        leaves.contains { leave in
            isDateInRange(day.date, from: leave.startDate, to: leave.endDate)
        }
    }
    
    private var isDutyDay: Bool {
        dutyRecords.contains { duty in
            isDateInRange(day.date, from: duty.startDate, to: duty.endDate)
        }
    }
    
    private func isDateInRange(_ date: Date, from: Date, to: Date) -> Bool {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let normalizedFrom = calendar.startOfDay(for: from)
        let normalizedTo = calendar.startOfDay(for: to)
        
        return normalizedDate >= normalizedFrom && normalizedDate <= normalizedTo
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 35, height: 35)
            
            Text("\(day.day)")
                .fontWeight(isToday ? .bold : .regular)
        }
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }
    
    private var backgroundColor: Color {
        if isLeaveDay {
            return Color.red.opacity(0.3)
        } else if isDutyDay {
            return Color.green.opacity(0.3)
        } else if isToday {
            return Color.blue.opacity(0.2)
        } else {
            return Color.clear
        }
    }
}

struct DutyCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DutyCalendarView()
                .environmentObject(DataManager())
        }
    }
} 