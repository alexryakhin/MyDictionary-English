//
//  AlertModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import Shared

public struct AlertModel {
    public let title: String
    public let message: String?
    public let actionText: String?
    public let action: VoidHandler?

    public init(
        title: String,
        message: String? = nil,
        actionText: String? = nil,
        action: VoidHandler? = nil
    ) {
        self.title = title
        self.message = message
        self.action = action
        self.actionText = actionText
    }
}
