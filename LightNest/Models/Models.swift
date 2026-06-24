import Foundation
import SwiftUI

// MARK: - Project
struct Project: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var objectType: String
    var address: String
    var startDate: Date
    var notes: String
    var status: String = "Planning"
    var updatedAt: Date = Date()
    var isArchived: Bool = false
    var rooms: [Room] = []

    var statusColor: String {
        switch status {
        case "Active": return "#22C55E"
        case "Planning": return "#3B82F6"
        case "Attention": return "#FACC15"
        default: return "#64748B"
        }
    }
}

// MARK: - Room
struct Room: Identifiable, Codable {
    var id: UUID = UUID()
    var projectId: UUID
    var name: String
    var floor: Int
    var area: Double
    var notes: String
    var status: String = "Planning"
    var fixtures: [Fixture] = []
    var records: [LightRecord] = []
    var updatedAt: Date = Date()
}

// MARK: - Fixture (Light Source)
struct Fixture: Identifiable, Codable {
    var id: UUID = UUID()
    var roomId: UUID
    var name: String
    var type: String = "LED Downlight"
    var power: Double = 10.0         // Watts
    var colorTemperature: Double = 4000 // Kelvin
    var angle: Double = 60.0          // degrees beam angle
    var positionX: Double = 0.5       // 0..1 relative
    var positionY: Double = 0.5
    var height: Double = 2.7          // meters
    var isOn: Bool = true
    var lumens: Double {
        return power * 80 // rough lm/W ratio
    }
    var illuminance: Double {
        // Simplified: E = Flux / (pi * r^2) where r = height * tan(angle/2)
        let r = height * tan((angle / 2) * .pi / 180)
        let area = Double.pi * r * r
        return lumens / area
    }
}

// MARK: - LightRecord
struct LightRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var projectId: UUID
    var roomId: UUID?
    var title: String
    var date: Date
    var category: String
    var value: String
    var comment: String
    var status: String = "Open"
    var photoData: Data?
}

// MARK: - AppTask
struct AppTask: Identifiable, Codable {
    var id: UUID = UUID()
    var projectId: UUID?
    var title: String
    var description: String
    var dueDate: Date?
    var priority: String = "Normal"
    var isDone: Bool = false
    var category: String = "General"
    var createdAt: Date = Date()

    var isOverdue: Bool {
        guard let d = dueDate else { return false }
        return !isDone && d < Date()
    }

    var isToday: Bool {
        guard let d = dueDate else { return false }
        return Calendar.current.isDateInToday(d)
    }
}

// MARK: - CalendarEvent
struct CalendarEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var type: String = "Check"
    var projectId: UUID?
    var notes: String
}

// MARK: - Recommendation
struct Recommendation: Identifiable, Codable {
    var id: UUID = UUID()
    var projectId: UUID
    var title: String
    var description: String
    var type: String  // "fix", "buy", "check"
    var isDismissed: Bool = false
    var isAddedToTasks: Bool = false
    var createdAt: Date = Date()
}

// MARK: - Photo
struct AppPhoto: Identifiable, Codable {
    var id: UUID = UUID()
    var projectId: UUID
    var roomId: UUID?
    var category: String  // Before, Problem, Progress, After
    var caption: String
    var date: Date = Date()
    var imageData: Data?
}

// MARK: - Notification Setting
struct NotificationSetting: Identifiable, Codable {
    var id: UUID = UUID()
    var type: String     // deadline, warning, weekly
    var isEnabled: Bool
    var time: Date
}

// MARK: - SimulationCell
struct SimulationCell: Identifiable {
    var id: UUID = UUID()
    var gridX: Int
    var gridY: Int
    var illuminance: Double   // lux
    var color: Color {
        if illuminance > 500 { return Color(hex: "#FACC15").opacity(0.9) }
        if illuminance > 200 { return Color(hex: "#FACC15").opacity(0.5) }
        if illuminance > 50  { return Color(hex: "#F97316").opacity(0.3) }
        return Color(hex: "#1E293B")
    }
    var label: String {
        if illuminance > 500 { return "Bright" }
        if illuminance > 200 { return "Good" }
        if illuminance > 50  { return "Dim" }
        return "Dark"
    }
}

// MARK: - Report
struct Report: Identifiable, Codable {
    var id: UUID = UUID()
    var projectId: UUID
    var title: String
    var createdAt: Date = Date()
    var summary: String
}

// MARK: - Object Types
enum ObjectType: String, CaseIterable {
    case apartment = "Apartment"
    case house = "House"
    case office = "Office"
    case warehouse = "Warehouse"
    case retail = "Retail"
    case outdoor = "Outdoor"
}

// MARK: - Record Categories
enum RecordCategory: String, CaseIterable {
    case measurement = "Measurement"
    case issue = "Issue"
    case installation = "Installation"
    case note = "Note"
    case inspection = "Inspection"
}

// MARK: - Task Priority
enum TaskPriority: String, CaseIterable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"
    case urgent = "Urgent"

    var color: Color {
        switch self {
        case .low: return .textSecondary
        case .normal: return .accentBlue
        case .high: return .accentOrange
        case .urgent: return .statusError
        }
    }
}

// MARK: - Fixture Types
enum FixtureType: String, CaseIterable {
    case ledDownlight = "LED Downlight"
    case spotlight = "Spotlight"
    case floodlight = "Floodlight"
    case strip = "LED Strip"
    case pendant = "Pendant"
    case wallSconce = "Wall Sconce"
    case table = "Table Lamp"
    case floor = "Floor Lamp"
}
