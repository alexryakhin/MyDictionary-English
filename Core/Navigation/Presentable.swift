import UIKit

/// Indicates the ability of the entity to participate in navigation
protocol Presentable: AnyObject {
    
    func toPresent() -> UIViewController?
}

extension UIViewController: Presentable {
    
    func toPresent() -> UIViewController? {
        return self
    }
}
