import Foundation
import SwiftUI
import Combine

// MARK: - ProjectViewModel
class ProjectViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var selectedProject: Project?

    private let key = "ln_projects"

    init() { load() }

    var activeProjects: [Project] { projects.filter { !$0.isArchived } }
    var archivedProjects: [Project] { projects.filter { $0.isArchived } }

    func add(_ project: Project) {
        var p = project
        p.updatedAt = Date()
        projects.insert(p, at: 0)
        save()
    }

    func update(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            var p = project
            p.updatedAt = Date()
            projects[idx] = p
            if selectedProject?.id == project.id { selectedProject = p }
        }
        save()
    }

    func archive(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx].isArchived = true
        }
        save()
    }

    func unarchive(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx].isArchived = false
        }
        save()
    }

    func delete(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        save()
    }

    func totalEnergyForProject(_ id: UUID, fixtureVM: FixtureViewModel) -> Double {
        let fixtures = fixtureVM.fixtures.filter { $0.isOn }
        return fixtures.reduce(0) { $0 + $1.power } / 1000.0
    }

    private func save() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        } else {
            projects = Project.sampleData
        }
    }
}

// MARK: - RoomViewModel
class RoomViewModel: ObservableObject {
    @Published var rooms: [Room] = []

    private let key = "ln_rooms"

    init() { load() }

    func rooms(for projectId: UUID) -> [Room] {
        rooms.filter { $0.projectId == projectId }
    }

    func add(_ room: Room) {
        var r = room
        r.updatedAt = Date()
        rooms.insert(r, at: 0)
        save()
    }

    func update(_ room: Room) {
        if let idx = rooms.firstIndex(where: { $0.id == room.id }) {
            var r = room
            r.updatedAt = Date()
            rooms[idx] = r
        }
        save()
    }

    func delete(_ room: Room) {
        rooms.removeAll { $0.id == room.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(rooms) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Room].self, from: data) {
            rooms = decoded
        }
    }
}

// MARK: - Sample Data
extension Project {
    static var sampleData: [Project] = [
        Project(
            id: UUID(),
            name: "Living Room Redesign",
            objectType: "Apartment",
            address: "Apt 4B, Main St",
            startDate: Date(),
            notes: "Full lighting overhaul for open-plan living area.",
            status: "Active"
        ),
        Project(
            id: UUID(),
            name: "Office Lighting",
            objectType: "Office",
            address: "Tech Park, Floor 3",
            startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
            notes: "Replace fluorescent with LED panels.",
            status: "Planning"
        )
    ]
}
