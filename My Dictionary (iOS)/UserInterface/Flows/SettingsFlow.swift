//
//  SettingsFlow.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct SettingsFlow: View {

    // MARK: - Properties

    @StateObject private var navigationManager: NavigationManager = .shared
    @ObservedObject var viewModel: SettingsViewModel

    // MARK: - Body

    var body: some View {
        SettingsView(viewModel: viewModel)
            .onReceive(viewModel.output) { output in
                handleOutput(output)
            }
    }

    // MARK: - Private Methods

    private func handleOutput(_ output: SettingsViewModel.Output) {
        switch output {
        case .showAboutApp:
            navigationManager.navigationPath.append(NavigationDestination.aboutApp)
        case .showTagManagement:
            navigationManager.navigationPath.append(NavigationDestination.tagManagement)
        case .showSharedDictionaries:
            navigationManager.navigationPath.append(NavigationDestination.sharedDictionariesList)
        case .showAuthentication:
            navigationManager.navigationPath.append(NavigationDestination.authentication)
        case .showProfile:
            navigationManager.navigationPath.append(NavigationDestination.profile)
        case .showDeleteWords:
            navigationManager.navigationPath.append(NavigationDestination.deleteWords)
        }
    }
}
