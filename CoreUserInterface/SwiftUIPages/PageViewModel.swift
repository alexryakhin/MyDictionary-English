//
//  AnyPageViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Combine
import SwiftUI
import Shared
import Core

open class PageViewModel<
    LoaderProps,
    PlaceholderProps,
    ErrorProps
>: ObservableObject {

    public typealias PageState = AdditionalPageState<LoaderProps, PlaceholderProps, ErrorProps>

    // MARK: - Properties

    @Published public var additionalState: PageState?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    public init() { }

    deinit {
        logInfo("DEINIT: \(String(describing: type(of: self)))")
    }

    public func setState(_ newState: PageState) {
        additionalState = newState
    }

    public func resetAdditionalState() {
        withAnimation {
            additionalState = nil
        }
    }

    public func errorReceived(
        _ error: Error,
        displayType: ErrorDisplayType,
        actionText: String? = nil,
        action: @escaping VoidHandler = {}
    ) {
        HapticManager.shared.triggerNotification(type: .error)
        guard let errorWithContext = error as? CoreError else {
            logError("Unexpectedly receive `Error` which is not `CoreError`, \(error)")
            return
        }
        defaultErrorReceived(errorWithContext, displayType: displayType, action: action)
    }

    /// Override this function to implement custom error processing
    public func defaultErrorReceived(
        _ error: CoreError,
        displayType: ErrorDisplayType,
        actionText: String? = nil,
        action: @escaping VoidHandler
    ) {
        switch displayType {
        case .page:
            defaultPageErrorHandler(error, action: action)
        case .alert:
            showAlert(
                withModel: .init(
                    title: "Error",
                    message: error.description,
                    actionText: actionText,
                    action: action
                )
            )
        case .none:
            return
        }
    }

    open func defaultPageErrorHandler(_ error: CoreError, action: @escaping VoidHandler) {
        assertionFailure()
    }

    open func presentErrorPage(withProps errorProps: ErrorProps) {
        assertionFailure()
    }

    open func loadingStarted() {
        assertionFailure()
    }

    open func showAlert(withModel model: AlertModel) {
        assertionFailure()
    }
}
