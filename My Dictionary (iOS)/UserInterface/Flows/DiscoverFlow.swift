//
//  DiscoverFlow.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import SwiftUI

struct DiscoverFlow: View {
    @StateObject private var viewModel = DiscoverViewModel()
    
    var body: some View {
        DiscoverContentView(viewModel: viewModel)
    }
}

