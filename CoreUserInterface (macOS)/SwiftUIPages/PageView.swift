//
//  PageView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import SwiftUI

public protocol PageView: View {
    associatedtype ContentView: View
    associatedtype LoaderView: View
    associatedtype ErrorView: View
    associatedtype PlaceholderView: View

    associatedtype ViewModel: DefaultPageViewModel

    typealias PageState = AdditionalPageState<DefaultLoaderProps, DefaultPlaceholderProps, DefaultErrorProps>

    var viewModel: StateObject<ViewModel> { get set }

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
                if let additionalState = viewModel.wrappedValue.additionalState {
                    Color.windowBackgroundColor.ignoresSafeArea()
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
            .alert(isPresented: viewModel.projectedValue.isShowingAlert) {
                if let message = viewModel.wrappedValue.alertModel.message,
                   let actionText = viewModel.wrappedValue.alertModel.actionText,
                   let destructiveActionText = viewModel.wrappedValue.alertModel.destructiveActionText
                {
                    return Alert(
                        title: Text(viewModel.wrappedValue.alertModel.title),
                        message: Text(message),
                        primaryButton: .destructive(Text(destructiveActionText), action: viewModel.wrappedValue.alertModel.destructiveAction),
                        secondaryButton: .cancel(Text(actionText), action: viewModel.wrappedValue.alertModel.action)
                    )
                } else if let message = viewModel.wrappedValue.alertModel.message,
                          let actionText = viewModel.wrappedValue.alertModel.actionText
                {
                    return Alert(
                        title: Text(viewModel.wrappedValue.alertModel.title),
                        message: Text(message),
                        dismissButton: .default(Text(actionText), action: viewModel.wrappedValue.alertModel.action)
                    )
                } else if let message = viewModel.wrappedValue.alertModel.message {
                    return Alert(
                        title: Text(viewModel.wrappedValue.alertModel.title),
                        message: Text(message),
                        dismissButton: .default(Text("OK"))
                    )
                } else {
                    return Alert(
                        title: Text(viewModel.wrappedValue.alertModel.title),
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
        EmptyListView(label: props.title, description: props.subtitle, background: .windowBackgroundColor)
    }

    @ViewBuilder
    func errorView(props: PageState.ErrorProps) -> some View {
        PageErrorView(props: props)
    }
}
