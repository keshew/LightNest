import SwiftUI

// MARK: - Tasks View
struct TasksView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var filter = "All"
    @State private var showAdd = false

    let filters = ["All", "Today", "Overdue", "Done"]

    var filteredTasks: [AppTask] {
        switch filter {
        case "Today": return taskVM.todayTasks
        case "Overdue": return taskVM.overdueTasks
        case "Done": return taskVM.doneTasks
        default: return taskVM.tasks
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filters, id: \.self) { f in
                                FilterChip(label: f, count: countFor(f), isSelected: filter == f) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        filter = f
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)

                    if filteredTasks.isEmpty {
                        VStack {
                            Spacer()
                            EmptyStateView(
                                icon: "checkmark.square",
                                title: "No tasks here",
                                subtitle: filter == "Done" ? "Complete tasks to see them here" : "Add a task to get started",
                                action: filter != "Done" ? { showAdd = true } : nil,
                                actionLabel: "Add Task"
                            )
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(filteredTasks) { task in
                                NavigationLink(destination: TaskDetailView(task: task)) {
                                    TaskRow(task: task) {
                                        taskVM.markDone(task)
                                    }
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing) {
                                    Button("Delete", role: .destructive) {
                                        taskVM.delete(task)
                                    }
                                    if !task.isDone {
                                        Button("Done") {
                                            taskVM.markDone(task)
                                        }
                                        .tint(Color.statusDone)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color.accentYellow)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddTaskView { task in
                    taskVM.add(task)
                    NotificationManager.shared.scheduleDeadline(for: task)
                }
            }
        }
    }

    private func countFor(_ f: String) -> Int {
        switch f {
        case "Today": return taskVM.todayTasks.count
        case "Overdue": return taskVM.overdueTasks.count
        case "Done": return taskVM.doneTasks.count
        default: return taskVM.tasks.count
        }
    }
}

struct FilterChip: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isSelected ? Color.bgPrimary : Color.accentYellow)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.bgPrimary.opacity(0.2) : Color.accentYellow.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? Color.bgPrimary : Color.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentYellow : Color.cardBg)
            .cornerRadius(20)
        }
    }
}

struct TaskRow: View {
    let task: AppTask
    let onDone: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onDone) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.isDone ? Color.statusDone : Color.divider)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(task.isDone ? Color.textInactive : Color.textPrimary)
                    .strikethrough(task.isDone)
                HStack(spacing: 8) {
                    if let d = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text(d, style: .date)
                        }
                        .font(.system(size: 11))
                        .foregroundColor(task.isOverdue ? Color.statusError : Color.textInactive)
                    }
                    Text(task.category)
                        .font(.system(size: 11))
                        .foregroundColor(Color.textInactive)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(task.priority)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(TaskPriority(rawValue: task.priority)?.color ?? .textSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background((TaskPriority(rawValue: task.priority)?.color ?? .textSecondary).opacity(0.15))
                    .cornerRadius(5)
                if task.isOverdue {
                    Text("Overdue")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.statusError)
                }
            }
        }
        .padding(12)
        .background(Color.cardBg)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(task.isOverdue ? Color.statusError.opacity(0.3) : Color.divider, lineWidth: 1)
        )
        .padding(.vertical, 3)
    }
}

// MARK: - Task Detail
struct TaskDetailView: View {
    let task: AppTask
    @EnvironmentObject var taskVM: TaskViewModel
    @State private var showEdit = false

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(task.title)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Color.textPrimary)
                                    .strikethrough(task.isDone)

                                HStack(spacing: 8) {
                                    StatusBadge(status: task.isDone ? "Done" : (task.isOverdue ? "Overdue" : "Pending"))
                                    Text(task.priority)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(TaskPriority(rawValue: task.priority)?.color ?? .textSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background((TaskPriority(rawValue: task.priority)?.color ?? .textSecondary).opacity(0.15))
                                        .cornerRadius(6)
                                }
                            }
                        }

                        if !task.description.isEmpty {
                            Text(task.description)
                                .font(.system(size: 15))
                                .foregroundColor(Color.textSecondary)
                        }

                        Divider().background(Color.divider)

                        if let d = task.dueDate {
                            DetailRow(icon: "calendar", label: "Due", value: d.formatted(date: .long, time: .shortened))
                        }
                        DetailRow(icon: "tag", label: "Category", value: task.category)
                        DetailRow(icon: "clock", label: "Created", value: task.createdAt.formatted(date: .abbreviated, time: .omitted))
                    }
                    .padding(16)
                    .cardStyle()
                    .padding(.horizontal, 16)

                    if !task.isDone {
                        Button("Mark as Done") {
                            taskVM.markDone(task)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 16)
                    }

                    Button(action: { showEdit = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                            Text("Edit Task")
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.horizontal, 16)

                    Button("Delete Task") {
                        taskVM.delete(task)
                    }
                    .buttonStyle(DangerButtonStyle())
                    .padding(.horizontal, 16)

                    Spacer().frame(height: 40)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            EditTaskView(task: task) { updated in
                taskVM.update(updated)
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color.textInactive)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Add Task
struct AddTaskView: View {
    let onSave: (AppTask) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var priority = TaskPriority.normal
    @State private var category = RecordCategory.note
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(86400)
    @State private var showConfirmation = false
    @State private var titleError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        ConfirmationBanner(message: "Task added!", isShowing: $showConfirmation)

                        VStack(spacing: 16) {
                            LNTextField(label: "Title *", text: $title, placeholder: "What needs to be done?")
                                .overlay(titleError ? RoundedRectangle(cornerRadius: 10).stroke(Color.statusError, lineWidth: 1) : nil)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Description")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                                TextEditor(text: $description)
                                    .frame(height: 80)
                                    .foregroundColor(Color.textPrimary)
                                    .font(.system(size: 15))
                                    .padding(8)
                                    .background(Color.bgSoft)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.divider, lineWidth: 1))
                            }

                            LNPickerField(label: "Priority", selection: $priority, options: TaskPriority.allCases)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Category")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(RecordCategory.allCases, id: \.self) { cat in
                                            Button(cat.rawValue) {
                                                withAnimation { category = cat }
                                            }
                                            .font(.system(size: 13, weight: category == cat ? .semibold : .medium))
                                            .foregroundColor(category == cat ? Color.bgPrimary : Color.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(category == cat ? Color.accentYellow : Color.cardBg)
                                            .cornerRadius(16)
                                        }
                                    }
                                }
                            }

                            // Due date toggle
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Set Due Date")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color.textPrimary)
                                    if hasDueDate {
                                        Text(dueDate, style: .date)
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.accentYellow)
                                    }
                                }
                                Spacer()
                                Toggle("", isOn: $hasDueDate)
                                    .labelsHidden()
                                    .tint(Color.accentYellow)
                            }
                            .padding(12)
                            .background(Color.bgSoft)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.divider, lineWidth: 1))

                            if hasDueDate {
                                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.graphical)
                                    .colorScheme(.dark)
                                    .tint(Color.accentYellow)
                                    .padding(12)
                                    .background(Color.bgSoft)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 16)

                        Button("Add Task") {
                            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
                                withAnimation { titleError = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { titleError = false } }
                                return
                            }
                            let task = AppTask(
                                title: title,
                                description: description,
                                dueDate: hasDueDate ? dueDate : nil,
                                priority: priority.rawValue,
                                category: category.rawValue
                            )
                            onSave(task)
                            withAnimation { showConfirmation = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 16)

                        Spacer().frame(height: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Add Task")
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

// MARK: - Edit Task
struct EditTaskView: View {
    let task: AppTask
    let onSave: (AppTask) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var title: String
    @State private var description: String
    @State private var priority: TaskPriority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var showConfirmation = false

    init(task: AppTask, onSave: @escaping (AppTask) -> Void) {
        self.task = task
        self.onSave = onSave
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        _priority = State(initialValue: TaskPriority(rawValue: task.priority) ?? .normal)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? Date().addingTimeInterval(86400))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        ConfirmationBanner(message: "Task updated!", isShowing: $showConfirmation)

                        VStack(spacing: 16) {
                            LNTextField(label: "Title", text: $title)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Description")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                                TextEditor(text: $description)
                                    .frame(height: 80)
                                    .foregroundColor(Color.textPrimary)
                                    .font(.system(size: 15))
                                    .padding(8)
                                    .background(Color.bgSoft)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.divider, lineWidth: 1))
                            }
                            LNPickerField(label: "Priority", selection: $priority, options: TaskPriority.allCases)

                            HStack {
                                Text("Due Date")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color.textPrimary)
                                Spacer()
                                Toggle("", isOn: $hasDueDate)
                                    .labelsHidden()
                                    .tint(Color.accentYellow)
                            }
                            .padding(12)
                            .background(Color.bgSoft)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.divider, lineWidth: 1))

                            if hasDueDate {
                                DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                    .colorScheme(.dark)
                                    .tint(Color.accentYellow)
                            }
                        }
                        .padding(.horizontal, 16)

                        Button("Save Changes") {
                            var updated = task
                            updated.title = title
                            updated.description = description
                            updated.priority = priority.rawValue
                            updated.dueDate = hasDueDate ? dueDate : nil
                            onSave(updated)
                            withAnimation { showConfirmation = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 16)

                        Spacer().frame(height: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Edit Task")
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

// MARK: - Recommendations View
struct RecommendationsView: View {
    let project: Project
    @EnvironmentObject var recVM: RecommendationViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var fixtureVM: FixtureViewModel
    @EnvironmentObject var roomVM: RoomViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showConfirmation = false
    @State private var confirmMsg = ""

    var recs: [Recommendation] { recVM.recommendations(for: project.id) }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        ConfirmationBanner(message: confirmMsg, isShowing: $showConfirmation)

                        Button("Analyze Project") {
                            recVM.generateRecommendations(for: project, fixtureVM: fixtureVM, roomVM: roomVM)
                            confirmMsg = "Analysis complete"
                            withAnimation { showConfirmation = true }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                        if recs.isEmpty {
                            VStack {
                                Spacer().frame(height: 60)
                                EmptyStateView(
                                    icon: "sparkles",
                                    title: "No recommendations",
                                    subtitle: "Tap Analyze Project to get tips"
                                )
                            }
                        } else {
                            ForEach(recs) { rec in
                                RecommendationCard(rec: rec,
                                    onAddToTasks: {
                                        let task = AppTask(
                                            title: rec.title,
                                            description: rec.description,
                                            priority: "Normal",
                                            category: "Inspection"
                                        )
                                        taskVM.add(task)
                                        recVM.addToTasks(rec)
                                        confirmMsg = "Added to tasks"
                                        withAnimation { showConfirmation = true }
                                    },
                                    onDismiss: {
                                        recVM.dismiss(rec)
                                    }
                                )
                                .padding(.horizontal, 16)
                            }
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Recommendations")
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

struct RecommendationCard: View {
    let rec: Recommendation
    let onAddToTasks: () -> Void
    let onDismiss: () -> Void

    private var recIcon: String {
        switch rec.type {
        case "fix": return "wrench.fill"
        case "buy": return "cart.fill"
        default: return "magnifyingglass"
        }
    }

    private var recColor: Color {
        switch rec.type {
        case "fix": return .statusError
        case "buy": return .accentYellow
        default: return .accentBlue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: recIcon)
                    .font(.system(size: 16))
                    .foregroundColor(recColor)
                    .frame(width: 32, height: 32)
                    .background(recColor.opacity(0.15))
                    .cornerRadius(8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(rec.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    Text(rec.type.capitalized)
                        .font(.system(size: 11))
                        .foregroundColor(recColor)
                }
                Spacer()
            }

            Text(rec.description)
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .lineSpacing(3)

            HStack(spacing: 10) {
                Button(rec.isAddedToTasks ? "Added ✓" : "Add to Tasks") {
                    if !rec.isAddedToTasks { onAddToTasks() }
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(rec.isAddedToTasks ? Color.statusDone : Color.bgPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(rec.isAddedToTasks ? Color.statusDone.opacity(0.15) : Color.accentYellow)
                .cornerRadius(8)
                .disabled(rec.isAddedToTasks)

                Button("Dismiss") { onDismiss() }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.textInactive)
            }
        }
        .padding(14)
        .cardStyle()
    }
}
