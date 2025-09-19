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
    let showInputLanguagePicker: Bool
    let leadingIcon: Image?
    let trailingButtonLabel: String?
    let onSubmit: VoidHandler?
    let onTrailingButtonTap: VoidHandler?
    @Binding public var text: String
    @Binding public var inputLanguage: InputLanguage
    @FocusState private var isFocused

    @State private var showsTrailingButton: Bool = false

    init(
        _ placeholder: String,
        leadingIcon: Image? = nil,
        submitLabel: SubmitLabel = .done,
        showInputLanguagePicker: Bool = false,
        text: Binding<String>,
        inputLanguage: Binding<InputLanguage> = .constant(.english),
        onSubmit: VoidHandler? = nil,
        trailingButtonLabel: String? = nil,
        onTrailingButtonTap: VoidHandler? = nil
    ) {
        self.placeholder = placeholder
        self.leadingIcon = leadingIcon
        self.trailingButtonLabel = trailingButtonLabel
        self.submitLabel = submitLabel
        self._text = text
        self._inputLanguage = inputLanguage
        self.onSubmit = onSubmit
        self.onTrailingButtonTap = onTrailingButtonTap
        self.showInputLanguagePicker = showInputLanguagePicker
    }

    static func searchView(_ placeholder: String, searchText: Binding<String>) -> InputView {
        InputView(
            placeholder,
            leadingIcon: Image(systemName: "magnifyingglass"),
            text: searchText,
            trailingButtonLabel: Loc.Actions.cancel
        )
    }

    public var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                leadingIcon
                    .foregroundStyle(.tertiary)
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
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
                    .buttonStyle(.plain)
                }
                if text.isEmpty && showInputLanguagePicker {
                    Menu {
                        ForEach(InputLanguage.allCasesSorted, id: \.self) { lang in
                            Button {
                                inputLanguage = lang
                            } label: {
                                Text(lang.displayName)
                            }
                        }
                    } label: {
                        TagView(text: inputLanguage.rawValue.uppercased(), color: .blue, size: .mini)
                    }
                }
            }
            .padding(vertical: 8, horizontal: 12)
            .background(Color.tertiarySystemFill)
            .clipShape(Capsule())

            if showsTrailingButton, let trailingButtonLabel {
                HeaderButton(trailingButtonLabel) {
                    HapticManager.shared.triggerImpact(style: .light)
                    text = ""
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
