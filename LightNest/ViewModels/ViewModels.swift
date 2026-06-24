import Foundation
import SwiftUI
import UserNotifications

// MARK: - FixtureViewModel
class FixtureViewModel: ObservableObject {
    @Published var fixtures: [Fixture] = []

    private let key = "ln_fixtures"

    init() { load() }

    func fixtures(for roomId: UUID) -> [Fixture] {
        fixtures.filter { $0.roomId == roomId }
    }

    func add(_ fixture: Fixture) {
        fixtures.append(fixture)
        save()
    }

    func update(_ fixture: Fixture) {
        if let idx = fixtures.firstIndex(where: { $0.id == fixture.id }) {
            fixtures[idx] = fixture
        }
        save()
    }

    func delete(_ fixture: Fixture) {
        fixtures.removeAll { $0.id == fixture.id }
        save()
    }

    func totalPower(for roomId: UUID) -> Double {
        fixtures(for: roomId).filter { $0.isOn }.reduce(0) { $0 + $1.power }
    }

    func totalLumens(for roomId: UUID) -> Double {
        fixtures(for: roomId).filter { $0.isOn }.reduce(0) { $0 + $1.lumens }
    }

    func averageColorTemp(for roomId: UUID) -> Double {
        let on = fixtures(for: roomId).filter { $0.isOn }
        guard !on.isEmpty else { return 0 }
        return on.reduce(0) { $0 + $1.colorTemperature } / Double(on.count)
    }

    // MARK: - Simulation grid (10x10)
    func simulationGrid(roomId: UUID, roomArea: Double) -> [[SimulationCell]] {
        let gridSize = 10
        let roomFixtures = fixtures(for: roomId).filter { $0.isOn }
        var grid = [[SimulationCell]]()
        for y in 0..<gridSize {
            var row = [SimulationCell]()
            for x in 0..<gridSize {
                let cellX = (Double(x) + 0.5) / Double(gridSize)
                let cellY = (Double(y) + 0.5) / Double(gridSize)
                var totalIlluminance = 0.0
                for fixture in roomFixtures {
                    let dx = cellX - fixture.positionX
                    let dy = cellY - fixture.positionY
                    let roomSide = sqrt(roomArea)
                    let distMeters = sqrt(dx * dx + dy * dy) * roomSide
                    let heightM = fixture.height
                    let dist3D = sqrt(distMeters * distMeters + heightM * heightM)
                    let cosAngle = heightM / dist3D
                    let halfAngleRad = (fixture.angle / 2) * .pi / 180
                    let spread = tan(halfAngleRad) * heightM
                    if distMeters <= spread * 1.5 {
                        let illuminance = (fixture.lumens * cosAngle * cosAngle) / (dist3D * dist3D)
                        totalIlluminance += illuminance
                    }
                }
                row.append(SimulationCell(gridX: x, gridY: y, illuminance: totalIlluminance))
            }
            grid.append(row)
        }
        return grid
    }

    private func save() {
        if let data = try? JSONEncoder().encode(fixtures) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Fixture].self, from: data) {
            fixtures = decoded
        }
    }
}

// MARK: - TaskViewModel
class TaskViewModel: ObservableObject {
    @Published var tasks: [AppTask] = []

    private let key = "ln_tasks"

    init() { load() }

    var todayTasks: [AppTask] { tasks.filter { $0.isToday && !$0.isDone } }
    var overdueTasks: [AppTask] { tasks.filter { $0.isOverdue } }
    var doneTasks: [AppTask] { tasks.filter { $0.isDone } }
    var pendingTasks: [AppTask] { tasks.filter { !$0.isDone } }

    func add(_ task: AppTask) {
        tasks.insert(task, at: 0)
        save()
    }

    func update(_ task: AppTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
        }
        save()
    }

    func markDone(_ task: AppTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isDone = true
        }
        save()
    }

    func delete(_ task: AppTask) {
        tasks.removeAll { $0.id == task.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([AppTask].self, from: data) {
            tasks = decoded
        }
    }
}

// MARK: - RecordViewModel
class RecordViewModel: ObservableObject {
    @Published var records: [LightRecord] = []

    private let key = "ln_records"

    init() { load() }

    func records(for projectId: UUID) -> [LightRecord] {
        records.filter { $0.projectId == projectId }
    }

    func add(_ record: LightRecord) {
        records.insert(record, at: 0)
        save()
    }

    func update(_ record: LightRecord) {
        if let idx = records.firstIndex(where: { $0.id == record.id }) {
            records[idx] = record
        }
        save()
    }

    func delete(_ record: LightRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([LightRecord].self, from: data) {
            records = decoded
        }
    }
}

// MARK: - NotificationManager
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func scheduleDeadline(for task: AppTask) {
        guard let due = task.dueDate else { return }
        let content = UNMutableNotificationContent()
        content.title = "Task Deadline"
        content.body = task.title
        content.sound = .default
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleWeeklyCheck() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Lighting Check"
        content.body = "Time to review your lighting plans and progress."
        content.sound = .default
        var comps = DateComponents()
        comps.weekday = 2; comps.hour = 9; comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_check", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - RecommendationViewModel
class RecommendationViewModel: ObservableObject {
    @Published var recommendations: [Recommendation] = []

    private let key = "ln_recs"

    init() { load() }

    func recommendations(for projectId: UUID) -> [Recommendation] {
        recommendations.filter { $0.projectId == projectId && !$0.isDismissed }
    }

    func add(_ rec: Recommendation) {
        recommendations.insert(rec, at: 0)
        save()
    }

    func dismiss(_ rec: Recommendation) {
        if let idx = recommendations.firstIndex(where: { $0.id == rec.id }) {
            recommendations[idx].isDismissed = true
        }
        save()
    }

    func addToTasks(_ rec: Recommendation) {
        if let idx = recommendations.firstIndex(where: { $0.id == rec.id }) {
            recommendations[idx].isAddedToTasks = true
        }
        save()
    }

    func generateRecommendations(for project: Project, fixtureVM: FixtureViewModel, roomVM: RoomViewModel) {
        let rooms = roomVM.rooms(for: project.id)
        var newRecs: [Recommendation] = []
        for room in rooms {
            let roomFixtures = fixtureVM.fixtures(for: room.id)
            if roomFixtures.isEmpty {
                newRecs.append(Recommendation(
                    projectId: project.id,
                    title: "No fixtures in \(room.name)",
                    description: "Add at least one light fixture to simulate this room's lighting.",
                    type: "fix"
                ))
            } else {
                let totalLumens = fixtureVM.totalLumens(for: room.id)
                let recommended = room.area * 100
                if totalLumens < recommended {
                    newRecs.append(Recommendation(
                        projectId: project.id,
                        title: "Insufficient light in \(room.name)",
                        description: "Current \(Int(totalLumens)) lm is below recommended \(Int(recommended)) lm for \(Int(room.area)) m².",
                        type: "buy"
                    ))
                }
                let avgTemp = fixtureVM.averageColorTemp(for: room.id)
                if avgTemp > 5500 {
                    newRecs.append(Recommendation(
                        projectId: project.id,
                        title: "Color temperature too cool in \(room.name)",
                        description: "Average \(Int(avgTemp))K is very cool. Consider warmer fixtures for comfort.",
                        type: "check"
                    ))
                }
            }
        }
        for rec in newRecs {
            recommendations.insert(rec, at: 0)
        }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(recommendations) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Recommendation].self, from: data) {
            recommendations = decoded
        }
    }
}

// MARK: - CalendarViewModel
class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []

    private let key = "ln_events"

    init() { load() }

    func events(on date: Date) -> [CalendarEvent] {
        events.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func add(_ event: CalendarEvent) {
        events.insert(event, at: 0)
        save()
    }

    func delete(_ event: CalendarEvent) {
        events.removeAll { $0.id == event.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([CalendarEvent].self, from: data) {
            events = decoded
        }
    }
}
