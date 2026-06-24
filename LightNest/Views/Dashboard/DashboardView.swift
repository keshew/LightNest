import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var fixtureVM: FixtureViewModel
    @EnvironmentObject var roomVM: RoomViewModel
    @EnvironmentObject var recVM: RecommendationViewModel
    @State private var showAddProject = false
    @State private var showQuickCheck = false
    @State private var selectedProject: Project?
    @State private var showProjectDetail = false
    @State private var appeared = false

    var activeProject: Project? { projectVM.activeProjects.first }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.bgGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        headerSection
                            .padding(.horizontal, 16)
                            .offset(y: appeared ? 0 : -20)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.5), value: appeared)

                        // Active Project Card
                        if let project = activeProject {
                            activeProjectCard(project)
                                .padding(.horizontal, 16)
                                .offset(y: appeared ? 0 : 20)
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)
                        }

                        // Stats Row
                        statsRow
                            .padding(.horizontal, 16)
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

                        // Today's Tasks
                        todayTasksSection
                            .padding(.horizontal, 16)
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

                        // Warnings
                        if !taskVM.overdueTasks.isEmpty {
                            warningsSection
                                .padding(.horizontal, 16)
                                .offset(y: appeared ? 0 : 20)
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)
                        }

                        // Action Buttons
                        actionButtons
                            .padding(.horizontal, 16)
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.5).delay(0.5), value: appeared)

                        Spacer().frame(height: 80)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation { appeared = true }
            }
            .sheet(isPresented: $showAddProject) {
                AddProjectView(onSave: { project in
                    projectVM.add(project)
                })
            }
            .sheet(isPresented: $showQuickCheck) {
                QuickCheckView()
            }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.textInactive)
                Text("Light Nest")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.accentYellow, Color.accentOrangeLight],
                        startPoint: .leading, endPoint: .trailing
                    ))
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.accentYellow.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.accentYellow)
            }
        }
    }

    private func activeProjectCard(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Project")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.textInactive)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Text(project.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                }
                Spacer()
                StatusBadge(status: project.status)
            }

            HStack(spacing: 12) {
                DashStatItem(icon: "square.3.layers.3d", value: "\(roomVM.rooms(for: project.id).count)", label: "Rooms")
                DashStatItem(icon: "lightbulb.fill", value: "\(fixtureVM.fixtures.filter { f in roomVM.rooms(for: project.id).contains(where: { $0.id == f.roomId }) }.count)", label: "Fixtures")
                DashStatItem(icon: "bolt.fill", value: "\(Int(fixtureVM.fixtures.filter { $0.isOn }.reduce(0) { $0 + $1.power }))W", label: "Power")
            }

            NavigationLink(destination: RoomsListView(project: project)) {
                HStack {
                    Text("Open Project")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.bgPrimary)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.bgPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.accentYellow)
                .cornerRadius(10)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "folder.fill", value: "\(projectVM.activeProjects.count)",
                label: "Projects", color: .accentBlue
            )
            StatCard(
                icon: "checkmark.circle.fill",
                value: "\(taskVM.pendingTasks.count)",
                label: "Pending Tasks", color: .accentYellow
            )
            StatCard(
                icon: "exclamationmark.triangle.fill",
                value: "\(taskVM.overdueTasks.count)",
                label: "Overdue", color: .statusError
            )
        }
    }

    private var todayTasksSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Today's Tasks")
            if taskVM.todayTasks.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(Color.statusDone)
                    Text("All clear for today!")
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
                    Spacer()
                }
                .padding(12)
                .cardStyle()
            } else {
                ForEach(taskVM.todayTasks.prefix(3)) { task in
                    DashTaskRow(task: task) {
                        taskVM.markDone(task)
                    }
                }
            }
        }
    }

    private var warningsSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Warnings")
            ForEach(taskVM.overdueTasks.prefix(2)) { task in
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.statusError)
                        .font(.system(size: 16))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.textPrimary)
                        if let d = task.dueDate {
                            Text("Overdue since \(d, style: .date)")
                                .font(.system(size: 12))
                                .foregroundColor(Color.statusError)
                        }
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.statusError.opacity(0.08))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.statusError.opacity(0.2), lineWidth: 1))
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button("Add Project") {
                showAddProject = true
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Quick Check") {
                showQuickCheck = true
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }
}

struct DashStatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color.accentYellow)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(Color.textInactive)
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.textInactive)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle()
    }
}

struct DashTaskRow: View {
    let task: AppTask
    let onDone: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onDone) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.isDone ? Color.statusDone : Color.divider)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(task.isDone ? Color.textInactive : Color.textPrimary)
                    .strikethrough(task.isDone)
                if let d = task.dueDate {
                    Text(d, style: .time)
                        .font(.system(size: 12))
                        .foregroundColor(Color.textInactive)
                }
            }
            Spacer()
            Text(task.priority)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(TaskPriority(rawValue: task.priority)?.color ?? .textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((TaskPriority(rawValue: task.priority)?.color ?? .textSecondary).opacity(0.15))
                .cornerRadius(6)
        }
        .padding(12)
        .cardStyle()
    }
}

// MARK: - Quick Check Sheet
struct QuickCheckView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var projectVM: ProjectViewModel
    @EnvironmentObject var fixtureVM: FixtureViewModel
    @EnvironmentObject var roomVM: RoomViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(projectVM.activeProjects) { project in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(project.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.textPrimary)

                                let rooms = roomVM.rooms(for: project.id)
                                ForEach(rooms) { room in
                                    HStack {
                                        Image(systemName: "square.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.accentBlue)
                                        Text(room.name)
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.textSecondary)
                                        Spacer()
                                        let count = fixtureVM.fixtures(for: room.id).count
                                        Text("\(count) fixture\(count == 1 ? "" : "s")")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(count == 0 ? Color.statusError : Color.statusDone)
                                    }
                                    .padding(10)
                                    .background(Color.bgSoft)
                                    .cornerRadius(8)
                                }

                                if rooms.isEmpty {
                                    Text("No rooms added yet")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.textInactive)
                                        .padding(10)
                                }
                            }
                            .padding(14)
                            .cardStyle()
                        }

                        if projectVM.activeProjects.isEmpty {
                            EmptyStateView(icon: "folder", title: "No active projects", subtitle: "Create a project to start your lighting plan")
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Quick Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.accentYellow)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
