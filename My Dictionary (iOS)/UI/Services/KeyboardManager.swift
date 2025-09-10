//
//  KeyboardManager.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 9/10/25.
//

import UIKit

final class KeyboardManager: ObservableObject {
    static let shared = KeyboardManager()
    
    @Published private(set) var isKeyboardPresented: Bool = false
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        isKeyboardPresented = true
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        isKeyboardPresented = false
    }
}
