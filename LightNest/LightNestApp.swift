import SwiftUI

@main
struct LightNestApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var projectVM = ProjectViewModel()
    @StateObject private var roomVM = RoomViewModel()
    @StateObject private var taskVM = TaskViewModel()
    @StateObject private var fixtureVM = FixtureViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(projectVM)
                .environmentObject(roomVM)
                .environmentObject(taskVM)
                .environmentObject(fixtureVM)
        }
    }

}

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true
    @State private var showOnboarding = false
    @State private var showMain = false
    
    @AppStorage("appTheme") private var appTheme = "dark"
    
    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            if showSplash {
                SplashView(onFinish: {
                    withAnimation(.easeInOut(duration: 1.5)) {
                        showSplash = false
                        if hasCompletedOnboarding {
                            showMain = true
                        } else {
                            showOnboarding = true
                        }
                    }
                })
                .transition(.opacity)
            } else if showOnboarding {
                OnboardingContainerView(onComplete: {
                    hasCompletedOnboarding = true
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showOnboarding = false
                        showMain = true
                    }
                })
                .transition(.opacity)
            } else if showMain {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(colorScheme)
    }
}
