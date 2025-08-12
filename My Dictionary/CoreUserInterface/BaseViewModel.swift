//
//  BaseViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine
import SwiftUI

enum ErrorDisplayType {
    case alert
    case page
    case none
}

@MainActor
open class BaseViewModel: ObservableObject {

    public let dismissPublisher = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    deinit {
        logInfo("DEINIT: \(String(describing: type(of: self)))")
    }
    
    func errorReceived(
        _ error: Error,
        displayType: ErrorDisplayType = .alert,
        actionText: String = "OK",
        action: @escaping VoidHandler = {}
    ) {
        #if os(iOS)
        HapticManager.shared.triggerNotification(type: .error)
        #endif

        switch displayType {
        case .alert:
            showAlert(
                withModel: .init(
                    title: "Ooops...",
                    message: error.localizedDescription,
                    actionText: actionText,
                    action: action
                )
            )
        case .page, .none:
            return
        }
    }
    
    func showAlert(withModel model: AlertModel) {
        AlertCenter.shared.showAlert(with: model)
    }
} 
