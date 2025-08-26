//
//  EditExampleAlert.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/16/25.
//

import SwiftUI

struct EditExampleAlert: View {

    @Binding var exampleText: String
    var onCancel: VoidHandler
    var onSave: VoidHandler

    var body: some View {
        VStack(spacing: 12) {
            Text(Loc.Words.editExample)
                .font(.title2)
                .bold()
                .padding()

            TextField(Loc.Words.example, text: $exampleText, axis: .vertical)
                .textFieldStyle(.plain)
                .clippedWithPaddingAndBackground(cornerRadius: 12)

            ActionButton(Loc.Actions.save, style: .borderedProminent, action: onSave)
            ActionButton(Loc.Actions.cancel, action: onCancel)
        }
        .padding(12)
        .groupedBackground()
        .frame(maxWidth: 300)
    }
}
