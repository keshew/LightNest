import SwiftUI

@main
struct LightNestApp: App {
    @UIApplicationDelegateAdaptor(LightNestAppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var projectVM = ProjectViewModel()
    @StateObject private var roomVM = RoomViewModel()
    @StateObject private var taskVM = TaskViewModel()
    @StateObject private var fixtureVM = FixtureViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            SplashView()
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
            if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingContainerView(onComplete: {
                    hasCompletedOnboarding = true
                })
                .transition(.opacity)
            }
        }
        .preferredColorScheme(colorScheme)
    }
}
