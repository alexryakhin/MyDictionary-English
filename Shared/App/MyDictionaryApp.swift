import SwiftUI
import Swinject
import SwinjectAutoregistration
import Firebase

@main
struct MyDictionaryApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    let resolver: Resolver

    init() {
        resolver = DIContainer.shared.resolver

        DIContainer.shared.assemble(assembly: ServiceAssembly())
        DIContainer.shared.assemble(assembly: UIAssembly())
    }

    var body: some Scene {
        WindowGroup {
            (resolver ~> MainTabView.self)
                .font(.system(.body, design: .rounded))
        }
        #if os(macOS)
        .windowStyle(TitleBarWindowStyle())
        .windowToolbarStyle(.unifiedCompact)
        #endif

        #if os(macOS)
        Settings {
            resolver ~> DictionarySettings.self
        }
        #endif
    }
}
