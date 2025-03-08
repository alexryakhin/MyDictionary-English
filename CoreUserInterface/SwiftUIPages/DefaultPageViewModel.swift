//
//  DefaultPageViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine
import Core
import Shared

open class DefaultPageViewModel: PageViewModel<DefaultLoaderProps, DefaultPlaceholderProps, DefaultErrorProps> {

    @Published public var isShowingSnack: Bool = false
    @Published public var snackModel = SnackModel(title: .empty, style: .default)

    override public func defaultPageErrorHandler(_ error: CoreError, action: @escaping VoidHandler) {
        let props: DefaultErrorProps? = switch error {
        case .networkError(let error):
                .common(message: error.description, action: action)
        case .storageError(let error):
                .common(message: error.description, action: action)
        case .validationError(let error):
                .common(message: error.description, action: action)
        case .internalError(let error):
                .common(message: error.description, action: action)
        default:
                .common(message: "Unknown error", action: action)
        }
        if let props {
            presentErrorPage(withProps: props)
        }
    }

    public override func presentErrorPage(withProps errorProps: DefaultErrorProps) {
        additionalState = .error(errorProps)
    }

    public override func presentErrorSnack(_ error: CoreError, action: @escaping VoidHandler) {
        snackModel = .init(title: "Ooops, something went wrong", text: error.description, style: .error, actionText: "Try again", action: action)
        isShowingSnack = true
    }

    public override func loadingStarted() {
        additionalState = .loading()
    }

    public override func showSnack(withModel model: SnackModel) {
        snackModel = model
        isShowingSnack = true
    }
}
