//
//  DiscoverContentView.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import SwiftUI

struct DiscoverContentView: View {
    @ObservedObject var viewModel: DiscoverViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Content type selection (initially only Music)
                contentTypeSelector

                // Main content based on selected type
                switch viewModel.selectedContentType {
                case .music:
                    MusicLearningContentView()
                }
            }
        }
        .groupedBackground()
        .navigation(title: Loc.Navigation.Tabbar.discover)
    }
    
    private var contentTypeSelector: some View {
        Picker("Content Type", selection: $viewModel.selectedContentType) {
            ForEach(ContentType.allCases) { type in
                Text(type.displayName).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

#Preview {
    DiscoverContentView(viewModel: DiscoverViewModel())
}

