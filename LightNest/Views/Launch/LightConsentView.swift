import SwiftUI

struct LightConsentView: View {
    @ObservedObject var viewModel: Bedside

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height

            ZStack {
                LightScreenImage(portrait: "ntprt", landscape: "ntland")

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: isLandscape ? 7 : 11) {
                        Text("ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS")
                            .font(.system(size: titleSize(isLandscape: isLandscape, width: proxy.size.width), weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.60), radius: 3, x: 0, y: 2)
                            .lineLimit(2)
                            .minimumScaleFactor(0.68)

                        Text("Stay tuned with best offers from our casino")
                            .font(.system(size: subtitleSize(isLandscape: isLandscape, width: proxy.size.width), weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.88))
                            .shadow(color: .black.opacity(0.55), radius: 2, x: 0, y: 2)
                            .lineLimit(2)
                            .minimumScaleFactor(0.68)
                            .padding(.bottom, isLandscape ? 7 : 10)

                        Button(action: viewModel.acceptConsent) {
                            Text("Yes, I Want Bonuses!")
                                .font(.system(size: buttonTextSize(isLandscape: isLandscape, width: proxy.size.width), weight: .black, design: .rounded))
                                .foregroundColor(Color(red: 0.12, green: 0.07, blue: 0.05))
                                .frame(maxWidth: .infinity)
                                .frame(height: isLandscape ? 25 : 34)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.78, blue: 0.14),
                                            Color(red: 1.0, green: 0.45, blue: 0.02)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: isLandscape ? 6 : 8)
                                        .stroke(Color(red: 1.0, green: 0.74, blue: 0.05), lineWidth: isLandscape ? 3 : 4)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: isLandscape ? 6 : 8))
                                .shadow(color: .black.opacity(0.48), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .frame(width: buttonWidth(isLandscape: isLandscape, width: proxy.size.width))

                        Button(action: viewModel.skipConsent) {
                            Text("Skip")
                                .font(.system(size: skipSize(isLandscape: isLandscape, width: proxy.size.width), weight: .black, design: .rounded))
                                .foregroundColor(.white.opacity(0.88))
                                .shadow(color: .black.opacity(0.58), radius: 2, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, isLandscape ? 2 : 5)
                    }
                    .frame(width: contentWidth(isLandscape: isLandscape, width: proxy.size.width))
                    .padding(.bottom, bottomInset(isLandscape: isLandscape, proxy: proxy))
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private func contentWidth(isLandscape: Bool, width: CGFloat) -> CGFloat {
        isLandscape ? min(width * 0.54, 700) : min(width * 0.78, 360)
    }

    private func buttonWidth(isLandscape: Bool, width: CGFloat) -> CGFloat {
        isLandscape ? min(width * 0.28, 360) : min(width * 0.56, 270)
    }

    private func bottomInset(isLandscape: Bool, proxy: GeometryProxy) -> CGFloat {
        let safeBottom = proxy.safeAreaInsets.bottom
        return safeBottom + proxy.size.height * (isLandscape ? 0.115 : 0.105)
    }

    private func titleSize(isLandscape: Bool, width: CGFloat) -> CGFloat {
        isLandscape ? max(11, min(width * 0.018, 24)) : max(15, min(width * 0.039, 22))
    }

    private func subtitleSize(isLandscape: Bool, width: CGFloat) -> CGFloat {
        isLandscape ? max(8, min(width * 0.011, 15)) : max(10, min(width * 0.027, 15))
    }

    private func buttonTextSize(isLandscape: Bool, width: CGFloat) -> CGFloat {
        isLandscape ? max(8, min(width * 0.011, 14)) : max(10, min(width * 0.027, 14))
    }

    private func skipSize(isLandscape: Bool, width: CGFloat) -> CGFloat {
        isLandscape ? max(8, min(width * 0.010, 13)) : max(10, min(width * 0.026, 14))
    }
}

#Preview("Notifications") {
    LightConsentView(viewModel: Bedside())
}
