//
//  SharedWordListFilterView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct SharedWordListFilterView: View {
    @ObservedObject var viewModel: SharedWordListViewModel
    
    var body: some View {
        if viewModel.words.isNotEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // All Words Filter
                    TagView(
                        text: Loc.FilterDisplay.all.localized,
                        color: .blue,
                        style: viewModel.filterState == .none ? .selected : .regular
                    )
                    .onTap {
                        viewModel.handle(.filterChanged(.none))
                    }

                    // Favorite Words Filter
                    TagView(
                        text: Loc.FilterDisplay.favorite.localized,
                        color: .accentColor,
                        style: viewModel.filterState == .favorite ? .selected : .regular
                    )
                    .onTap {
                        viewModel.handle(.filterChanged(.favorite))
                    }

                    // Difficulty Filters
                    TagView(
                        text: Loc.FilterDisplay.new.localized,
                        color: .secondary,
                        style: viewModel.filterState == .new ? .selected : .regular
                    )
                    .onTap {
                        viewModel.handle(.filterChanged(.new))
                    }

                    TagView(
                        text: Loc.FilterDisplay.inProgress.localized,
                        color: .orange,
                        style: viewModel.filterState == .inProgress ? .selected : .regular
                    )
                    .onTap {
                        viewModel.handle(.filterChanged(.inProgress))
                    }

                    TagView(
                        text: Loc.FilterDisplay.needsReview.localized,
                        color: .red,
                        style: viewModel.filterState == .needsReview ? .selected : .regular
                    )
                    .onTap {
                        viewModel.handle(.filterChanged(.needsReview))
                    }

                    TagView(
                        text: Loc.FilterDisplay.mastered.localized,
                        color: .accent,
                        style: viewModel.filterState == .mastered ? .selected : .regular
                    )
                    .onTap {
                        viewModel.handle(.filterChanged(.mastered))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
