//
//  VocabularyListFilterView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct VocabularyListFilterView: View {
    @ObservedObject var wordListViewModel: WordListViewModel
    @ObservedObject var idiomListViewModel: IdiomListViewModel
    
    @State private var selectedFilterCase: FilterCase = .none
    @State private var selectedTag: CDTag?
    @State private var selectedLanguage: InputLanguage?
    
    @State private var showingTagManagement = false
    
    var body: some View {
        if wordListViewModel.words.isNotEmpty || idiomListViewModel.idioms.isNotEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // All Words Filter
                    TagView(
                        text: Loc.FilterDisplay.all,
                        color: .blue,
                        style: selectedFilterCase == .none ? .selected : .regular
                    )
                    .onTap {
                        selectedFilterCase = .none
                    }

                    // Favorite Words Filter
                    TagView(
                        text: Loc.FilterDisplay.favorite,
                        color: .accentColor,
                        style: selectedFilterCase == .favorite ? .selected : .regular
                    )
                    .onTap {
                        selectedFilterCase = .favorite
                    }

                    // Difficulty Filter
                    var difficultyMenuTitle: String {
                        switch selectedFilterCase {
                        case .new: Loc.FilterDisplay.new
                        case .inProgress: Loc.FilterDisplay.inProgress
                        case .needsReview: Loc.FilterDisplay.needsReview
                        case .mastered: Loc.FilterDisplay.mastered
                        default: Loc.Words.difficulty
                        }
                    }
                    var difficultyMenuColor: Color {
                        switch selectedFilterCase {
                        case .new: .secondary
                        case .inProgress: .orange
                        case .needsReview: .red
                        case .mastered: .accent
                        default: .indigo
                        }
                    }
                    var difficultyMenuStyle: TagView.Style {
                        switch selectedFilterCase {
                        case .new: .selected
                        case .inProgress: .selected
                        case .needsReview: .selected
                        case .mastered: .selected
                        default: .regular
                        }
                    }
                    Menu {
                        Picker(Loc.Words.difficulty, selection: $selectedFilterCase) {
                            Text(Loc.FilterDisplay.new).tag(FilterCase.new)
                            Text(Loc.FilterDisplay.inProgress).tag(FilterCase.inProgress)
                            Text(Loc.FilterDisplay.needsReview).tag(FilterCase.needsReview)
                            Text(Loc.FilterDisplay.mastered).tag(FilterCase.mastered)
                        }
                        .pickerStyle(.inline)
                    } label: {
                        TagView(
                            text: difficultyMenuTitle,
                            color: difficultyMenuColor,
                            style: difficultyMenuStyle
                        )
                    }
                    .buttonStyle(.plain)

                    // Tag Filter
                    Menu {
                        Section {
                            Button {
                                showingTagManagement = true
                            } label: {
                                Label(Loc.Words.WordList.manageTags, systemImage: "plus")
                            }
                        }
                        Section {
                            Picker(Loc.FilterDisplay.tag, selection: $selectedTag) {
                                ForEach(wordListViewModel.availableTags, id: \.id) { tag in
                                    Text(tag.name ?? "")
                                        .tag(tag)
                                }
                            }
                            .pickerStyle(.inline)
                        }
                    } label: {
                        TagView(
                            text: selectedTag?.name ?? Loc.FilterDisplay.tag,
                            color: selectedTag?.colorValue.color ?? .brown,
                            style: selectedTag == nil ? .regular : .selected
                        )
                    }
                    .buttonStyle(.plain)

                    // Language Filter
                    let languages = (wordListViewModel.availableLanguages + idiomListViewModel.availableLanguages).removedDuplicates
                    if languages.count > 1 {
                        Menu {
                            Picker(Loc.FilterDisplay.language, selection: $selectedLanguage) {
                                ForEach(languages, id: \.self) { language in
                                    Text(language.displayName)
                                        .tag(language)
                                }
                            }
                            .pickerStyle(.inline)
                        } label: {
                            TagView(
                                text: selectedLanguage?.displayName ?? Loc.FilterDisplay.language,
                                color: .purple,
                                style: selectedLanguage == nil ? .regular : .selected
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .sheet(isPresented: $showingTagManagement) {
                TagManagementView()
            }
            .onChange(of: selectedFilterCase) {
                if selectedFilterCase != .tag {
                    selectedTag = nil
                }
                if selectedFilterCase != .language {
                    selectedLanguage = nil
                }
                handleFilterChanged(
                    selectedFilterCase,
                    tag: selectedTag,
                    language: selectedLanguage
                )
            }
            .onChange(of: selectedTag) {
                if let selectedTag {
                    selectedFilterCase = .tag
                    handleFilterChanged(
                        selectedFilterCase,
                        tag: selectedTag,
                        language: selectedLanguage
                    )
                }
            }
            .onChange(of: selectedLanguage) {
                if let selectedLanguage {
                    selectedFilterCase = .language
                    handleFilterChanged(
                        selectedFilterCase,
                        tag: selectedTag,
                        language: selectedLanguage
                    )
                }
            }
        }
    }

    private func handleFilterChanged(_ filter: FilterCase, tag: CDTag? = nil, language: InputLanguage? = nil) {
        wordListViewModel.handle(.filterChanged(filter, tag: tag, language: language))
        idiomListViewModel.handle(.filterChanged(filter, tag: tag, language: language))
    }
}
