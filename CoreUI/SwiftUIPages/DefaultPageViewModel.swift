//
//  DefaultPageViewModel.swift
//  Suint One
//
//  Created by Aleksandr Riakhin on 9/30/24.
//
import Foundation

class DefaultPageViewModel: PageViewModel<DefaultLoaderProps, DefaultPlaceholderProps, DefaultErrorProps> {

    @Published var isShowingSnack: Bool = false
    @Published var snackModel = SnackModel(title: .empty, style: .default)

    override func defaultPageErrorHandler(_ error: CoreError, action: @escaping VoidHandler) {
        let props: DefaultErrorProps? = switch error {
        case .networkError(let error):
                .common(message: error.description, action: action)
        case .storageError(let error):
                .common(message: error.description, action: action)
        case .validationError(let error):
                .common(message: error.description, action: action)
        case .unknownError:
                .common(message: "Unknown error", action: action)
        }
        if let props {
            presentErrorPage(withProps: props)
        }
    }

    override func presentErrorPage(withProps errorProps: DefaultErrorProps) {
        additionalState = .error(errorProps)
    }

    override func presentErrorSnack(_ error: CoreError, action: @escaping VoidHandler) {
        snackModel = .init(title: "Ooops, something went wrong", text: error.description, style: .error, actionText: "Try again", action: action)
        isShowingSnack = true
    }

    override func loadingStarted() {
        additionalState = .loading()
    }

    override func showSnack(withModel model: SnackModel) {
        snackModel = model
        isShowingSnack = true
    }
}
