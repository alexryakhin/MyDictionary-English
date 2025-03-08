//
//  SnackModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUISnackbar
import SwiftUI
import Shared

public struct SnackModel {
    public let title: String
    public let text: String?
    public let style: SnackbarStyle
    public let actionText: String?
    public let dismissOnTap: Bool
    public let dismissAfter: Double?
    public let extraBottomPadding: CGFloat
    public let action: VoidHandler?

    public init(
        title: String,
        text: String? = nil,
        style: SnackbarStyle = .default,
        actionText: String? = nil,
        dismissOnTap: Bool = true,
        dismissAfter: Double? = 4,
        extraBottomPadding: CGFloat = 0,
        action: VoidHandler? = nil
    ) {
        self.title = title
        self.text = text
        self.style = style
        self.actionText = actionText
        self.dismissOnTap = dismissOnTap
        self.dismissAfter = dismissAfter
        self.extraBottomPadding = extraBottomPadding
        self.action = action
    }
}
