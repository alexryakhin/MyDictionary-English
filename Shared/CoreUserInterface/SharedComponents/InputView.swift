//
//  InputView.swift
//  Flippin
//
//  Created by Alexander Riakhin on 7/27/25.
//

import SwiftUI

public struct InputView: View {

    let placeholder: String
    let submitLabel: SubmitLabel
    let leadingIcon: Image?
    let trailingButtonLabel: String?
    let onSubmit: VoidHandler?
    let onTrailingButtonTap: VoidHandler?
    @Binding public var text: String
    @FocusState private var isFocused

    @State private var showsTrailingButton: Bool = false

    init(
        _ placeholder: String,
        leadingIcon: Image? = nil,
        submitLabel: SubmitLabel = .done,
        text: Binding<String>,
        onSubmit: VoidHandler? = nil,
        trailingButtonLabel: String? = nil,
        onTrailingButtonTap: VoidHandler? = nil
    ) {
        self.placeholder = placeholder
        self.leadingIcon = leadingIcon
        self.trailingButtonLabel = trailingButtonLabel
        self.submitLabel = submitLabel
        self._text = text
        self.onSubmit = onSubmit
        self.onTrailingButtonTap = onTrailingButtonTap
    }

    static func searchView(_ placeholder: String, searchText: Binding<String>) -> InputView {
        InputView(
            placeholder,
            leadingIcon: Image(systemName: "magnifyingglass"),
            text: searchText,
            trailingButtonLabel: "Cancel"
        )
    }

    public var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                leadingIcon
                    .foregroundStyle(.tertiary)
                TextField(placeholder, text: $text)
                    .submitLabel(submitLabel)
                    .focused($isFocused)
                    .onSubmit {
                        endEditing()
                        onSubmit?()
                    }
                    .onChange(of: isFocused) { newValue in
                        withAnimation {
                            showsTrailingButton = newValue
                        }
                    }
                if isFocused, !text.isEmpty {
                    Button {
                        HapticManager.shared.triggerImpact(style: .light)
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.callout)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(vertical: 8, horizontal: 12)
            .background(Color.tertiarySystemFill)
            .clipShape(Capsule())

            if showsTrailingButton, let trailingButtonLabel {
                HeaderButton(trailingButtonLabel) {
                    HapticManager.shared.triggerImpact(style: .light)
                    endEditing()
                    onTrailingButtonTap?()
                }
                .transition(.move(edge: .trailing))
                .opacity(isFocused ? 1 : 0)
            }
        }
        .animation(.easeInOut, value: isFocused)
    }
}
