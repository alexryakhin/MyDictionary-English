//
//  AlertModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct AlertModel: Equatable {
    static func == (lhs: AlertModel, rhs: AlertModel) -> Bool {
        lhs.title == rhs.title
        && lhs.message == rhs.message
        && lhs.actionText == rhs.actionText
        && lhs.additionalActionText == rhs.additionalActionText
        && lhs.isDestructive == rhs.isDestructive
    }
    
    let title: String
    let message: String?
    let actionText: String?
    let additionalActionText: String?
    let isDestructive: Bool
    let action: VoidHandler?
    let additionalAction: VoidHandler?

    init(
        title: String,
        message: String? = nil,
        actionText: String? = nil,
        additionalActionText: String? = nil,
        isDestructive: Bool = false,
        action: VoidHandler? = nil,
        additionalAction: VoidHandler? = nil
    ) {
        self.title = title
        self.message = message
        self.actionText = actionText
        self.additionalActionText = additionalActionText
        self.isDestructive = isDestructive
        self.action = action
        self.additionalAction = additionalAction
    }

    // MARK: - Convenience Initializers

    /// Simple info alert
    static func info(
        title: String,
        message: String? = nil,
        actionText: String = "OK",
        action: @escaping VoidHandler = {}
    ) -> AlertModel {
        return AlertModel(
            title: title,
            message: message,
            actionText: actionText,
            action: action
        )
    }

    /// Confirmation alert with cancel and confirm
    static func confirmation(
        title: String,
        message: String? = nil,
        cancelText: String = "Cancel",
        confirmText: String = "Confirm",
        onCancel: @escaping VoidHandler = {},
        onConfirm: @escaping VoidHandler = {}
    ) -> AlertModel {
        return AlertModel(
            title: title,
            message: message,
            actionText: cancelText,
            additionalActionText: confirmText,
            action: onCancel,
            additionalAction: onConfirm
        )
    }

    /// Delete confirmation alert
    static func deleteConfirmation(
        title: String = "Delete",
        message: String? = nil,
        cancelText: String = "Cancel",
        deleteText: String = "Delete",
        onCancel: @escaping VoidHandler = {},
        onDelete: @escaping VoidHandler = {}
    ) -> AlertModel {
        return AlertModel(
            title: title,
            message: message,
            actionText: cancelText,
            additionalActionText: deleteText,
            isDestructive: true,
            action: onCancel,
            additionalAction: onDelete
        )
    }
}
