import Foundation

extension String {
    /// Returns a localized string using the key from Loc enum
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Returns a localized string using the key from Loc enum with format arguments
    func localized(_ arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}
