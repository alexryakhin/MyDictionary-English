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
                Alert(
                    title: Text(viewModel.alertModel.title),
                    message: viewModel.alertModel.message != nil ? Text(viewModel.alertModel.message!) : nil,
                    dismissButton: .default(Text(viewModel.alertModel.actionText ?? "OK"), action: viewModel.alertModel.action)
                )
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
