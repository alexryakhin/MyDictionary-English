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
            navigationPath.append("about_app")
        case .showTagManagement:
            navigationPath.append("tag_management")
        case .showSharedDictionaries:
            navigationPath.append("shared_dictionaries")
        case .showAuthentication:
            navigationPath.append("authentication")
        }
    }
}
