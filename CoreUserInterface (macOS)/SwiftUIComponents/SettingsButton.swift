//
//  SettingsButton.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 4/1/25.
//

import SwiftUI
import AppKit

public struct SettingsButton<Label: View>: View {

    private let label: () -> Label

    public init(@ViewBuilder label: @escaping () -> Label) {
        self.label = label
    }

    public var body: some View {
        if #available(macOS 14.0, *) {
            SettingsLink(label: label)
        } else {
            Button(
                action: {
                    if #available(macOS 13.0, *) {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    }
                    else {
                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                    }
                },
                label: label
            )
        }
    }
}
