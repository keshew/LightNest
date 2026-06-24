import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @EnvironmentObject var roomVM: RoomViewModel
    @EnvironmentObject var fixtureVM: FixtureViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @State private var selectedProject: Project?
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var appeared = false

    var selectedOrFirst: Project? { selectedProject ?? projectVM.activeProjects.first }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Project selector
                        if !projectVM.activeProjects.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(projectVM.activeProjects) { project in
                                        Button(project.name) {
                                            withAnimation { selectedProject = project }
                                        }
                                        .font(.system(size: 13, weight: selectedProject?.id == project.id ? .semibold : .medium))
                                        .foregroundColor(selectedProject?.id == project.id ? Color.bgPrimary : Color.textSecondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedProject?.id == project.id ? Color.accentYellow : Color.cardBg)
                                        .cornerRadius(20)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.top, 4)
                        }

                        if let project = selectedOrFirst {
                            reportContent(for: project)
                        } else {
                            EmptyStateView(icon: "chart.bar", title: "No projects", subtitle: "Create a project to see reports")
                        }

                        Spacer().frame(height: 80)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if let project = selectedOrFirst {
                            shareText = generateReport(for: project)
                            showShareSheet = true
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color.accentYellow)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(text: shareText)
            }
            .onAppear {
                if selectedProject == nil { selectedProject = projectVM.activeProjects.first }
                withAnimation { appeared = true }
            }
        }
    }

    @ViewBuilder
    private func reportContent(for project: Project) -> some View {
        let rooms = roomVM.rooms(for: project.id)
        let allFixtures = rooms.flatMap { fixtureVM.fixtures(for: $0.id) }
        let totalPower = allFixtures.filter { $0.isOn }.reduce(0.0) { $0 + $1.power }
        let totalLumens = allFixtures.filter { $0.isOn }.reduce(0.0) { $0 + $1.lumens }
        let energyCost = totalPower / 1000.0 * 24 * 0.12 // kWh/day * rate

        // Summary cards
        HStack(spacing: 12) {
            MetricCard(value: "\(rooms.count)", label: "Rooms", icon: "square.3.layers.3d", color: .accentBlue)
            MetricCard(value: "\(allFixtures.count)", label: "Fixtures", icon: "lightbulb.fill", color: .accentYellow)
            MetricCard(value: "\(Int(totalPower))W", label: "Total Power", icon: "bolt.fill", color: .accentOrange)
        }
        .padding(.horizontal, 16)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)

        HStack(spacing: 12) {
            MetricCard(value: "\(Int(totalLumens / 1000))k", label: "Lumens", icon: "sun.max.fill", color: .statusDone)
            MetricCard(value: String(format: "$%.2f", energyCost), label: "Cost/day", icon: "dollarsign.circle.fill", color: .accentYellowActive)
            MetricCard(value: String(format: "%.1f kWh", totalPower / 1000 * 24), label: "kWh/day", icon: "chart.line.uptrend.xyaxis", color: .accentBlueSoft)
        }
        .padding(.horizontal, 16)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)

        // Status by room chart
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Status by Room")

            if rooms.isEmpty {
                Text("No rooms in this project")
                    .font(.system(size: 14))
                    .foregroundColor(Color.textInactive)
                    .padding(12)
            } else {
                ForEach(rooms) { room in
                    let roomFixtures = fixtureVM.fixtures(for: room.id)
                    let power = fixtureVM.totalPower(for: room.id)
                    RoomReportRow(
                        name: room.name,
                        fixtureCount: roomFixtures.count,
                        power: power,
                        status: room.status,
                        appeared: appeared
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)

        // Power distribution bar chart
        if !rooms.isEmpty {
            powerDistributionChart(rooms: rooms)
                .padding(.horizontal, 16)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
        }

        // Task progress
        taskProgressSection
            .padding(.horizontal, 16)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)

        // Export button
        Button("Export Report") {
            shareText = generateReport(for: project)
            showShareSheet = true
        }
        .buttonStyle(SecondaryButtonStyle())
        .padding(.horizontal, 16)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)
    }

    private func powerDistributionChart(rooms: [Room]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Power Distribution")

            let total = rooms.reduce(0.0) { $0 + fixtureVM.totalPower(for: $1.id) }
            let colors: [Color] = [.accentYellow, .accentOrange, .accentBlue, .statusDone, .accentBlueSoft]

            VStack(spacing: 8) {
                // Bar
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(Array(rooms.enumerated()), id: \.element.id) { idx, room in
                            let power = fixtureVM.totalPower(for: room.id)
                            let fraction = total > 0 ? power / total : 1.0 / Double(rooms.count)
                            colors[idx % colors.count]
                                .frame(width: geo.size.width * CGFloat(fraction))
                                .cornerRadius(idx == 0 ? 6 : (idx == rooms.count - 1 ? 6 : 0))
                        }
                    }
                    .cornerRadius(6)
                }
                .frame(height: 16)

                // Legend
                ForEach(Array(rooms.enumerated()), id: \.element.id) { idx, room in
                    let power = fixtureVM.totalPower(for: room.id)
                    let pct = total > 0 ? Int((power / total) * 100) : 0
                    HStack(spacing: 8) {
                        Circle()
                            .fill(colors[idx % colors.count])
                            .frame(width: 8, height: 8)
                        Text(room.name)
                            .font(.system(size: 13))
                            .foregroundColor(Color.textSecondary)
                        Spacer()
                        Text("\(Int(power))W · \(pct)%")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.textPrimary)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var taskProgressSection: some View {
        let total = taskVM.tasks.count
        let done = taskVM.doneTasks.count
        let pct = total > 0 ? Double(done) / Double(total) : 0

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Task Progress")

            VStack(spacing: 12) {
                HStack {
                    Text("\(done) of \(total) tasks done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    Spacer()
                    Text("\(Int(pct * 100))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.accentYellow)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.bgSoft)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient.yellowGlow)
                            .frame(width: geo.size.width * CGFloat(pct), height: 8)
                            .animation(.easeOut(duration: 1.0), value: appeared)
                    }
                }
                .frame(height: 8)

                HStack(spacing: 16) {
                    TaskStatBadge(count: taskVM.pendingTasks.count, label: "Pending", color: .accentBlue)
                    TaskStatBadge(count: taskVM.overdueTasks.count, label: "Overdue", color: .statusError)
                    TaskStatBadge(count: taskVM.doneTasks.count, label: "Done", color: .statusDone)
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func generateReport(for project: Project) -> String {
        let rooms = roomVM.rooms(for: project.id)
        let allFixtures = rooms.flatMap { fixtureVM.fixtures(for: $0.id) }
        let totalPower = allFixtures.filter { $0.isOn }.reduce(0.0) { $0 + $1.power }
        let totalLumens = allFixtures.filter { $0.isOn }.reduce(0.0) { $0 + $1.lumens }

        var report = "LIGHT NEST REPORT\n"
        report += "Project: \(project.name)\n"
        report += "Date: \(Date().formatted(date: .long, time: .omitted))\n\n"
        report += "SUMMARY\n"
        report += "Rooms: \(rooms.count)\n"
        report += "Fixtures: \(allFixtures.count)\n"
        report += "Total Power: \(Int(totalPower))W\n"
        report += "Total Lumens: \(Int(totalLumens)) lm\n"
        report += "Daily Energy: \(String(format: "%.2f", totalPower / 1000 * 24)) kWh\n\n"
        report += "ROOMS\n"
        for room in rooms {
            let f = fixtureVM.fixtures(for: room.id)
            report += "• \(room.name): \(f.count) fixtures, \(Int(fixtureVM.totalPower(for: room.id)))W\n"
        }
        report += "\nGenerated by Light Nest"
        return report
    }
}

struct MetricCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.textInactive)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardStyle()
    }
}

struct RoomReportRow: View {
    let name: String
    let fixtureCount: Int
    let power: Double
    let status: String
    let appeared: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.textPrimary)
                Text("\(fixtureCount) fixtures · \(Int(power))W")
                    .font(.system(size: 12))
                    .foregroundColor(Color.textInactive)
            }
            Spacer()
            StatusBadge(status: status)
        }
        .padding(12)
        .cardStyle()
    }
}

struct TaskStatBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color.textInactive)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
