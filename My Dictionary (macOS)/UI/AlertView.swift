//
//  AlertView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/16/25.
//

import SwiftUI

struct AlertView: View {

    let model: AlertModel
    let dismiss: VoidHandler

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 16) {
                Text(model.title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .padding(.top, 16)

                if let message = model.message {
                    Text(message)
                        .font(.system(.headline, design: .rounded, weight: .medium))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .frame(height: 56, alignment: .top)
                }
            }

            if let actionText = model.actionText {
                ActionButton(actionText) {
                    model.action?()
                    dismiss()
                }
            }
            if let additionalActionText = model.additionalActionText {
                ActionButton(additionalActionText) {
                    model.additionalAction?()
                    dismiss()
                }
            }
            if let destructiveActionText = model.destructiveActionText {
                ActionButton(destructiveActionText, color: .red) {
                    model.destructiveAction?()
                    dismiss()
                }
            }
            if model.actionText == nil
                && model.additionalActionText == nil
                && model.destructiveActionText == nil {
                ActionButton("OK") {
                    dismiss()
                }
            }
        }
        .padding(12)
        .frame(idealWidth: 250, maxHeight: 350)
    }
}
