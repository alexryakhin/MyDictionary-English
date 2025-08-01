//
//  ScrollView+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//
import SwiftUI

extension ScrollView {
    @ViewBuilder
    func scrollTargetBehaviorIfAvailable() -> some View {
        if #available(macOS 14, *) {
            self.scrollTargetBehavior(.viewAligned)
        } else {
            self
        }
    }
}

extension List {
    @ViewBuilder
    func scrollContentBackgroundIfAvailable(_ visibility: Visibility) -> some View {
        if #available(iOS 16, *) {
            self.scrollContentBackground(visibility)
        } else {
            self
        }
    }
}

extension View {
    @ViewBuilder
    func scrollTargetLayoutIfAvailable() -> some View {
        if #available(macOS 14, *) {
            self.scrollTargetLayout()
        } else {
            self
        }
    }

    @ViewBuilder
    func scrollClipDisabledIfAvailable(_ disabled: Bool = true) -> some View {
        if #available(macOS 14, *) {
            self.scrollClipDisabled(disabled)
        } else {
            self
        }
    }
}
