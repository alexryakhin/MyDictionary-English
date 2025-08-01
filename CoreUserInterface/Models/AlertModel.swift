//
//  AlertModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct AlertModel {
    let title: String
    let message: String?
    let actionText: String?
    let destructiveActionText: String?
    let action: VoidHandler?
    let destructiveAction: VoidHandler?

    init(
        title: String,
        message: String? = nil,
        actionText: String? = nil,
        destructiveActionText: String? = nil,
        action: VoidHandler? = nil,
        destructiveAction: VoidHandler? = nil
    ) {
        self.title = title
        self.message = message
        self.action = action
        self.destructiveAction = destructiveAction
        self.destructiveActionText = destructiveActionText
        self.actionText = actionText
    }
}
