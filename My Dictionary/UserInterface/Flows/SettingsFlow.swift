//
//  SettingsFlow.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct SettingsFlow: View {

    // MARK: - Properties

    @Binding var navigationPath: NavigationPath
    @ObservedObject var viewModel: SettingsViewModel

    // MARK: - Body

    var body: some View {
        SettingsContentView(viewModel: viewModel)
            .onReceive(viewModel.output) { output in
                handleOutput(output)
            }
    }

    // MARK: - Private Methods

    private func handleOutput(_ output: SettingsViewModel.Output) {
        switch output {
        case .showAboutApp:
            navigationPath.append(NavigationDestination.aboutApp)
        case .showTagManagement:
            navigationPath.append(NavigationDestination.tagManagement)
        case .showSharedDictionaries:
            navigationPath.append(NavigationDestination.sharedDictionariesList)
        case .showAuthentication:
            navigationPath.append(NavigationDestination.authentication)
        }
    }
}
