//
//  BaseViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine
import SwiftUI

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
        actionText: String = Loc.Actions.ok.localized,
        action: @escaping VoidHandler = {}
    ) {
        HapticManager.shared.triggerNotification(type: .error)

        showAlert(
            withModel: .init(
                title: Loc.App.oops.localized,
                message: error.localizedDescription,
                actionText: actionText,
                action: action
            )
        )
    }
    
    func showAlert(withModel model: AlertModel) {
        AlertCenter.shared.showAlert(with: model)
    }
} 
