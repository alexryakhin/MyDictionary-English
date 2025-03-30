//
//  Color+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

public extension NSColor {
    var swiftUIColor: Color {
        Color(nsColor: self)
    }
}

public extension Color {
    static var lightGray: Self {
        NSColor.lightGray.swiftUIColor
    }
    static var darkGray: Self {
        NSColor.darkGray.swiftUIColor
    }
    static var labelColor: Self {
        NSColor.labelColor.swiftUIColor
    }
    static var secondaryLabelColor: Self {
        NSColor.secondaryLabelColor.swiftUIColor
    }
    static var tertiaryLabelColor: Self {
        NSColor.tertiaryLabelColor.swiftUIColor
    }
    static var quaternaryLabelColor: Self {
        NSColor.quaternaryLabelColor.swiftUIColor
    }
    static var quinaryLabel: Self {
        NSColor.quinaryLabel.swiftUIColor
    }
    static var linkColor: Self {
        NSColor.linkColor.swiftUIColor
    }
    static var placeholderTextColor: Self {
        NSColor.placeholderTextColor.swiftUIColor
    }
    static var windowFrameTextColor: Self {
        NSColor.windowFrameTextColor.swiftUIColor
    }
    static var selectedMenuItemTextColor: Self {
        NSColor.selectedMenuItemTextColor.swiftUIColor
    }
    static var alternateSelectedControlTextColor: Self {
        NSColor.alternateSelectedControlTextColor.swiftUIColor
    }
    static var headerTextColor: Self {
        NSColor.headerTextColor.swiftUIColor
    }
    static var separatorColor: Self {
        NSColor.separatorColor.swiftUIColor
    }
    static var gridColor: Self {
        NSColor.gridColor.swiftUIColor
    }
    static var windowBackgroundColor: Self {
        NSColor.windowBackgroundColor.swiftUIColor
    }
    static var underPageBackgroundColor: Self {
        NSColor.underPageBackgroundColor.swiftUIColor
    }
    static var controlBackgroundColor: Self {
        NSColor.controlBackgroundColor.swiftUIColor
    }
    static var selectedContentBackgroundColor: Self {
        NSColor.selectedContentBackgroundColor.swiftUIColor
    }
    static var unemphasizedSelectedContentBackgroundColor: Self {
        NSColor.unemphasizedSelectedContentBackgroundColor.swiftUIColor
    }
    static var findHighlightColor: Self {
        NSColor.findHighlightColor.swiftUIColor
    }
    static var textColor: Self {
        NSColor.textColor.swiftUIColor
    }
    static var textBackgroundColor: Self {
        NSColor.textBackgroundColor.swiftUIColor
    }
    @available(macOS 14.0, *)
    static var textInsertionPointColor: Self {
        NSColor.textInsertionPointColor.swiftUIColor
    }
    static var selectedTextColor: Self {
        NSColor.selectedTextColor.swiftUIColor
    }
    static var unemphasizedSelectedTextBackgroundColor: Self {
        NSColor.unemphasizedSelectedTextBackgroundColor.swiftUIColor
    }
    static var unemphasizedSelectedTextColor: Self {
        NSColor.unemphasizedSelectedTextColor.swiftUIColor
    }
    static var controlColor: Self {
        NSColor.controlColor.swiftUIColor
    }
    static var controlTextColor: Self {
        NSColor.controlTextColor.swiftUIColor
    }
    static var selectedControlColor: Self {
        NSColor.selectedControlColor.swiftUIColor
    }
    static var selectedControlTextColor: Self {
        NSColor.selectedControlTextColor.swiftUIColor
    }
    static var disabledControlTextColor: Self {
        NSColor.disabledControlTextColor.swiftUIColor
    }
    static var keyboardFocusIndicatorColor: Self {
        NSColor.keyboardFocusIndicatorColor.swiftUIColor
    }
    static var scrubberTexturedBackground: Self {
        NSColor.scrubberTexturedBackground.swiftUIColor
    }

    // Assets

    static var backgroundColor: Self {
        Color("BackgroundColor")
    }
    static var surfaceColor: Self {
        Color("SurfaceColor")
    }
    static var textFieldColor: Self {
        Color("TextFieldColor")
    }
}
