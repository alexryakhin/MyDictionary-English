//
//  UIScreen+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//
import UIKit

extension UIApplication {

    class var currentWindow: UIWindow? {
        return UIApplication
            .shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .last
    }

    var userInterfaceStyle: UIUserInterfaceStyle? {
        Self.currentWindow?.traitCollection.userInterfaceStyle
    }
}

extension UIWindow {

    static let safeAreaInsets: UIEdgeInsets = UIApplication.currentWindow?.safeAreaInsets ?? .zero
    static let safeAreaBottomInset: CGFloat = safeAreaInsets.bottom
    static let safeAreaTopInset: CGFloat = safeAreaInsets.top
}

extension UIScreen {

    static var size: CGSize {
        return UIScreen.main.bounds.size
    }

    static var width: CGFloat {
        return size.width
    }

    static var height: CGFloat {
        return size.height
    }
}

