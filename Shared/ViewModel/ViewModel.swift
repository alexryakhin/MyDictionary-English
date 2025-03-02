//
//  ViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/2/25.
//

import Combine

class ViewModel: ObservableObject {

    enum AdditionalState {
        case loading
        case error(Error)
        case placeholder
    }

    @Published private(set) var additionalState: AdditionalState?

    init() {
        print("DEBUG50 \(String(describing: self)) init")
    }

    deinit {
        print("DEBUG50 \(String(describing: self)) deinit")
    }

    func presentLoading() {
        additionalState = .loading
    }

    func presentPlaceholder() {
        additionalState = .placeholder
    }

    func handleError(_ error: Error, isFullScreen: Bool = false) {
        print(error)

        if isFullScreen {
            additionalState = .error(error)
        } else {
            // TODO: show snack
        }
    }

    func resetAdditionalState() {
        additionalState = nil
    }
}
