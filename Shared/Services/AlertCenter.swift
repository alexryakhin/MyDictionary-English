//
//  AlertCenter.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/7/25.
//

import SwiftUI

final class AlertCenter {

    static let shared = AlertCenter()

    private var isPresentingAlert: Bool = false

    private init() {}

    func showAlert(with model: AlertModel) {
        if !Thread.isMainThread {
            print("❌ [AlertCenter] Must be called from main thread, model: \(model)")
        }
        assert(Thread.isMainThread)

        #if os(iOS)
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow })
        else { return }

        let alertController = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: .alert
        )

        if let action = model.action, let actionText = model.actionText {
            alertController.addAction(.init(title: actionText, style: .cancel) { [weak self] _ in
                action()
                self?.isPresentingAlert = false
            })
        }

        if let additionalAction = model.additionalAction, let additionalActionText = model.additionalActionText {
            alertController.addAction(.init(title: additionalActionText, style: .default) { [weak self] _ in
                additionalAction()
                self?.isPresentingAlert = false
            })
        }

        if let destructiveAction = model.destructiveAction, let destructiveActionText = model.destructiveActionText {
            alertController.addAction(.init(title: destructiveActionText, style: .destructive) { [weak self] _ in
                destructiveAction()
                self?.isPresentingAlert = false
            })
        }

        if model.actionText == nil && model.additionalActionText == nil && model.destructiveActionText == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self, weak alertController] in
                alertController?.dismiss(animated: true)
                self?.isPresentingAlert = false
            }
        }

        guard !isPresentingAlert else { return }

        if let topController = topViewController(for: window.rootViewController), topController.presentedViewController == nil {
            topController.present(alertController, animated: true)
            isPresentingAlert = true
        } else {
            print("⚠️ AlertCenter: Already presenting something. Alert skipped.")
        }
        #elseif os(macOS)
        // For macOS, we'll use NSAlert
        let alert = NSAlert()
        alert.messageText = model.title
        alert.informativeText = model.message
        
        if let action = model.action, let actionText = model.actionText {
            alert.addButton(withTitle: actionText)
            alert.buttons.first?.keyEquivalent = "\r"
        }
        
        if let additionalAction = model.additionalAction, let additionalActionText = model.additionalActionText {
            alert.addButton(withTitle: additionalActionText)
        }
        
        if let destructiveAction = model.destructiveAction, let destructiveActionText = model.destructiveActionText {
            let destructiveButton = alert.addButton(withTitle: destructiveActionText)
            destructiveButton.keyEquivalent = ""
        }
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn, let action = model.action {
            action()
        } else if response == .alertSecondButtonReturn, let additionalAction = model.additionalAction {
            additionalAction()
        } else if response == .alertThirdButtonReturn, let destructiveAction = model.destructiveAction {
            destructiveAction()
        }
        #endif
    }

    #if os(iOS)
    // MARK: - Helper

    private func topViewController(for root: UIViewController?) -> UIViewController? {
        var top = root
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
    #endif
}
