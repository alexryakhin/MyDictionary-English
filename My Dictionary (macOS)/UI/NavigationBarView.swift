//
//  NavigationTitleModifier.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/15/25.
//

import SwiftUI

enum NavigationTitleMode {
    case inline
    case regular

    var font: Font {
        switch self {
        case .inline:
            return .headline
        case .regular:
            return .title
        }
    }
}

struct NavigationBarView<TrailingContent: View, BottomContent: View>: View {

    @Environment(\.dismiss) var dismiss

    let title: String
    let mode: NavigationTitleMode
    let vPadding: CGFloat
    let hPadding: CGFloat
    let showsDismissButton: Bool

    @ViewBuilder let trailingContent: () -> TrailingContent
    @ViewBuilder let bottomContent: () -> BottomContent

    init(
        title: String,
        mode: NavigationTitleMode = .inline,
        vPadding: CGFloat = 8,
        hPadding: CGFloat = 12,
        showsDismissButton: Bool = true,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent = { EmptyView() },
        @ViewBuilder bottomContent: @escaping () -> BottomContent = { EmptyView() }
    ) {
        self.title = title
        self.mode = mode
        self.vPadding = vPadding
        self.hPadding = hPadding
        self.showsDismissButton = showsDismissButton
        self.trailingContent = trailingContent
        self.bottomContent = bottomContent
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 2) {
                Text(title)
                    .font(mode.font)
                    .bold()
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 6) {
                    trailingContent()
                        .fixedSize()
                        .lineLimit(1)
                    if showsDismissButton {
                        HeaderButton(
                            Loc.Navigation.close,
                            style: .bordered
                        ) {
                            dismiss()
                        }
                        .help(Loc.Navigation.closeScreen)
                    }
                }
            }

            bottomContent()
        }
        .padding(vertical: vPadding, horizontal: hPadding)
    }
}
