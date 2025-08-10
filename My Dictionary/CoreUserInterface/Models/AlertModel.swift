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
        && lhs.alertType == rhs.alertType
    }
    
    let title: String
    let message: String?
    let actionText: String?
    let destructiveActionText: String?
    let additionalActionText: String?
    let action: VoidHandler?
    let destructiveAction: VoidHandler?
    let additionalAction: VoidHandler?
    let alertType: AlertType
    let style: UIAlertController.Style

    enum AlertType {
        case info
        case warning
        case error
        case confirmation
        case choice
    }

    init(
        title: String,
        message: String? = nil,
        actionText: String? = nil,
        destructiveActionText: String? = nil,
        additionalActionText: String? = nil,
        action: VoidHandler? = nil,
        destructiveAction: VoidHandler? = nil,
        additionalAction: VoidHandler? = nil,
        alertType: AlertType = .info,
        style: UIAlertController.Style = .alert
    ) {
        self.title = title
        self.message = message
        self.actionText = actionText
        self.destructiveActionText = destructiveActionText
        self.additionalActionText = additionalActionText
        self.action = action
        self.destructiveAction = destructiveAction
        self.additionalAction = additionalAction
        self.alertType = alertType
        self.style = style
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
            action: action,
            alertType: .info
        )
    }

    /// Warning alert
    static func warning(
        title: String,
        message: String? = nil,
        actionText: String = "OK",
        action: @escaping VoidHandler = {}
    ) -> AlertModel {
        return AlertModel(
            title: title,
            message: message,
            actionText: actionText,
            action: action,
            alertType: .warning
        )
    }

    /// Error alert
    static func error(
        title: String,
        message: String? = nil,
        actionText: String = "OK",
        action: @escaping VoidHandler = {}
    ) -> AlertModel {
        return AlertModel(
            title: title,
            message: message,
            actionText: actionText,
            action: action,
            alertType: .error
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
            destructiveActionText: confirmText,
            action: onCancel,
            destructiveAction: onConfirm,
            alertType: .confirmation
        )
    }

    /// Choice alert with three options
    static func choice(
        title: String,
        message: String? = nil,
        cancelText: String = "Cancel",
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
            additionalAction: onSecondary,
            alertType: .choice
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
            destructiveActionText: deleteText,
            action: onCancel,
            destructiveAction: onDelete,
            alertType: .confirmation
        )
    }

    // MARK: - Computed Properties

    /// Returns the appropriate icon for the alert type
    var icon: String {
        switch alertType {
        case .info:
            return "info.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .error:
            return "xmark.circle"
        case .confirmation:
            return "questionmark.circle"
        case .choice:
            return "list.bullet"
        }
    }

    /// Returns the appropriate color for the alert type
    var iconColor: Color {
        switch alertType {
        case .info:
            return .accent
        case .warning:
            return .orange
        case .error:
            return .red
        case .confirmation:
            return .accent
        case .choice:
            return .accent
        }
    }

    /// Returns the appropriate background color for the alert type
    var backgroundColor: Color {
        switch alertType {
        case .info:
            return Color(.systemBlue).opacity(0.2)
        case .warning:
            return Color(.systemOrange).opacity(0.2)
        case .error:
            return Color(.systemRed).opacity(0.2)
        case .confirmation:
            return Color(.systemBlue).opacity(0.2)
        case .choice:
            return Color(.systemBlue).opacity(0.2)
        }
    }
}
