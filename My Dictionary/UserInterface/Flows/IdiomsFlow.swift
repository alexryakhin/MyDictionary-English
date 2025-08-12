//
//  IdiomsFlow.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct IdiomsFlow: View {

    // MARK: - Properties

    @StateObject private var navigationManager: NavigationManager = .shared
    @ObservedObject var viewModel: IdiomListViewModel

    // MARK: - Body

    var body: some View {
        IdiomListContentView(viewModel: viewModel)
            .onReceive(viewModel.output) { output in
                handleOutput(output)
            }
    }

    // MARK: - Private Methods

    private func handleOutput(_ output: IdiomListViewModel.Output) {
        switch output {
        case .showIdiomDetails(let idiom):
            navigationManager.navigationPath.append(NavigationDestination.idiomDetails(idiom))
        case .showAddIdiom:
            navigationManager.navigationPath.append(NavigationDestination.addIdiom)
        }
    }
}
