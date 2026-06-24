import SwiftUI

struct MainTabView: View {
    @StateObject private var recordVM = RecordViewModel()
    @StateObject private var recVM = RecommendationViewModel()
    @StateObject private var calVM = CalendarViewModel()
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                ProjectsView()
                    .tag(1)
                TasksView()
                    .tag(2)
                ReportsView()
                    .tag(3)
                SettingsView()
                    .tag(4)
            }
            .environmentObject(recordVM)
            .environmentObject(recVM)
            .environmentObject(calVM)

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("folder.fill", "Projects"),
        ("checkmark.square.fill", "Tasks"),
        ("chart.bar.fill", "Reports"),
        ("gearshape.fill", "Settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[i].icon)
                            .font(.system(size: 20, weight: selectedTab == i ? .semibold : .regular))
                            .foregroundColor(selectedTab == i ? Color.accentYellow : Color.textInactive)
                            .scaleEffect(selectedTab == i ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)

                        Text(tabs[i].label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTab == i ? Color.accentYellow : Color.textInactive)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(
            Color.bgDepth
                .overlay(Rectangle().fill(Color.divider).frame(height: 0.5), alignment: .top)
        )
        .padding(.bottom, 0)
    }
}

// MARK: - Shared Components

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.textPrimary)
            Spacer()
            if let action = action {
                Button(actionLabel, action: action)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.accentYellow)
            }
        }
    }
}

struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(statusColor(status))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.15))
            .cornerRadius(6)
    }
}

struct IconButton: View {
    let icon: String
    let action: () -> Void
    var color: Color = .textSecondary

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(Color.cardBg)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.divider, lineWidth: 1))
        }
    }
}

struct LNTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.textSecondary)

            TextField(placeholder.isEmpty ? label : placeholder, text: $text)
                .keyboardType(keyboardType)
                .foregroundColor(Color.textPrimary)
                .font(.system(size: 15))
                .padding(12)
                .background(Color.bgSoft)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.divider, lineWidth: 1))
        }
    }
}

struct LNPickerField<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let label: String
    @Binding var selection: T
    let options: [T]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.textSecondary)

            Menu {
                ForEach(options, id: \.self) { opt in
                    Button(opt.rawValue) { selection = opt }
                }
            } label: {
                HStack {
                    Text(selection.rawValue)
                        .foregroundColor(Color.textPrimary)
                        .font(.system(size: 15))
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textInactive)
                }
                .padding(12)
                .background(Color.bgSoft)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.divider, lineWidth: 1))
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "Add"

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Color.textInactive)

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textInactive)
                    .multilineTextAlignment(.center)
            }

            if let action = action {
                Button(actionLabel, action: action)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.bgPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.accentYellow)
                    .cornerRadius(10)
            }
        }
        .padding(32)
    }
}

struct ConfirmationBanner: View {
    let message: String
    @Binding var isShowing: Bool

    var body: some View {
        if isShowing {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.statusDone)
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.textPrimary)
                Spacer()
            }
            .padding(14)
            .background(Color.cardBg)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.statusDone.opacity(0.4), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { isShowing = false }
                }
            }
        }
    }
}
