//
//  WordListContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import StoreKit

struct WordListContentView: View {

    @ObservedObject var viewModel: WordListViewModel

    init(viewModel: WordListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        WordListView(viewModel: viewModel)
    }
}
