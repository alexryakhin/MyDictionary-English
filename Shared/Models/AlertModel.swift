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
        && lhs.destructiveActionText == rhs.destructiveActionText
        && lhs.additionalActionText == rhs.additionalActionText
    }
    
    let title: String
    let message: String?
    let actionText: String?
    let destructiveActionText: String?
    let additionalActionText: String?
    let action: VoidHandler?
    let destructiveAction: VoidHandler?
    let additionalAction: VoidHandler?

    init(
        title: String,
        message: String? = nil,
        actionText: String? = nil,
        destructiveActionText: String? = nil,
        additionalActionText: String? = nil,
        action: VoidHandler? = nil,
        destructiveAction: VoidHandler? = nil,
        additionalAction: VoidHandler? = nil,
    ) {
        self.title = title
        self.message = message
        self.actionText = actionText
        self.destructiveActionText = destructiveActionText
        self.additionalActionText = additionalActionText
        self.action = action
        self.destructiveAction = destructiveAction
        self.additionalAction = additionalAction
    }
    
    // MARK: - Convenience Initializers

    /// Simple info alert
    static func info(
        title: String,
        message: String? = nil,
        actionText: String = Loc.Actions.ok,
        action: @escaping VoidHandler = {}
    ) -> AlertModel {
        return AlertModel(
            title: title,
            message: message,
            actionText: actionText,
            action: action
        )
    }

    /// Warning alert
    static func warning(
        title: String,
        message: String? = nil,
        actionText: String = Loc.Actions.ok,
        action: @escaping VoidHandler = {}
    ) -> AlertModel {
        return AlertModel(
            title: title,
            message: message,
            actionText: actionText,
            action: action
        )
    }

    /// Error alert
    static func error(
        title: String = Loc.Errors.oops,
        message: String,
        actionText: String = Loc.Actions.ok,
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
        cancelText: String = Loc.Actions.cancel,
        confirmText: String = Loc.Actions.confirm,
        onCancel: @escaping VoidHandler = {},
        onConfirm: @escaping VoidHandler = {}
    ) -> AlertModel {
        return AlertModel(
            title: title,
            message: message,
            actionText: cancelText,
            destructiveActionText: confirmText,
            action: onCancel,
            destructiveAction: onConfirm
        )
    }

    /// Choice alert with three options
    static func choice(
        title: String,
        message: String? = nil,
        cancelText: String = Loc.Actions.cancel,
        primaryText: String,
        secondaryText: String,
        onCancel: @escaping VoidHandler = {},
        onPrimary: VoidHandler? = nil,
        onSecondary: VoidHandler? = nil
    ) -> AlertModel {
        return AlertModel(
            title: title,
            message: message,
            actionText: cancelText,
            destructiveActionText: primaryText,
            additionalActionText: secondaryText,
            action: onCancel,
            destructiveAction: onPrimary,
            additionalAction: onSecondary
        )
    }

    /// Delete confirmation alert
    static func deleteConfirmation(
        title: String = Loc.Actions.delete,
        message: String? = nil,
        cancelText: String = Loc.Actions.cancel,
        deleteText: String = Loc.Actions.delete,
        onCancel: @escaping VoidHandler = {},
        onDelete: @escaping VoidHandler = {}
    ) -> AlertModel {
        return AlertModel(
            title: title,
            message: message,
            actionText: cancelText,
            destructiveActionText: deleteText,
            action: onCancel,
            destructiveAction: onDelete
        )
    }
}
