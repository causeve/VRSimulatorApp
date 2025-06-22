import SwiftUI

@main
struct VRSimulatorApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authService = AuthenticationService()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
                   if authService.isAuthenticated {
                       ControlPanelView()
                           .environmentObject(authService)
                           .onAppear {
                               // Force landscape mode for iPad
                              // AppDelegate.orientationLock = .landscape
                           }
                   } else {
                       LoginView()
                           .environmentObject(authService)
                           .onAppear {
                               // Allow any orientation for login screen
                               AppDelegate.orientationLock = .all
                           }
                   }
               }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    // Static property to manage orientation lock
        static var orientationLock = UIInterfaceOrientationMask.all

        func application(
            _ application: UIApplication,
            supportedInterfaceOrientationsFor window: UIWindow?
        ) -> UIInterfaceOrientationMask {
            return AppDelegate.orientationLock
        }
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("Your code here")
        return true
    }
}
