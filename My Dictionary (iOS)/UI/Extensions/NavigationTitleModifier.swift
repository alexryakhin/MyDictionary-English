//
//  NavigationTitleModifier.swift
//  Flippin
//
//  Created by Alexander Riakhin on 6/30/25.
//

import SwiftUI

enum NavigationTitleMode {
    case inline
    case large
}

struct NavigationTitleModifier<TrailingContent: View, BottomContent: View>: ViewModifier {

    @Environment(\.dismiss) var dismiss

    let title: String
    let mode: NavigationTitleMode
    let vPadding: CGFloat
    let hPadding: CGFloat
    let showsBackButton: Bool

    @ViewBuilder let trailingContent: () -> TrailingContent
    @ViewBuilder let bottomContent: () -> BottomContent

    func body(content: Content) -> some View {
        content
            .safeAreaBarIfAvailable(edge: .top) {
                VStack(spacing: mode == .large ? 12 : 8) {
                    HStack(spacing: 2) {
                        if showsBackButton {
                            HeaderButton(
                                icon: "chevron.left",
                                style: .bordered
                            ) {
                                dismiss()
                            }
                            .padding(.trailing, 6)
                        }
                        Text(title)
                            .font(mode == .inline ? .headline : .largeTitle)
                            .bold()
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Spacer()

                        HStack(spacing: 6) {
                            trailingContent()
                                .fixedSize()
                                .lineLimit(1)
                        }
                    }

                    bottomContent()
                }
                .clippedWithPaddingAndBackgroundMaterial(cornerRadius: 32)
                .shadow(color: .label.opacity(0.3), radius: 5)
                .padding(vertical: vPadding, horizontal: hPadding)
            }
            .toolbar(.hidden)
    }
}

extension View {
    func navigation<TrailingContent: View, BottomContent: View>(
        title: String,
        mode: NavigationTitleMode = .large,
        vPadding: CGFloat = 8,
        hPadding: CGFloat = 8,
        showsBackButton: Bool = false,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent = { EmptyView() },
        @ViewBuilder bottomContent: @escaping () -> BottomContent = { EmptyView() }
    ) -> some View {
        modifier(
            NavigationTitleModifier(
                title: title,
                mode: mode,
                vPadding: vPadding,
                hPadding: hPadding,
                showsBackButton: showsBackButton,
                trailingContent: trailingContent,
                bottomContent: bottomContent
            )
        )
    }
}
