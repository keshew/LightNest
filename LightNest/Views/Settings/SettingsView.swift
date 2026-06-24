import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("appTheme") private var theme = "dark"
    @AppStorage("appCurrency") private var currency = "USD"
    @AppStorage("appUnits") private var units = "metric"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("weeklyCheckEnabled") private var weeklyCheckEnabled = true
    @AppStorage("deadlineNotifEnabled") private var deadlineNotifEnabled = true
    @AppStorage("warningNotifEnabled") private var warningNotifEnabled = true
    @AppStorage("defaultFloor") private var defaultFloor = 1
    @AppStorage("gridResolution") private var gridResolution = "10x10"

    @State private var showConfirmation = false
    @State private var confirmMsg = ""
    @State private var showClearDataAlert = false
    @State private var appeared = false

    let currencies = ["USD", "EUR", "GBP", "JPY", "CNY", "AUD"]
    let gridOptions = ["6x6", "8x8", "10x10", "12x12"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        ConfirmationBanner(message: confirmMsg, isShowing: $showConfirmation)
                            .padding(.horizontal, 16)

                        // Appearance
                        SettingsSection(title: "Appearance") {
                            // Theme picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Theme")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                                HStack(spacing: 10) {
                                    ForEach(["dark", "light", "system"], id: \.self) { t in
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                theme = t
                                                appState.theme = t
                                            }
                                        }) {
                                            VStack(spacing: 6) {
                                                Image(systemName: themeIcon(t))
                                                    .font(.system(size: 20))
                                                    .foregroundColor(theme == t ? Color.bgPrimary : Color.textSecondary)
                                                Text(t.capitalized)
                                                    .font(.system(size: 12, weight: theme == t ? .semibold : .regular))
                                                    .foregroundColor(theme == t ? Color.bgPrimary : Color.textSecondary)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(theme == t ? Color.accentYellow : Color.bgSoft)
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Units & Currency
                        SettingsSection(title: "Units & Currency") {
                            // Units
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Measurement Units")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                                HStack(spacing: 10) {
                                    ForEach(["metric", "imperial"], id: \.self) { u in
                                        Button(u == "metric" ? "Metric (m²)" : "Imperial (ft²)") {
                                            units = u
                                        }
                                        .font(.system(size: 13, weight: units == u ? .semibold : .regular))
                                        .foregroundColor(units == u ? Color.bgPrimary : Color.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(units == u ? Color.accentYellow : Color.bgSoft)
                                        .cornerRadius(10)
                                    }
                                }
                            }

                            Divider().background(Color.divider)

                            // Currency
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Currency")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(currencies, id: \.self) { c in
                                            Button(c) {
                                                currency = c
                                                appState.currency = c
                                            }
                                            .font(.system(size: 13, weight: currency == c ? .semibold : .medium))
                                            .foregroundColor(currency == c ? Color.bgPrimary : Color.textSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(currency == c ? Color.accentYellow : Color.bgSoft)
                                            .cornerRadius(16)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Simulation Settings
                        SettingsSection(title: "Simulation") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Grid Resolution")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                                HStack(spacing: 8) {
                                    ForEach(gridOptions, id: \.self) { g in
                                        Button(g) {
                                            gridResolution = g
                                        }
                                        .font(.system(size: 13, weight: gridResolution == g ? .semibold : .regular))
                                        .foregroundColor(gridResolution == g ? Color.bgPrimary : Color.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(gridResolution == g ? Color.accentYellow : Color.bgSoft)
                                        .cornerRadius(10)
                                    }
                                }
                                Text("Higher resolution = more accurate but slower simulation")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.textInactive)
                            }
                        }
                        .padding(.horizontal, 16)

                        // Notifications
                        SettingsSection(title: "Notifications") {
                            SettingsToggle(
                                label: "Enable Notifications",
                                icon: "bell.fill",
                                color: .accentYellow,
                                isOn: $notificationsEnabled,
                                onChange: handleNotificationToggle
                            )

                            if notificationsEnabled {
                                Divider().background(Color.divider)

                                SettingsToggle(
                                    label: "Deadline Reminders",
                                    icon: "calendar.badge.exclamationmark",
                                    color: .statusError,
                                    isOn: $deadlineNotifEnabled,
                                    onChange: { _ in }
                                )

                                Divider().background(Color.divider)

                                SettingsToggle(
                                    label: "Warning Alerts",
                                    icon: "exclamationmark.triangle.fill",
                                    color: .accentOrange,
                                    isOn: $warningNotifEnabled,
                                    onChange: { _ in }
                                )

                                Divider().background(Color.divider)

                                SettingsToggle(
                                    label: "Weekly Check Reminder",
                                    icon: "clock.arrow.circlepath",
                                    color: .accentBlue,
                                    isOn: $weeklyCheckEnabled,
                                    onChange: { enabled in
                                        if enabled {
                                            NotificationManager.shared.scheduleWeeklyCheck()
                                        } else {
                                            NotificationManager.shared.cancelNotification(id: "weekly_check")
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)

                        // Data
                        SettingsSection(title: "Data & Backup") {
                            Button(action: exportData) {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.up.doc.fill")
                                        .foregroundColor(Color.accentBlue)
                                        .frame(width: 28)
                                    Text("Export Data")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.textInactive)
                                }
                            }

                            Divider().background(Color.divider)

                            Button(action: { showClearDataAlert = true }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(Color.statusError)
                                        .frame(width: 28)
                                    Text("Clear All Data")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color.statusError)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Save Settings
                        Button("Save Settings") {
                            saveSettings()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 16)

                        // App info
                        VStack(spacing: 4) {
                            Text("Light Nest")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.textSecondary)
                            Text("Version 1.0.0 · Built with SwiftUI")
                                .font(.system(size: 12))
                                .foregroundColor(Color.textInactive)
                        }
                        .padding(.top, 4)

                        Spacer().frame(height: 80)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear All Data", isPresented: $showClearDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all projects, rooms, fixtures, and tasks. This cannot be undone.")
            }
            .onAppear {
                withAnimation { appeared = true }
            }
        }
    }

    private func themeIcon(_ t: String) -> String {
        switch t {
        case "dark": return "moon.fill"
        case "light": return "sun.max.fill"
        default: return "circle.lefthalf.filled"
        }
    }

    private func handleNotificationToggle(_ enabled: Bool) {
        if enabled {
            NotificationManager.shared.requestPermission { granted in
                if !granted {
                    DispatchQueue.main.async {
                        notificationsEnabled = false
                        appState.notificationsEnabled = false
                    }
                } else {
                    appState.notificationsEnabled = true
                }
            }
        } else {
            NotificationManager.shared.cancelAll()
            appState.notificationsEnabled = false
        }
    }

    private func saveSettings() {
        appState.theme = theme
        appState.currency = currency
        appState.units = units
        appState.notificationsEnabled = notificationsEnabled
        confirmMsg = "Settings saved!"
        withAnimation { showConfirmation = true }
    }

    private func exportData() {
        let exportString = """
        Light Nest Data Export
        Date: \(Date().formatted(date: .long, time: .shortened))
        Settings:
        - Theme: \(theme)
        - Currency: \(currency)
        - Units: \(units)
        - Grid: \(gridResolution)
        """

        let av = UIActivityViewController(activityItems: [exportString], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(av, animated: true)
        }
    }

    private func clearAllData() {
        let keys = ["ln_projects", "ln_rooms", "ln_fixtures", "ln_tasks", "ln_records", "ln_recs", "ln_events"]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        NotificationManager.shared.cancelAll()
        confirmMsg = "All data cleared"
        withAnimation { showConfirmation = true }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.textInactive)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                content
            }
            .padding(14)
            .cardStyle()
        }
    }
}

struct SettingsToggle: View {
    let label: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    var onChange: (Bool) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 28)

            Text(label)
                .font(.system(size: 15))
                .foregroundColor(Color.textPrimary)

            Spacer()

            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newVal in
                    isOn = newVal
                    onChange(newVal)
                }
            ))
            .labelsHidden()
            .tint(Color.accentYellow)
        }
    }
}
