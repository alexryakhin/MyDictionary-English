//
//  CustomTextField.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/22/25.
//

import SwiftUI

struct CustomTextField: View {

    @FocusState private var isFocused: Bool

    private let placeholder: String
    private let text: Binding<String>
    private let submitLabel: SubmitLabel
    private let onCommit: () -> Void

    init(
        _ placeholder: String,
        text: Binding<String>,
        submitLabel: SubmitLabel = .done,
        onCommit: @escaping () -> Void = {}
    ) {
        self.placeholder = placeholder
        self.text = text
        self.submitLabel = submitLabel
        self.onCommit = onCommit
    }

    var body: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: text, axis: .vertical)
                .onSubmit(onCommit)
                .submitLabel(submitLabel)
                .focused($isFocused)
                .textFieldStyle(.plain)

            if isFocused && text.wrappedValue.isNotEmpty {
                Button {
                    text.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
        }
    }
}
