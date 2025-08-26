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
                        text: Loc.FilterDisplay.all,
                        color: .blue,
                        style: viewModel.filterState == .none ? .selected : .regular
                    )
                    .onTap {
                        viewModel.handle(.filterChanged(.none))
                    }

                    TagView(
                        text: Loc.FilterDisplay.favorite,
                        color: .accentColor,
                        style: viewModel.filterState == .favorite ? .selected : .regular
                    )
                    .onTap {
                        viewModel.handle(.filterChanged(.favorite))
                    }

                    TagView(
                        text: Loc.FilterDisplay.new,
                        color: .secondary,
                        style: viewModel.filterState == .new ? .selected : .regular
                    )
                    .onTap {
                        viewModel.handle(.filterChanged(.new))
                    }

                    TagView(
                        text: Loc.FilterDisplay.inProgress,
                        color: .orange,
                        style: viewModel.filterState == .inProgress ? .selected : .regular
                    )
                    .onTap {
                        viewModel.handle(.filterChanged(.inProgress))
                    }

                    TagView(
                        text: Loc.FilterDisplay.needsReview,
                        color: .red,
                        style: viewModel.filterState == .needsReview ? .selected : .regular
                    )
                    .onTap {
                        viewModel.handle(.filterChanged(.needsReview))
                    }

                    TagView(
                        text: Loc.FilterDisplay.mastered,
                        color: .accent,
                        style: viewModel.filterState == .mastered ? .selected : .regular
                    )
                    .onTap {
                        viewModel.handle(.filterChanged(.mastered))
                    }
                }
            }
            .scrollClipDisabled()
        }
    }
}
