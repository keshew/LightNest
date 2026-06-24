import SwiftUI

struct RoomsListView: View {
    let project: Project
    @EnvironmentObject var roomVM: RoomViewModel
    @EnvironmentObject var fixtureVM: FixtureViewModel
    @EnvironmentObject var recVM: RecommendationViewModel
    @State private var showAddRoom = false
    @State private var filterStatus = "All"

    let statusFilters = ["All", "Planning", "Active", "Done"]

    var filteredRooms: [Room] {
        let rooms = roomVM.rooms(for: project.id)
        if filterStatus == "All" { return rooms }
        return rooms.filter { $0.status == filterStatus }
    }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Filter bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(statusFilters, id: \.self) { f in
                            Button(f) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    filterStatus = f
                                }
                            }
                            .font(.system(size: 13, weight: filterStatus == f ? .semibold : .medium))
                            .foregroundColor(filterStatus == f ? Color.bgPrimary : Color.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(filterStatus == f ? Color.accentYellow : Color.cardBg)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)

                if filteredRooms.isEmpty {
                    VStack {
                        Spacer()
                        EmptyStateView(
                            icon: "square.3.layers.3d",
                            title: "No rooms yet",
                            subtitle: "Add rooms to start planning your lighting layout",
                            action: { showAddRoom = true },
                            actionLabel: "Add Room"
                        )
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(filteredRooms) { room in
                                NavigationLink(destination: RoomDetailView(room: room, project: project)) {
                                    RoomCard(room: room, fixtureVM: fixtureVM)
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer().frame(height: 80)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddRoom = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(Color.accentYellow)
                }
            }
        }
        .sheet(isPresented: $showAddRoom) {
            AddRoomView(projectId: project.id) { room in
                roomVM.add(room)
            }
        }
    }
}

struct RoomCard: View {
    let room: Room
    let fixtureVM: FixtureViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(room.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    HStack(spacing: 6) {
                        Text("Floor \(room.floor)")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textInactive)
                        Text("·")
                            .foregroundColor(Color.textInactive)
                        Text(String(format: "%.1f m²", room.area))
                            .font(.system(size: 12))
                            .foregroundColor(Color.textInactive)
                    }
                }
                Spacer()
                StatusBadge(status: room.status)
            }

            HStack(spacing: 16) {
                RoomStatBadge(
                    icon: "lightbulb.fill",
                    value: "\(fixtureVM.fixtures(for: room.id).count)",
                    label: "Fixtures",
                    color: .accentYellow
                )
                RoomStatBadge(
                    icon: "bolt.fill",
                    value: "\(Int(fixtureVM.totalPower(for: room.id)))W",
                    label: "Power",
                    color: .accentOrange
                )
                RoomStatBadge(
                    icon: "sun.max.fill",
                    value: "\(Int(fixtureVM.totalLumens(for: room.id)))lm",
                    label: "Lumens",
                    color: .accentBlueSoft
                )
            }

            // Mini light bar
            let fixtures = fixtureVM.fixtures(for: room.id)
            if !fixtures.isEmpty {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(fixtures.prefix(8)) { f in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(f.isOn ? Color.accentYellow : Color.divider)
                                .frame(height: 4)
                        }
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(16)
        .cardStyle()
    }
}

struct RoomStatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color.textInactive)
        }
    }
}

// MARK: - Add Room
struct AddRoomView: View {
    let projectId: UUID
    let onSave: (Room) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var floor = 1
    @State private var area = ""
    @State private var notes = ""
    @State private var showConfirmation = false
    @State private var nameError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        ConfirmationBanner(message: "Room saved!", isShowing: $showConfirmation)

                        VStack(spacing: 16) {
                            LNTextField(label: "Room Name *", text: $name, placeholder: "e.g. Living Room")
                                .overlay(nameError ? RoundedRectangle(cornerRadius: 10).stroke(Color.statusError, lineWidth: 1) : nil)

                            // Floor selector
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Floor")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.textSecondary)

                                HStack(spacing: 8) {
                                    ForEach(1...5, id: \.self) { f in
                                        Button("\(f)") {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                floor = f
                                            }
                                        }
                                        .font(.system(size: 15, weight: floor == f ? .semibold : .regular))
                                        .foregroundColor(floor == f ? Color.bgPrimary : Color.textSecondary)
                                        .frame(width: 44, height: 44)
                                        .background(floor == f ? Color.accentYellow : Color.cardBg)
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.divider, lineWidth: 1))
                                    }
                                }
                            }

                            LNTextField(
                                label: "Area (m²)",
                                text: $area,
                                placeholder: "e.g. 24.5",
                                keyboardType: .decimalPad
                            )

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                                TextEditor(text: $notes)
                                    .frame(height: 80)
                                    .foregroundColor(Color.textPrimary)
                                    .font(.system(size: 15))
                                    .padding(8)
                                    .background(Color.bgSoft)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.divider, lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 16)

                        Button("Save Room") {
                            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                                withAnimation { nameError = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { nameError = false } }
                                return
                            }
                            let room = Room(
                                projectId: projectId,
                                name: name,
                                floor: floor,
                                area: Double(area) ?? 0,
                                notes: notes,
                                status: "Planning"
                            )
                            onSave(room)
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
            .navigationTitle("Add Room")
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

// MARK: - Room Detail
struct RoomDetailView: View {
    let room: Room
    let project: Project
    @EnvironmentObject var fixtureVM: FixtureViewModel
    @EnvironmentObject var recVM: RecommendationViewModel
    @EnvironmentObject var roomVM: RoomViewModel
    @State private var showSimulation = false
    @State private var showAddFixture = false
    @State private var showRecommendations = false

    var fixtures: [Fixture] { fixtureVM.fixtures(for: room.id) }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Room info card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(room.name)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Color.textPrimary)
                                Text("Floor \(room.floor)  ·  \(String(format: "%.1f", room.area)) m²")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.textSecondary)
                            }
                            Spacer()
                            StatusBadge(status: room.status)
                        }

                        if !room.notes.isEmpty {
                            Text(room.notes)
                                .font(.system(size: 14))
                                .foregroundColor(Color.textSecondary)
                        }

                        HStack(spacing: 12) {
                            RoomStatBadge(icon: "lightbulb.fill", value: "\(fixtures.count)", label: "Fixtures", color: .accentYellow)
                            RoomStatBadge(icon: "bolt.fill", value: "\(Int(fixtureVM.totalPower(for: room.id)))W", label: "Power", color: .accentOrange)
                            RoomStatBadge(icon: "thermometer.medium", value: "\(Int(fixtureVM.averageColorTemp(for: room.id)))K", label: "Avg Temp", color: .accentBlueSoft)
                            RoomStatBadge(icon: "sun.max.fill", value: "\(Int(fixtureVM.totalLumens(for: room.id)))lm", label: "Lumens", color: .statusDone)
                        }
                    }
                    .padding(16)
                    .cardStyle()
                    .padding(.horizontal, 16)

                    // Action buttons
                    HStack(spacing: 10) {
                        Button(action: { showSimulation = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "waveform.path.ecg")
                                Text("Simulate")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.bgPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentYellow)
                            .cornerRadius(12)
                        }
                        Button(action: { showRecommendations = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                Text("Tips")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.cardBg)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 16)

                    // Fixtures section
                    VStack(spacing: 12) {
                        HStack {
                            SectionHeader(title: "Fixtures")
                            Spacer()
                            Button(action: { showAddFixture = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Add")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.accentYellow)
                            }
                        }
                        .padding(.horizontal, 16)

                        if fixtures.isEmpty {
                            EmptyStateView(
                                icon: "lightbulb",
                                title: "No fixtures",
                                subtitle: "Add light fixtures to simulate this room",
                                action: { showAddFixture = true },
                                actionLabel: "Add Fixture"
                            )
                        } else {
                            ForEach(fixtures) { fixture in
                                FixtureRow(fixture: fixture) {
                                    var updated = fixture
                                    updated.isOn.toggle()
                                    fixtureVM.update(updated)
                                } onDelete: {
                                    fixtureVM.delete(fixture)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    Spacer().frame(height: 80)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Room")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSimulation) {
            SimulationView(room: room)
        }
        .sheet(isPresented: $showAddFixture) {
            AddFixtureView(roomId: room.id) { fixture in
                fixtureVM.add(fixture)
            }
        }
        .sheet(isPresented: $showRecommendations) {
            RecommendationsView(project: project)
        }
    }
}

struct FixtureRow: View {
    let fixture: Fixture
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(fixture.isOn ? Color.accentYellow.opacity(0.2) : Color.cardBg)
                        .frame(width: 40, height: 40)
                    Image(systemName: fixture.isOn ? "lightbulb.fill" : "lightbulb")
                        .font(.system(size: 18))
                        .foregroundColor(fixture.isOn ? Color.accentYellow : Color.textInactive)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(fixture.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                HStack(spacing: 8) {
                    Text("\(Int(fixture.power))W")
                        .font(.system(size: 12))
                        .foregroundColor(Color.accentOrange)
                    Text("\(Int(fixture.colorTemperature))K")
                        .font(.system(size: 12))
                        .foregroundColor(Color.accentBlueSoft)
                    Text("\(Int(fixture.angle))°")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textInactive)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(fixture.lumens))lm")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.textSecondary)
                Text(fixture.isOn ? "On" : "Off")
                    .font(.system(size: 11))
                    .foregroundColor(fixture.isOn ? Color.statusDone : Color.textInactive)
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(Color.statusError.opacity(0.7))
            }
        }
        .padding(12)
        .cardStyle()
    }
}
