import SwiftUI

struct SplashView: View {
    let onFinish: () -> Void

    @State private var isVisible = false
    // Layer 1: BG gradient pulse
    @State private var bgPulse = false
    // Layer 2: Rotating light rays
    @State private var rayRotation: Double = 0
    @State private var rayOpacity: Double = 0
    // Layer 3: Light particles
    @State private var particlesVisible = false
    @State private var particle1Offset: CGFloat = 0
    @State private var particle2Offset: CGFloat = 0
    @State private var particle3Offset: CGFloat = 0
    // Layer 4: Logo entrance
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    // Exit
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0

    var body: some View {
        ZStack {
            // Background gradient (Layer 1)
            RadialGradient(
                colors: [
                    bgPulse ? Color(hex: "#1A1500") : Color(hex: "#0F172A"),
                    Color.bgDepth,
                    Color.bgPrimary
                ],
                center: .center,
                startRadius: bgPulse ? 50 : 20,
                endRadius: 400
            )
            .ignoresSafeArea()
            .animation(
                isVisible ? Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true) : .default,
                value: bgPulse
            )

            // Light rays (Layer 2)
            ZStack {
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentYellow.opacity(0.15), Color.clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: 200)
                        .offset(y: -100)
                        .rotationEffect(.degrees(Double(i) * 45 + rayRotation))
                }
            }
            .opacity(rayOpacity)
            .animation(
                isVisible ? Animation.linear(duration: 8).repeatForever(autoreverses: false) : .default,
                value: rayRotation
            )

            // Particles (Layer 3)
            if particlesVisible {
                ZStack {
                    SplashParticle(color: .accentYellow, size: 6, offset: CGSize(width: -80, height: particle1Offset))
                    SplashParticle(color: .accentOrange, size: 4, offset: CGSize(width: 60, height: particle2Offset))
                    SplashParticle(color: .accentYellowLight, size: 5, offset: CGSize(width: -30, height: particle3Offset))
                    SplashParticle(color: .accentBlue, size: 3, offset: CGSize(width: 100, height: particle1Offset * 0.7))
                    SplashParticle(color: .accentOrangeSoft, size: 4, offset: CGSize(width: -110, height: particle2Offset * 0.8))
                    SplashParticle(color: .accentYellow, size: 3, offset: CGSize(width: 40, height: particle3Offset * 1.2))
                }
            }

            // Logo & Title (Layer 4)
            VStack(spacing: 20) {
                Spacer()
                // Logo icon
                ZStack {
                    Circle()
                        .fill(Color.accentYellow.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)

                    Circle()
                        .fill(Color.cardBg)
                        .frame(width: 90, height: 90)
                        .overlay(
                            Circle().stroke(Color.accentYellow.opacity(0.4), lineWidth: 1.5)
                        )

                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentYellow, Color.accentOrange],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // App name
                VStack(spacing: 6) {
                    Text("Light Nest")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentYellow, Color.accentOrangeLight],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )

                    Text("Smart lighting simulation")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.textSecondary)
                        .tracking(1.5)
                        .textCase(.uppercase)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)

                Spacer()

                // Bottom tag
                Text("Plan before you install")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.textInactive)
                    .opacity(subtitleOpacity)
                    .padding(.bottom, 60)
            }
        }
        .scaleEffect(exitScale)
        .opacity(exitOpacity)
        .onAppear {
            guard !isVisible else { return }
            isVisible = true
            startAnimations()
        }
        .onDisappear {
            isVisible = false
            stopAnimations()
        }
    }

    private func startAnimations() {
        // Phase 1: BG builds in (0-0.6s)
        withAnimation(.easeIn(duration: 0.6)) {
            bgPulse = true
        }

        // Phase 2: Rays animate (0.6-1.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeIn(duration: 0.5)) {
                rayOpacity = 1.0
            }
            withAnimation(Animation.linear(duration: 8).repeatForever(autoreverses: false)) {
                rayRotation = 360
            }
            particlesVisible = true
            withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                particle1Offset = -80
                particle2Offset = -100
                particle3Offset = -60
            }
        }

        // Phase 3: Logo appears (1.4-2.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            withAnimation(.easeIn(duration: 0.4)) {
                subtitleOpacity = 1.0
            }
        }

        // Phase 4: Exit (2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(.easeInOut(duration: 0.5)) {
                exitScale = 1.15
                exitOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onFinish()
            }
        }
    }

    private func stopAnimations() {
        bgPulse = false
        rayRotation = 0
        rayOpacity = 0
        particlesVisible = false
        particle1Offset = 0
        particle2Offset = 0
        particle3Offset = 0
        logoScale = 0.3
        logoOpacity = 0
        titleOffset = 30
        titleOpacity = 0
        subtitleOpacity = 0
    }
}

struct SplashParticle: View {
    let color: Color
    let size: CGFloat
    let offset: CGSize

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(offset)
            .blur(radius: size / 3)
    }
}
