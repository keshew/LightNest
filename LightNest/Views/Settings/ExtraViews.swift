import SwiftUI

// MARK: - Calendar View (accessible from NavigationLink)
struct CalendarView: View {
    @EnvironmentObject var calVM: CalendarViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @State private var selectedDate = Date()
    @State private var showAddEvent = false
    @State private var currentMonth = Date()

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 16) {
                // Month navigation
                HStack {
                    Button(action: prevMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.textSecondary)
                    }
                    Spacer()
                    Text(currentMonth, format: .dateTime.month(.wide).year())
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    Spacer()
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color.textSecondary)
                    }
                }
                .padding(.horizontal, 16)

                // Calendar grid
                calendarGrid
                    .padding(.horizontal, 16)

                // Events for selected date
                VStack(spacing: 8) {
                    HStack {
                        Text(selectedDate, style: .date)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        Spacer()
                        Button("Add Event") { showAddEvent = true }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.accentYellow)
                    }
                    .padding(.horizontal, 16)

                    let dayEvents = calVM.events(on: selectedDate)
                    let dayTasks = taskVM.tasks.filter {
                        guard let d = $0.dueDate else { return false }
                        return Calendar.current.isDate(d, inSameDayAs: selectedDate)
                    }

                    if dayEvents.isEmpty && dayTasks.isEmpty {
                        HStack {
                            Text("Nothing scheduled")
                                .font(.system(size: 14))
                                .foregroundColor(Color.textInactive)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }

                    ForEach(dayEvents) { event in
                        CalendarEventRow(event: event, onDelete: { calVM.delete(event) })
                            .padding(.horizontal, 16)
                    }

                    ForEach(dayTasks.prefix(3)) { task in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.square")
                                .foregroundColor(Color.accentBlue)
                            Text(task.title)
                                .font(.system(size: 14))
                                .foregroundColor(Color.textPrimary)
                            Spacer()
                            StatusBadge(status: task.isDone ? "Done" : "Pending")
                        }
                        .padding(10)
                        .cardStyle()
                        .padding(.horizontal, 16)
                    }
                }

                Spacer()
            }
            .padding(.top, 16)
        }
        .navigationTitle("Calendar")
        .sheet(isPresented: $showAddEvent) {
            AddEventView { event in calVM.add(event) }
        }
    }

    private var calendarGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

        return VStack(spacing: 4) {
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { d in
                    Text(d)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.textInactive)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        let isToday = Calendar.current.isDateInToday(date)
                        let hasEvent = !calVM.events(on: date).isEmpty || taskVM.tasks.contains { t in
                            guard let d = t.dueDate else { return false }
                            return Calendar.current.isDate(d, inSameDayAs: date)
                        }

                        Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedDate = date } }) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.accentYellow : (isToday ? Color.accentYellow.opacity(0.2) : Color.clear))
                                    .frame(width: 34, height: 34)

                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.system(size: 14, weight: isSelected || isToday ? .semibold : .regular))
                                    .foregroundColor(isSelected ? Color.bgPrimary : (isToday ? Color.accentYellow : Color.textPrimary))

                                if hasEvent {
                                    Circle()
                                        .fill(Color.accentOrange)
                                        .frame(width: 4, height: 4)
                                        .offset(y: 12)
                                }
                            }
                        }
                    } else {
                        Color.clear.frame(height: 34)
                    }
                }
            }
        }
        .padding(12)
        .cardStyle()
    }

    private func daysInMonth() -> [Date?] {
        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth))!
        let range = cal.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = cal.component(.weekday, from: startOfMonth) - 1

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            days.append(cal.date(byAdding: .day, value: day - 1, to: startOfMonth))
        }
        return days
    }

    private func prevMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }

    private func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
}

struct CalendarEventRow: View {
    let event: CalendarEvent
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: eventIcon(event.type))
                .foregroundColor(eventColor(event.type))
                .font(.system(size: 14))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.textPrimary)
                Text(event.date, style: .time)
                    .font(.system(size: 12))
                    .foregroundColor(Color.textInactive)
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .foregroundColor(Color.textInactive)
            }
        }
        .padding(10)
        .cardStyle()
    }

    private func eventIcon(_ type: String) -> String {
        switch type {
        case "Check": return "magnifyingglass"
        case "Task": return "checkmark.square"
        case "Deadline": return "exclamationmark.circle"
        default: return "calendar"
        }
    }

    private func eventColor(_ type: String) -> Color {
        switch type {
        case "Check": return .accentBlue
        case "Task": return .statusDone
        case "Deadline": return .statusError
        default: return .accentYellow
        }
    }
}

struct AddEventView: View {
    let onSave: (CalendarEvent) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var date = Date()
    @State private var type = "Check"
    @State private var notes = ""
    @State private var showConfirmation = false

    let types = ["Check", "Task", "Deadline", "Meeting"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        ConfirmationBanner(message: "Event added!", isShowing: $showConfirmation)

                        VStack(spacing: 16) {
                            LNTextField(label: "Title", text: $title, placeholder: "Event name")

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Date & Time")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                                DatePicker("", selection: $date)
                                    .colorScheme(.dark)
                                    .tint(Color.accentYellow)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Type")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                                HStack(spacing: 8) {
                                    ForEach(types, id: \.self) { t in
                                        Button(t) { type = t }
                                            .font(.system(size: 13, weight: type == t ? .semibold : .regular))
                                            .foregroundColor(type == t ? Color.bgPrimary : Color.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(type == t ? Color.accentYellow : Color.bgSoft)
                                            .cornerRadius(16)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        Button("Save Event") {
                            guard !title.isEmpty else { return }
                            onSave(CalendarEvent(title: title, date: date, type: type, notes: notes))
                            withAnimation { showConfirmation = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Energy View
struct EnergyView: View {
    @EnvironmentObject var roomVM: RoomViewModel
    @EnvironmentObject var fixtureVM: FixtureViewModel
    @EnvironmentObject var appState: AppState
    let project: Project

    @State private var hoursPerDay: Double = 8
    @State private var ratePerKwh: Double = 0.12

    var rooms: [Room] { roomVM.rooms(for: project.id) }
    var allFixtures: [Fixture] { rooms.flatMap { fixtureVM.fixtures(for: $0.id) } }
    var totalPower: Double { allFixtures.filter { $0.isOn }.reduce(0) { $0 + $1.power } }
    var dailyKwh: Double { totalPower / 1000.0 * hoursPerDay }
    var dailyCost: Double { dailyKwh * ratePerKwh }
    var monthlyCost: Double { dailyCost * 30 }
    var yearlyCost: Double { dailyCost * 365 }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Total cost card
                    VStack(spacing: 16) {
                        Text("Energy Estimate")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.textInactive)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Text(String(format: "%.2f kWh/day", dailyKwh))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(LinearGradient.yellowGlow)

                        HStack(spacing: 0) {
                            Divider().background(Color.divider)
                            VStack(spacing: 4) {
                                Text(String(format: "\(currencySymbol)%.2f", dailyCost))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.textPrimary)
                                Text("per day")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.textInactive)
                            }
                            .frame(maxWidth: .infinity)
                            Divider().background(Color.divider)
                            VStack(spacing: 4) {
                                Text(String(format: "\(currencySymbol)%.2f", monthlyCost))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.textPrimary)
                                Text("per month")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.textInactive)
                            }
                            .frame(maxWidth: .infinity)
                            Divider().background(Color.divider)
                            VStack(spacing: 4) {
                                Text(String(format: "\(currencySymbol)%.0f", yearlyCost))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.textPrimary)
                                Text("per year")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.textInactive)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(height: 60)
                    }
                    .padding(16)
                    .cardStyle()
                    .padding(.horizontal, 16)

                    // Controls
                    VStack(spacing: 12) {
                        SliderField(
                            label: "Hours per day",
                            value: $hoursPerDay,
                            range: 1...24,
                            displayFormat: { "\(Int($0)) hrs" },
                            color: .accentYellow
                        )
                        SliderField(
                            label: "Rate (\(currencySymbol)/kWh)",
                            value: $ratePerKwh,
                            range: 0.01...0.5,
                            displayFormat: { String(format: "\(currencySymbol)%.3f", $0) },
                            color: .accentOrange
                        )
                    }
                    .padding(.horizontal, 16)

                    // Per-room breakdown
                    VStack(spacing: 10) {
                        SectionHeader(title: "By Room")
                            .padding(.horizontal, 16)

                        ForEach(rooms) { room in
                            let power = fixtureVM.totalPower(for: room.id)
                            let cost = power / 1000.0 * hoursPerDay * ratePerKwh
                            HStack(spacing: 12) {
                                Image(systemName: "square.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.accentBlue)
                                Text(room.name)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.textPrimary)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(Int(power))W")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color.accentOrange)
                                    Text(String(format: "\(currencySymbol)%.2f/day", cost))
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.textSecondary)
                                }
                            }
                            .padding(12)
                            .cardStyle()
                            .padding(.horizontal, 16)
                        }
                    }

                    Spacer().frame(height: 80)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Energy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var currencySymbol: String {
        switch appState.currency {
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        default: return "$"
        }
    }
}

// MARK: - History View
struct HistoryView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var filter = "All"

    let filters = ["All", "Created", "Updated", "Completed"]

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { f in
                            FilterChip(label: f, count: 0, isSelected: filter == f) {
                                withAnimation { filter = f }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 10)

                List {
                    ForEach(projectVM.projects.sorted(by: { $0.updatedAt > $1.updatedAt })) { project in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(project.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color.textPrimary)
                                Text(project.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.textInactive)
                            }
                            Spacer()
                            StatusBadge(status: project.status)
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Notifications Settings
struct NotificationsSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("deadlineEnabled") private var deadlineEnabled = true
    @AppStorage("warningEnabled") private var warningEnabled = true
    @AppStorage("weeklyEnabled") private var weeklyEnabled = true
    @State private var showConfirmation = false

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ConfirmationBanner(message: "Notification settings saved!", isShowing: $showConfirmation)

                    VStack(spacing: 1) {
                        SettingsToggle(
                            label: "All Notifications",
                            icon: "bell.fill",
                            color: .accentYellow,
                            isOn: $notificationsEnabled
                        )
                        .padding(14)
                        .background(Color.cardBg)

                        if notificationsEnabled {
                            Divider().background(Color.divider).padding(.horizontal, 14)

                            SettingsToggle(
                                label: "Deadline Alerts",
                                icon: "calendar.badge.exclamationmark",
                                color: .statusError,
                                isOn: $deadlineEnabled
                            )
                            .padding(14)
                            .background(Color.cardBg)

                            Divider().background(Color.divider).padding(.horizontal, 14)

                            SettingsToggle(
                                label: "Warning Alerts",
                                icon: "exclamationmark.triangle.fill",
                                color: .accentOrange,
                                isOn: $warningEnabled
                            )
                            .padding(14)
                            .background(Color.cardBg)

                            Divider().background(Color.divider).padding(.horizontal, 14)

                            SettingsToggle(
                                label: "Weekly Lighting Check",
                                icon: "clock.arrow.circlepath",
                                color: .accentBlue,
                                isOn: $weeklyEnabled,
                                onChange: { enabled in
                                    if enabled { NotificationManager.shared.scheduleWeeklyCheck() }
                                    else { NotificationManager.shared.cancelNotification(id: "weekly_check") }
                                }
                            )
                            .padding(14)
                            .background(Color.cardBg)
                        }
                    }
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.divider, lineWidth: 1))
                    .padding(.horizontal, 16)

                    Button("Save Notifications") {
                        withAnimation { showConfirmation = true }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 16)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
