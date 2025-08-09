//
//  IdiomListContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct IdiomListContentView: View {

    @ObservedObject var viewModel: IdiomListViewModel

    init(viewModel: IdiomListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        IdiomListView(viewModel: viewModel)
    }
}
