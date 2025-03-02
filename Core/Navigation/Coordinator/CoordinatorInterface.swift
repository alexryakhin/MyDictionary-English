import UIKit

/// Coordinator managing user history
protocol CoordinatorInterface: AnyObject {

    func start()
    func open(url: String?)
    func open(url: URL)
}

extension CoordinatorInterface {
    
    func open(url: String?) {
        guard
            let urlStr = url,
            let url = URL(string: urlStr) else {
            assertionFailure("Invalid url string")
            return
        }
        open(url: url)
    }

    func open(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

protocol RoutableCoordinator: CoordinatorInterface {
    var router: RouterInterface { get }
}
