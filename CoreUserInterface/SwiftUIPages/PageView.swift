//
//  PageView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import SwiftUI
import SwiftUISnackbar

public protocol PageView: View {
    associatedtype ContentView: View
    associatedtype LoaderView: View
    associatedtype ErrorView: View
    associatedtype PlaceholderView: View

    associatedtype ViewModel: DefaultPageViewModel

    typealias PageState = AdditionalPageState<DefaultLoaderProps, DefaultPlaceholderProps, DefaultErrorProps>

    var viewModel: ViewModel { get set }

    @ViewBuilder var contentView: ContentView { get }
    @ViewBuilder func loaderView(props: PageState.LoaderProps) -> LoaderView
    @ViewBuilder func placeholderView(props: PageState.PlaceholderProps) -> PlaceholderView
    @ViewBuilder func errorView(props: PageState.ErrorProps) -> ErrorView
}

public extension PageView {
    @ViewBuilder
    var body: some View {
        contentView
            .overlay {
                if let additionalState = viewModel.additionalState {
                    Color.systemBackground.ignoresSafeArea()
                    switch additionalState {
                    case .loading(let props):
                        loaderView(props: props)
                    case .error(let props):
                        errorView(props: props)
                    case .placeholder(let props):
                        placeholderView(props: props)
                    }
                }
            }
            .alert(isPresented: .init(get: {
                viewModel.isShowingAlert
            }, set: { newValue in
                viewModel.isShowingAlert = newValue
            })) {
                if let message = viewModel.alertModel.message,
                   let actionText = viewModel.alertModel.actionText,
                   let destructiveActionText = viewModel.alertModel.destructiveActionText
                {
                    return Alert(
                        title: Text(viewModel.alertModel.title),
                        message: Text(message),
                        primaryButton: .destructive(Text(destructiveActionText), action: viewModel.alertModel.destructiveAction),
                        secondaryButton: .cancel(Text(actionText), action: viewModel.alertModel.action)
                    )
                } else if let message = viewModel.alertModel.message,
                          let actionText = viewModel.alertModel.actionText
                {
                    return Alert(
                        title: Text(viewModel.alertModel.title),
                        message: Text(message),
                        dismissButton: .default(Text(actionText), action: viewModel.alertModel.action)
                    )
                } else if let message = viewModel.alertModel.message {
                    return Alert(
                        title: Text(viewModel.alertModel.title),
                        message: Text(message),
                        dismissButton: .default(Text("OK"))
                    )
                } else {
                    return Alert(
                        title: Text(viewModel.alertModel.title),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
    }

    @ViewBuilder
    func loaderView(props: PageState.LoaderProps) -> some View {
        PageLoadingView(props: props)
    }

    @ViewBuilder
    func placeholderView(props: PageState.PlaceholderProps) -> some View {
        EmptyListView(label: props.title, description: props.subtitle)
    }

    @ViewBuilder
    func errorView(props: PageState.ErrorProps) -> some View {
        PageErrorView(props: props)
    }
}
