import SwiftUI

@main
struct todayApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .preferredColorScheme(settings.preferredColorScheme)
                .task {
                    await NotificationService.shared.checkAuthorization()
                    // Only disable if the system revoked permission.
                    // Don't auto-enable, the user may have turned it off in the app.
                    if !NotificationService.shared.isAuthorized {
                        settings.notificationsEnabled = false
                    }
                }
        }
    }
}
