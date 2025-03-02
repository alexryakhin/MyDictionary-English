//
//  DefaultErrorProps.swift
//  Suint One
//
//  Created by Aleksandr Riakhin on 9/30/24.
//

import Foundation
import SwiftUI

struct DefaultErrorProps: Hashable {

    struct ActionControlProps {

        let title: String
        let action: VoidHandler

        init(title: String, action: @escaping VoidHandler) {
            self.title = title
            self.action = action
        }
    }

    let title: String
    let message: String
    let image: Image?
    let actionProps: ActionControlProps?

    init(
        title: String,
        message: String,
        image: Image?,
        actionProps: ActionControlProps? = nil
    ) {
        self.title = title
        self.message = message
        self.image = image
        self.actionProps = actionProps
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(message)
        if let actionProps {
            hasher.combine(actionProps.title)
        }
    }

    static func == (lhs: DefaultErrorProps, rhs: DefaultErrorProps) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension DefaultErrorProps {

    static func common(message: String?, action: @escaping VoidHandler) -> Self {
        DefaultErrorProps(
            title: "Ooops... Something went wrong",
            message: message ?? "Please try again later",
            image: Image(systemName: "exclamationmark.circle.fill"),
            actionProps: .init(title: "Try again", action: action)
        )
    }

    static func timeout(action: @escaping VoidHandler) -> Self {
        DefaultErrorProps(
            title: "Timeout",
            message: "Please try again later",
            image: Image(systemName: "clock.badge.exclamationmark.fill"),
            actionProps: .init(title: "Try again", action: action)
        )
    }

    static func networkFailure(action: @escaping VoidHandler) -> Self {
        DefaultErrorProps(
            title: "Network failure",
            message: "Error Message",
            image: Image(systemName: "exclamationmark.icloud.fill"),
            actionProps: .init(title: "Try again", action: action)
        )
    }

    static func underDevelopment() -> Self {
        DefaultErrorProps(
            title: "Under Development",
            message: "Under Development",
            image: Image(systemName: "wrench.adjustable.fill")
        )
    }
}
