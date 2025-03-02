//
//  AnyPageViewModel.swift
//  Suint One
//
//  Created by Aleksandr Riakhin on 9/30/24.
//

import Combine
import SwiftUI

open class PageViewModel<
    LoaderProps,
    PlaceholderProps,
    ErrorProps
>: ObservableObject {

    typealias PageState = AdditionalPageState<LoaderProps, PlaceholderProps, ErrorProps>

    // MARK: - Properties

    @Published var additionalState: PageState?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    init() { }

    func setState(_ newState: PageState) {
        additionalState = newState
    }

    func resetAdditionalState() {
        withAnimation {
            additionalState = nil
        }
    }

    func errorReceived(
        _ error: Error,
        displayType: ErrorDisplayType,
        action: @escaping VoidHandler = {}
    ) {
        guard let errorWithContext = error as? CoreError else {
            print("Unexpectedly receive `Error` which is not `CoreError`")
            return
        }
        defaultErrorReceived(errorWithContext, displayType: displayType, action: action)
    }

    /// Override this function to implement custom error processing
    func defaultErrorReceived(
        _ error: CoreError,
        displayType: ErrorDisplayType,
        action: @escaping VoidHandler
    ) {
        switch displayType {
        case .page:
            defaultPageErrorHandler(error, action: action)
        case .snack:
            presentErrorSnack(error, action: action)
        case .none:
            return
        }
    }

    func defaultPageErrorHandler(_ error: CoreError, action: @escaping VoidHandler) {
        assertionFailure()
    }

    func presentErrorPage(withProps errorProps: ErrorProps) {
        assertionFailure()
    }

    func presentErrorSnack(_ error: CoreError, action: @escaping VoidHandler) {
        assertionFailure()
    }

    func loadingStarted() {
        assertionFailure()
    }

    func showSnack(withModel: SnackModel) {
        assertionFailure()
    }
}
