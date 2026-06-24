import SwiftUI

// MARK: - Add Fixture
struct AddFixtureView: View {
    let roomId: UUID
    let onSave: (Fixture) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var type = FixtureType.ledDownlight
    @State private var power: Double = 10
    @State private var colorTemp: Double = 4000
    @State private var angle: Double = 60
    @State private var height: Double = 2.7
    @State private var posX: Double = 0.5
    @State private var posY: Double = 0.5
    @State private var showConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        ConfirmationBanner(message: "Fixture added!", isShowing: $showConfirmation)

                        VStack(spacing: 16) {
                            LNTextField(label: "Fixture Name", text: $name, placeholder: "e.g. Main Downlight")
                            LNPickerField(label: "Type", selection: $type, options: FixtureType.allCases)

                            // Power slider
                            SliderField(
                                label: "Power",
                                value: $power,
                                range: 1...200,
                                displayFormat: { "\(Int($0))W" },
                                color: .accentOrange
                            )

                            // Color Temperature
                            SliderField(
                                label: "Color Temperature",
                                value: $colorTemp,
                                range: 2700...6500,
                                displayFormat: { "\(Int($0))K" },
                                color: colorTempColor(colorTemp)
                            )

                            // Angle
                            SliderField(
                                label: "Beam Angle",
                                value: $angle,
                                range: 10...120,
                                displayFormat: { "\(Int($0))°" },
                                color: .accentYellow
                            )

                            // Mount height
                            SliderField(
                                label: "Mount Height",
                                value: $height,
                                range: 0.5...5.0,
                                displayFormat: { String(format: "%.1fm", $0) },
                                color: .accentBlueSoft
                            )

                            // Position
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Position in room")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.textSecondary)

                                PositionPicker(x: $posX, y: $posY)
                            }

                            // Preview card
                            fixturePreview
                        }
                        .padding(.horizontal, 16)

                        Button("Add Fixture") {
                            let fixtureName = name.isEmpty ? type.rawValue : name
                            let fixture = Fixture(
                                roomId: roomId,
                                name: fixtureName,
                                type: type.rawValue,
                                power: power,
                                colorTemperature: colorTemp,
                                angle: angle,
                                positionX: posX,
                                positionY: posY,
                                height: height,
                                isOn: true
                            )
                            onSave(fixture)
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
            .navigationTitle("Add Fixture")
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

    private var fixturePreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preview")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.textSecondary)

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(colorTempColor(colorTemp).opacity(0.2))
                        .frame(width: 60, height: 60)
                        .blur(radius: 8)
                    Circle()
                        .fill(Color.cardBg)
                        .frame(width: 48, height: 48)
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 22))
                        .foregroundColor(colorTempColor(colorTemp))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(name.isEmpty ? type.rawValue : name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    Text("\(Int(power))W · \(Int(colorTemp))K · \(Int(angle))° beam")
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)
                    Text("~\(Int(power * 80)) lumens · \(String(format: "%.1f", height))m mount")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textInactive)
                }
            }
        }
        .padding(14)
        .cardStyle()
    }

    private func colorTempColor(_ k: Double) -> Color {
        if k < 3000 { return Color(hex: "#FDBA74") }
        if k < 4500 { return Color(hex: "#FDE047") }
        return Color(hex: "#BAE6FD")
    }
}

struct SliderField: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let displayFormat: (Double) -> String
    var color: Color = .accentYellow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.textSecondary)
                Spacer()
                Text(displayFormat(value))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range)
                .tint(color)
        }
        .padding(12)
        .background(Color.bgSoft)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.divider, lineWidth: 1))
    }
}

struct PositionPicker: View {
    @Binding var x: Double
    @Binding var y: Double
    @State private var dragLocation: CGPoint = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Room grid
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.bgSoft)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.divider, lineWidth: 1)
                    )

                // Grid lines
                Canvas { ctx, size in
                    ctx.opacity = 0.1
                    let cols = 4
                    let rows = 4
                    for i in 1..<cols {
                        var p = Path()
                        let xPos = size.width * CGFloat(i) / CGFloat(cols)
                        p.move(to: CGPoint(x: xPos, y: 0))
                        p.addLine(to: CGPoint(x: xPos, y: size.height))
                        ctx.stroke(p, with: .color(.white), lineWidth: 0.5)
                    }
                    for i in 1..<rows {
                        var p = Path()
                        let yPos = size.height * CGFloat(i) / CGFloat(rows)
                        p.move(to: CGPoint(x: 0, y: yPos))
                        p.addLine(to: CGPoint(x: size.width, y: yPos))
                        ctx.stroke(p, with: .color(.white), lineWidth: 0.5)
                    }
                }

                // Light cone preview
                RadialGradient(
                    colors: [Color.accentYellow.opacity(0.3), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 30
                )
                .frame(width: 80, height: 80)
                .position(
                    x: x * geo.size.width,
                    y: y * geo.size.height
                )

                // Fixture dot
                Circle()
                    .fill(Color.accentYellow)
                    .frame(width: 16, height: 16)
                    .shadow(color: Color.accentYellow.opacity(0.5), radius: 4)
                    .position(
                        x: x * geo.size.width,
                        y: y * geo.size.height
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { val in
                                x = max(0.05, min(0.95, val.location.x / geo.size.width))
                                y = max(0.05, min(0.95, val.location.y / geo.size.height))
                            }
                    )

                // Tap to place
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            x = location.x / geo.size.width
                            y = location.y / geo.size.height
                        }
                    }
            }
        }
        .frame(height: 160)
    }
}

// MARK: - Simulation View (Main Feature)
struct SimulationView: View {
    let room: Room
    @EnvironmentObject var fixtureVM: FixtureViewModel
    @Environment(\.dismiss) var dismiss

    @State private var simulationGrid: [[SimulationCell]] = []
    @State private var hasRunSimulation = false
    @State private var isRunning = false
    @State private var showLegend = false
    @State private var progress: Double = 0
    @State private var selectedCell: SimulationCell?

    var fixtures: [Fixture] { fixtureVM.fixtures(for: room.id) }

    var darkZones: Int {
        simulationGrid.flatMap { $0 }.filter { $0.illuminance < 50 }.count
    }
    var brightZones: Int {
        simulationGrid.flatMap { $0 }.filter { $0.illuminance > 500 }.count
    }
    var goodZones: Int {
        simulationGrid.flatMap { $0 }.filter { $0.illuminance >= 50 && $0.illuminance <= 500 }.count
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Room + fixture summary
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(room.name)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color.textPrimary)
                                Text("\(fixtures.count) active fixture\(fixtures.count == 1 ? "" : "s")")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.textSecondary)
                            }
                            Spacer()
                            Text("\(String(format: "%.1f", room.area)) m²")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.accentYellow)
                        }
                        .padding(14)
                        .cardStyle()
                        .padding(.horizontal, 16)

                        // Simulation grid
                        VStack(spacing: 8) {
                            HStack {
                                Text("Light Map")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.textPrimary)
                                Spacer()
                                Button(action: { showLegend.toggle() }) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(Color.textInactive)
                                }
                            }
                            .padding(.horizontal, 16)

                            if hasRunSimulation {
                                simulationGridView
                            } else {
                                placeholderGrid
                            }

                            if hasRunSimulation {
                                zoneStatsRow
                                    .padding(.horizontal, 16)
                            }
                        }

                        // Controls
                        fixtureControls

                        // Run button
                        Button(action: runSimulation) {
                            HStack(spacing: 8) {
                                if isRunning {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color.bgPrimary))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "play.fill")
                                }
                                Text(isRunning ? "Calculating..." : "Run Simulation")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 16)
                        .disabled(isRunning || fixtures.isEmpty)
                        .opacity(fixtures.isEmpty ? 0.5 : 1)

                        if fixtures.isEmpty {
                            Text("Add fixtures to this room first")
                                .font(.system(size: 13))
                                .foregroundColor(Color.textInactive)
                        }

                        if showLegend {
                            legendView
                                .padding(.horizontal, 16)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Simulation")
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

    private var simulationGridView: some View {
        VStack(spacing: 2) {
            ForEach(0..<simulationGrid.count, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(simulationGrid[row]) { cell in
                        Rectangle()
                            .fill(cell.color)
                            .frame(height: 28)
                            .cornerRadius(3)
                            .overlay(
                                selectedCell?.id == cell.id
                                ? RoundedRectangle(cornerRadius: 3).stroke(Color.white, lineWidth: 1)
                                : nil
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCell = cell
                                }
                            }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .overlay(
            Group {
                if let cell = selectedCell {
                    HStack(spacing: 6) {
                        Text(cell.label)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        Text("\(Int(cell.illuminance)) lux")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.bgDepth.opacity(0.95))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.divider, lineWidth: 1))
                }
            },
            alignment: .bottom
        )
    }

    private var placeholderGrid: some View {
        VStack(spacing: 2) {
            ForEach(0..<10, id: \.self) { _ in
                HStack(spacing: 2) {
                    ForEach(0..<10, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.bgSoft)
                            .frame(height: 28)
                            .cornerRadius(3)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .overlay(
            VStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 28))
                    .foregroundColor(Color.textInactive)
                Text("Tap Run Simulation")
                    .font(.system(size: 14))
                    .foregroundColor(Color.textInactive)
            }
        )
    }

    private var zoneStatsRow: some View {
        HStack(spacing: 12) {
            ZoneStatBadge(count: darkZones, label: "Dark", color: Color.bgSoft, icon: "moon.fill")
            ZoneStatBadge(count: goodZones, label: "Good", color: Color.accentYellow.opacity(0.5), icon: "sun.min.fill")
            ZoneStatBadge(count: brightZones, label: "Bright", color: Color.accentYellow, icon: "sun.max.fill")
        }
    }

    private var fixtureControls: some View {
        VStack(spacing: 10) {
            SectionHeader(title: "Fixtures")
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(fixtures) { fixture in
                        FixtureControlChip(fixture: fixture) {
                            var f = fixture
                            f.isOn.toggle()
                            fixtureVM.update(f)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Illuminance Legend")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.textPrimary)
            LegendRow(color: Color.bgSoft, label: "Dark zones", range: "< 50 lux")
            LegendRow(color: Color.accentOrange.opacity(0.3), label: "Dim zones", range: "50–200 lux")
            LegendRow(color: Color.accentYellow.opacity(0.5), label: "Good zones", range: "200–500 lux")
            LegendRow(color: Color.accentYellow.opacity(0.9), label: "Bright zones", range: "> 500 lux")
        }
        .padding(14)
        .cardStyle()
    }

    private func runSimulation() {
        guard !fixtures.isEmpty else { return }
        isRunning = true
        selectedCell = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let area = max(room.area, 1.0)
            let grid = fixtureVM.simulationGrid(roomId: room.id, roomArea: area)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.3)) {
                    simulationGrid = grid
                    hasRunSimulation = true
                    isRunning = false
                }
            }
        }
    }
}

struct ZoneStatBadge: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color == Color.bgSoft ? Color.textInactive : color)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(count)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(Color.textInactive)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .cardStyle()
    }
}

struct FixtureControlChip: View {
    let fixture: Fixture
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 6) {
                Image(systemName: fixture.isOn ? "lightbulb.fill" : "lightbulb")
                    .font(.system(size: 18))
                    .foregroundColor(fixture.isOn ? Color.accentYellow : Color.textInactive)
                Text(fixture.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(1)
                Text(fixture.isOn ? "On" : "Off")
                    .font(.system(size: 10))
                    .foregroundColor(fixture.isOn ? Color.statusDone : Color.textInactive)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(fixture.isOn ? Color.accentYellow.opacity(0.12) : Color.cardBg)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                fixture.isOn ? Color.accentYellow.opacity(0.4) : Color.divider,
                lineWidth: 1
            ))
        }
    }
}

struct LegendRow: View {
    let color: Color
    let label: String
    let range: String

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 24, height: 14)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color.textSecondary)
            Spacer()
            Text(range)
                .font(.system(size: 12))
                .foregroundColor(Color.textInactive)
        }
    }
}
