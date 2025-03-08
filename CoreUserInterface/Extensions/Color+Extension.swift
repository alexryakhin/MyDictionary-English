//
//  Color+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

public extension UIColor {
    var swiftUIColor: Color {
        Color(uiColor: self)
    }
}

public extension Color {
    static var systemBackground: Self {
        UIColor.systemBackground.swiftUIColor
    }
    static var secondarySystemBackground: Self {
        UIColor.secondarySystemBackground.swiftUIColor
    }
    static var tertiarySystemBackground: Self {
        UIColor.tertiarySystemBackground.swiftUIColor
    }
    static var lightText: Self {
        UIColor.lightText.swiftUIColor
    }
    static var darkText: Self {
        UIColor.darkText.swiftUIColor
    }
    static var lightGray: Self {
        UIColor.lightGray.swiftUIColor
    }
    static var darkGray: Self {
        UIColor.darkGray.swiftUIColor
    }
    static var systemFill: Self {
        UIColor.systemFill.swiftUIColor
    }
    static var secondarySystemFill: Self {
        UIColor.secondarySystemFill.swiftUIColor
    }
    static var tertiarySystemFill: Self {
        UIColor.tertiarySystemFill.swiftUIColor
    }
    static var quaternarySystemFill: Self {
        UIColor.quaternarySystemFill.swiftUIColor
    }
    static var label: Self {
        UIColor.label.swiftUIColor
    }
    static var secondaryLabel: Self {
        UIColor.secondaryLabel.swiftUIColor
    }
    static var tertiaryLabel: Self {
        UIColor.tertiaryLabel.swiftUIColor
    }
    static var quaternaryLabel: Self {
        UIColor.quaternaryLabel.swiftUIColor
    }
}
