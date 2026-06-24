import SwiftUI
import CoreMotion

struct OnboardingContainerView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            TabView(selection: $currentPage) {
                OnboardingPage1().tag(0)
                OnboardingPage2().tag(1)
                OnboardingPage3().tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                HStack {
                    Button("Skip") {
                        complete()
                    }
                    .foregroundColor(Color.textInactive)
                    .font(.system(size: 15, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    Spacer()
                }
                .padding(.top, 8)

                Spacer()

                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<3) { i in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(i == currentPage ? Color.accentYellow : Color.divider)
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    Button(action: {
                        if currentPage < 2 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            complete()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(currentPage < 2 ? "Next" : "Get Started")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: currentPage < 2 ? "arrow.right" : "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 50)
            }
        }
    }

    private func complete() {
        hasCompletedOnboarding = true
        onComplete()
    }
}

// MARK: - Page 1: Tap-to-trigger particle burst
struct OnboardingPage1: View {
    @State private var isVisible = false
    @State private var tapped = false
    @State private var particles: [BurstParticle] = []
    @State private var bulbScale: CGFloat = 1.0
    @State private var glowRadius: CGFloat = 0

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            // Floating light halos
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.accentYellow.opacity(0.06 - Double(i) * 0.015), lineWidth: 1)
                    .frame(width: CGFloat(180 + i * 80), height: CGFloat(180 + i * 80))
                    .scaleEffect(isVisible ? 1.0 : 0.5)
                    .opacity(isVisible ? 1 : 0)
                    .animation(
                        Animation.easeOut(duration: 0.8).delay(Double(i) * 0.15),
                        value: isVisible
                    )
            }

            // Particles from tap
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .offset(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }

            // Glow behind bulb
            Circle()
                .fill(Color.accentYellow.opacity(0.2))
                .frame(width: 160, height: 160)
                .blur(radius: glowRadius)
                .animation(.easeOut(duration: 0.4), value: glowRadius)

            VStack(spacing: 0) {
                Spacer()

                // Interactive light bulb
                Button(action: triggerBurst) {
                    ZStack {
                        Circle()
                            .fill(Color.cardBg)
                            .frame(width: 140, height: 140)
                            .overlay(Circle().stroke(Color.accentYellow.opacity(0.3), lineWidth: 1.5))

                        Image(systemName: tapped ? "lightbulb.fill" : "lightbulb")
                            .font(.system(size: 60, weight: .light))
                            .foregroundStyle(
                                tapped
                                ? LinearGradient(colors: [Color.accentYellow, Color.accentOrange], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Color.textInactive, Color.textSecondary], startPoint: .top, endPoint: .bottom)
                            )
                    }
                    .scaleEffect(bulbScale)
                }
                .buttonStyle(.plain)

                if !tapped {
                    Text("Tap the bulb")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.textInactive)
                        .padding(.top, 12)
                        .transition(.opacity)
                }

                Spacer().frame(height: 40)

                VStack(spacing: 16) {
                    Text("Understand the problem")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Your room is dark.\nShadows where you least want them.\nWrong fixtures, wrong placement.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    Spacer()
                        .frame(height: 50)
                }
                .padding(.horizontal, 32)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: isVisible)

                Spacer().frame(height: 120)
            }
        }
        .onAppear {
            withAnimation { isVisible = true }
        }
        .onDisappear {
            isVisible = false
            tapped = false
            particles = []
            glowRadius = 0
            bulbScale = 1.0
        }
    }

    private func triggerBurst() {
        tapped = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            bulbScale = 1.15
            glowRadius = 30
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                bulbScale = 1.0
            }
        }

        let colors: [Color] = [.accentYellow, .accentOrange, .accentYellowLight, .accentOrangeSoft, .accentBlue]
        var newParticles: [BurstParticle] = []
        for _ in 0..<20 {
            let angle = Double.random(in: 0..<360) * .pi / 180
            let dist = CGFloat.random(in: 60...160)
            newParticles.append(BurstParticle(
                x: cos(angle) * dist,
                y: sin(angle) * dist - 70,
                size: CGFloat.random(in: 3...8),
                color: colors.randomElement()!,
                opacity: Double.random(in: 0.6...1.0)
            ))
        }
        particles = newParticles
        withAnimation(.easeOut(duration: 0.8)) {}
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                for i in particles.indices { particles[i].opacity = 0 }
            }
        }
    }
}

struct BurstParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
}

// MARK: - Page 2: Drag gesture animation
struct OnboardingPage2: View {
    @State private var isVisible = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            // Grid lines background
            Canvas { ctx, size in
                let spacing: CGFloat = 40
                ctx.opacity = 0.04
                var x: CGFloat = 0
                while x < size.width {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    ctx.stroke(path, with: .color(.white), lineWidth: 0.5)
                    x += spacing
                }
                var y: CGFloat = 0
                while y < size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(path, with: .color(.white), lineWidth: 0.5)
                    y += spacing
                }
            }

            VStack(spacing: 0) {
                Spacer()

                // Draggable fixture
                ZStack {
                    // Light cone visualization
                    let dragX = dragOffset.width
                    let dragY = dragOffset.height
                    let intensity = min(1.0, Double(100 / max(1, abs(dragX) + abs(dragY))))

                    RadialGradient(
                        colors: [Color.accentYellow.opacity(0.25 * intensity), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                    .frame(width: 180, height: 180)
                    .offset(dragOffset)

                    // Draggable fixture circle
                    ZStack {
                        Circle()
                            .fill(Color.cardBg)
                            .frame(width: 60, height: 60)
                            .overlay(Circle().stroke(Color.accentYellow.opacity(isDragging ? 0.8 : 0.4), lineWidth: 2))
                            .shadow(color: Color.accentYellow.opacity(isDragging ? 0.4 : 0.1), radius: 12)

                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.accentYellow)
                    }
                    .offset(dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { v in
                                isDragging = true
                                let maxOffset: CGFloat = 100
                                dragOffset = CGSize(
                                    width: max(-maxOffset, min(maxOffset, v.translation.width)),
                                    height: max(-maxOffset, min(maxOffset, v.translation.height))
                                )
                            }
                            .onEnded { _ in
                                isDragging = false
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    dragOffset = .zero
                                }
                            }
                    )

                    if dragOffset == .zero && !isDragging {
                        Text("drag to place")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.textInactive)
                            .offset(y: 42)
                    }
                }
                .frame(height: 200)

                Spacer().frame(height: 32)

                VStack(spacing: 16) {
                    Text("Track everything")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Place fixtures precisely.\nSee how light distributes across every corner\nof your space.")
                        .font(.system(size: 16))
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    Spacer()
                        .frame(height: 50)
                }
                .padding(.horizontal, 32)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: isVisible)

                Spacer().frame(height: 120)
            }
        }
        .onAppear { withAnimation { isVisible = true } }
        .onDisappear { isVisible = false; dragOffset = .zero; isDragging = false }
    }
}

// MARK: - Page 3: Scroll-driven parallax
struct OnboardingPage3: View {
    @State private var isVisible = false
    @State private var scrollProgress: CGFloat = 0
    @State private var layer1Offset: CGFloat = 0
    @State private var layer2Offset: CGFloat = 0
    @State private var layer3Offset: CGFloat = 0
    @State private var animating = false

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            // Parallax layers
            ZStack {
                // Layer 1 - slowest
                ForEach(0..<6) { i in
                    Circle()
                        .fill(Color.accentYellow.opacity(0.04))
                        .frame(width: CGFloat(30 + i * 15), height: CGFloat(30 + i * 15))
                        .offset(
                            x: CGFloat([-80, 90, -60, 110, -100, 70][i]),
                            y: CGFloat([-120, -80, 50, 20, 100, -150][i]) + layer1Offset
                        )
                }
                // Layer 2 - medium
                ForEach(0..<4) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentOrange.opacity(0.06))
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(45))
                        .offset(
                            x: CGFloat([-110, 80, -40, 120][i]),
                            y: CGFloat([30, -100, 150, -40][i]) + layer2Offset
                        )
                }
                // Layer 3 - fastest
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.accentBlue.opacity(0.08))
                        .frame(width: CGFloat(8 + i * 4), height: CGFloat(8 + i * 4))
                        .offset(
                            x: CGFloat([-50, 60, -90][i]),
                            y: CGFloat([80, -60, 130][i]) + layer3Offset
                        )
                }
            }
            .opacity(isVisible ? 1 : 0)
            .animation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animating)

            VStack(spacing: 0) {
                Spacer()

                // Energy meter visualization
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.divider, lineWidth: 8)
                            .frame(width: 140, height: 140)

                        Circle()
                            .trim(from: 0, to: isVisible ? 0.73 : 0)
                            .stroke(
                                LinearGradient(colors: [Color.accentYellow, Color.accentOrange], startPoint: .leading, endPoint: .trailing),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.2).delay(0.3), value: isVisible)

                        VStack(spacing: 2) {
                            Text("73%")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color.accentYellow)
                            Text("efficiency")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1)
                        }
                    }

                    HStack(spacing: 20) {
                        EnergyBadge(icon: "bolt.fill", value: "340W", label: "Power", color: .accentYellow)
                        EnergyBadge(icon: "thermometer.medium", value: "3800K", label: "Temp", color: .accentOrange)
                        EnergyBadge(icon: "sun.max.fill", value: "680lx", label: "Avg Lux", color: .accentBlueSoft)
                    }
                }
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6), value: isVisible)

                Spacer().frame(height: 32)

                VStack(spacing: 16) {
                    Text("Get better results")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Track energy use, optimize placement,\nget clear reports before you spend\na single dollar on fixtures.")
                        .font(.system(size: 16))
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    Spacer()
                        .frame(height: 50)
                }
                .padding(.horizontal, 32)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)

                Spacer().frame(height: 120)
            }
        }
        .onAppear {
            withAnimation { isVisible = true }
            animating = true
            withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                layer1Offset = -20
                layer2Offset = 30
                layer3Offset = -15
            }
        }
        .onDisappear {
            isVisible = false
            animating = false
            layer1Offset = 0
            layer2Offset = 0
            layer3Offset = 0
        }
    }
}

struct EnergyBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.textInactive)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(width: 70)
        .padding(.vertical, 12)
        .background(Color.cardBg)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))
    }
}
