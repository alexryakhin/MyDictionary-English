//
//  SectionHeaderButton.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/23/25.
//

import SwiftUI

public struct SectionHeaderButton: View {

    private let titleKey: LocalizedStringKey
    private let systemImage: String
    private let action: () -> Void

    public init(
        _ titleKey: LocalizedStringKey,
        systemImage: String = .empty,
        action: @escaping () -> Void
    ) {
        self.titleKey = titleKey
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button {
            action()
        } label: {
            Label(titleKey, systemImage: systemImage)
                .textCase(.uppercase)
                .font(.footnote)
        }
    }
}
