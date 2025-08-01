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

open class BaseViewModel: ObservableObject {
    
    @Published var isShowingAlert: Bool = false
    @Published var alertModel = AlertModel(title: .empty)

    public let dismissPublisher = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    deinit {
        logInfo("DEINIT: \(String(describing: type(of: self)))")
    }
    
    func errorReceived(
        _ error: Error,
        displayType: ErrorDisplayType = .alert,
        actionText: String? = nil,
        action: @escaping VoidHandler = {}
    ) {
        #if os(iOS)
        HapticManager.shared.triggerNotification(type: .error)
        #endif
        guard let errorWithContext = error as? CoreError else {
            logError("Unexpectedly receive `Error` which is not `CoreError`, \(error)")
            return
        }
        
        switch displayType {
        case .alert:
            showAlert(
                withModel: .init(
                    title: "Ooops...",
                    message: errorWithContext.description,
                    actionText: actionText,
                    action: action
                )
            )
        case .page, .none:
            return
        }
    }
    
    func showAlert(withModel model: AlertModel) {
        if isShowingAlert {
            isShowingAlert = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
                self?.showAlert(withModel: model)
            })
            return
        }
        alertModel = model
        isShowingAlert = true
    }
} 
