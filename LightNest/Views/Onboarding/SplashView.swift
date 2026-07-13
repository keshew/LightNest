import SwiftUI
import Combine
import Network

struct SplashView: View {

    @StateObject private var viewModel = Bedside()
    @State private var networkMonitor = NWPathMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    @State private var isVisible = true

    var body: some View {
        LightLoadingView()
            .preferredColorScheme(.dark)
            .fullScreenCover(isPresented: $viewModel.showPermissionPrompt) {
                LightConsentView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $viewModel.showOfflineView) {
                LightOfflineView()
            }
            .fullScreenCover(isPresented: $viewModel.navigateToScope) {
                ScopeView()
            }
            .fullScreenCover(isPresented: $viewModel.navigateToMain) {
                RootView()
            }
            .onAppear {
                NotificationCenter.default.publisher(for: .pulseArrived)
                    .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
                    .sink { data in
                        viewModel.ingestPulse(data)
                    }
                    .store(in: &cancellables)

                NotificationCenter.default.publisher(for: .tracesArrived)
                    .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
                    .sink { data in
                        viewModel.ingestTraces(data)
                    }
                    .store(in: &cancellables)

                setupNetworkMonitoring()
                viewModel.ignite()
            }
            .onDisappear {
                isVisible = false
                networkMonitor.cancel()
            }
    }

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                viewModel.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
}

private struct LightLoadingView: View {
    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            ZStack {
                Image("bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                Image("ldtx")
                    .resizable()
                    .scaledToFit()
                    .frame(width: isLandscape ? proxy.size.width * 0.36 : proxy.size.width * 0.74)
                    .position(
                        x: proxy.size.width * 0.50,
                        y: proxy.size.height * (isLandscape ? 0.55 : 0.52)
                    )

                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(isLandscape ? 0.85 : 0.95)
                        .padding(.bottom, proxy.safeAreaInsets.bottom + proxy.size.height * (isLandscape ? 0.09 : 0.07))
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("Loading") {
    SplashView()
}
