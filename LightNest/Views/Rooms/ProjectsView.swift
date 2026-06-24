import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var showAdd = false
    @State private var showArchived = false
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                Group {
                    if projectVM.activeProjects.isEmpty && !showArchived {
                        VStack {
                            Spacer()
                            EmptyStateView(
                                icon: "folder.badge.plus",
                                title: "No projects yet",
                                subtitle: "Create your first lighting plan project",
                                action: { showAdd = true },
                                actionLabel: "Create Project"
                            )
                            Spacer()
                        }
                    } else {
                        List {
                            let displayed = showArchived ? projectVM.archivedProjects : projectVM.activeProjects
                            ForEach(displayed) { project in
                                NavigationLink(destination: RoomsListView(project: project)) {
                                    ProjectCard(project: project)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing) {
                                    Button(showArchived ? "Restore" : "Archive") {
                                        if showArchived {
                                            projectVM.unarchive(project)
                                        } else {
                                            projectVM.archive(project)
                                        }
                                    }
                                    .tint(Color.accentOrange)

                                    Button("Delete", role: .destructive) {
                                        projectVM.delete(project)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(showArchived ? "Active" : "Archived") {
                        withAnimation { showArchived.toggle() }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.accentYellow)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddProjectView { project in
                    projectVM.add(project)
                }
            }
        }
    }
}

struct ProjectCard: View {
    let project: Project

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentYellow.opacity(0.12))
                    .frame(width: 50, height: 50)
                Image(systemName: "folder.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color.accentYellow)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                HStack(spacing: 8) {
                    Text(project.objectType)
                        .font(.system(size: 12))
                        .foregroundColor(Color.textInactive)
                    if !project.address.isEmpty {
                        Text("·")
                            .foregroundColor(Color.textInactive)
                        Text(project.address)
                            .font(.system(size: 12))
                            .foregroundColor(Color.textInactive)
                            .lineLimit(1)
                    }
                }
                Text("Updated \(project.updatedAt, style: .relative) ago")
                    .font(.system(size: 11))
                    .foregroundColor(Color.textInactive)
            }

            Spacer()

            StatusBadge(status: project.status)
        }
        .padding(14)
        .background(Color.cardBg)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.divider, lineWidth: 1))
        .padding(.vertical, 4)
    }
}

// MARK: - Add Project
struct AddProjectView: View {
    let onSave: (Project) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var objectType = ObjectType.apartment
    @State private var address = ""
    @State private var startDate = Date()
    @State private var notes = ""
    @State private var showConfirmation = false
    @State private var nameError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        ConfirmationBanner(message: "Project saved!", isShowing: $showConfirmation)

                        VStack(spacing: 16) {
                            LNTextField(label: "Project Name *", text: $name, placeholder: "e.g. Living Room Redesign")
                                .overlay(
                                    nameError
                                    ? RoundedRectangle(cornerRadius: 10).stroke(Color.statusError, lineWidth: 1)
                                    : nil
                                )

                            LNPickerField(label: "Object Type", selection: $objectType, options: ObjectType.allCases)

                            LNTextField(label: "Address / Label", text: $address, placeholder: "e.g. Apt 4B, Main St")

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Start Date")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .colorScheme(.dark)
                                    .padding(12)
                                    .background(Color.bgSoft)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.divider, lineWidth: 1))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                                TextEditor(text: $notes)
                                    .frame(height: 90)
                                    .foregroundColor(Color.textPrimary)
                                    .font(.system(size: 15))
                                    .padding(8)
                                    .background(Color.bgSoft)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.divider, lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 16)

                        Button("Save Project") {
                            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                                withAnimation { nameError = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { nameError = false }
                                }
                                return
                            }
                            let project = Project(
                                name: name,
                                objectType: objectType.rawValue,
                                address: address,
                                startDate: startDate,
                                notes: notes,
                                status: "Planning"
                            )
                            onSave(project)
                            withAnimation { showConfirmation = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 16)

                        Spacer().frame(height: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("New Project")
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
