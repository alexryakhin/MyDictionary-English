import SwiftUI
import Swinject
import SwinjectAutoregistration
import Firebase

//@main
//struct MyDictionaryApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//
//    let resolver: Resolver
//
//    init() {
//        resolver = DIContainer.shared.resolver
//
//        DIContainer.shared.assemble(assembly: ServiceAssembly())
//        DIContainer.shared.assemble(assembly: UIAssembly())
//    }
//
//    var body: some Scene {
//        WindowGroup {
//            (resolver ~> MainTabView.self)
//                .font(.system(.body, design: .rounded))
//        }
//    }
//}
