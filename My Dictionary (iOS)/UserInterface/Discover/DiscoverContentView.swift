//
//  DiscoverContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct DiscoverContentView: View {
    @ObservedObject var viewModel: DiscoverViewModel
    
    var body: some View {
        switch viewModel.selectedContentType {
        case .music:
            MusicDiscoveringView(
                discoverViewModel: viewModel,
                contentPicker: contentPicker
            )
        case .stories:
            StoryLabConfigurationView(
                discoverViewModel: viewModel,
                contentPicker: contentPicker
            )
        }
    }
    
    private var contentPicker: some View {
        HeaderButtonMenu(
            viewModel.selectedContentType.displayName,
            style: .borderedProminent
        ) {
            Picker(
                Loc.Discover.ContentType.fiterTitle,
                selection: $viewModel.selectedContentType
            ) {
                ForEach(ContentType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.inline)
        }
    }
}

#Preview {
    DiscoverContentView(viewModel: DiscoverViewModel())
}

