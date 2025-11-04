//
//  ImageSelectionView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 1/8/25.
//

import SwiftUI

struct ImageSelectionView: View {

    enum ScreenState {
        case initial
        case loading
        case content
        case error(String)
    }

    struct ContentModel {
        var pexelsPhotos: [PexelsPhoto]
        var hasMorePages: Bool
        var isLoadingMore: Bool
        var currentPage: Int
    }

    private let pexelsService = PexelsService.shared

    @State private var searchQuery: String = ""
    @State private var language: InputLanguage = .english
    @State private var screenState: ScreenState = .initial
    @State private var selectedPhoto: PexelsPhoto?
    @State private var content: ContentModel?

    let word: String
    let onImageSelected: (String, String) -> Void // (imageUrl, localPath)
    let onDismiss: () -> Void

    init(
        word: String,
        language: InputLanguage,
        onImageSelected: @escaping (String, String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.word = word
        self._language = .init(initialValue: language)
        self.onImageSelected = onImageSelected
        self.onDismiss = onDismiss
    }

    var body: some View {
        ScrollViewWithCustomNavBar {
            switch screenState {
            case .initial:
                ContentUnavailableView {
                    Image(systemName: "photo.badge.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                } description: {
                    Text(Loc.WordImages.ImageSelection.initialMessage)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loading:
                ContentUnavailableView {
                    ProgressView()
                } description: {
                    Text(Loc.WordImages.ImageSelection.searching(searchQuery))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .content:
                if let content, content.pexelsPhotos.isNotEmpty {
                    VStack(spacing: 12) {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(content.pexelsPhotos) { photo in
                                ImageThumbnailView(
                                    photo: photo,
                                    isSelected: selectedPhoto?.id == photo.id,
                                    onTap: {
                                        selectedPhoto = photo
                                    }
                                )
                            }
                        }
                        if content.isLoadingMore {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(Loc.Actions.loadingMore)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else if content.hasMorePages {
                            HeaderButton(Loc.Actions.loadMore, icon: "plus.circle") {
                                loadMoreImages()
                            }
                        }
                    }
                    .padding()
                } else {
                    ContentUnavailableView {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    } description: {
                        Text(Loc.WordImages.ImageSelection.noImagesFound(word))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            case .error(let errorMessage):
                ContentUnavailableView {
                    Image(systemName: "photo.trianglebadge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button(Loc.WordImages.ImageSelection.retry) {
                        searchImages()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } navigationBar: {
            NavigationBarView(
                title: Loc.WordImages.ImageSelection.title,
                mode: .inline,
                showsDismissButton: false,
                trailingContent: {
                    HeaderButton(Loc.Actions.cancel) {
                        onDismiss()
                    }
                    AsyncHeaderButton(Loc.Actions.done, style: .borderedProminent) {
                        await selectImage()
                    }
                    .disabled(selectedPhoto == nil)
                },
                bottomContent: {
                    HStack(spacing: 8) {
                        InputView(
                            Loc.WordImages.ImageSelection.searchPlaceholder,
                            showInputLanguagePicker: true,
                            text: $searchQuery,
                            inputLanguage: $language,
                            onSubmit: {
                                searchImages()
                            })
                        HeaderButton(icon: "magnifyingglass") {
                            searchImages()
                        }
                    }
                }
            )
        }
        .frame(width: 500, height: 500)
        .groupedBackground()
        .onAppear {
            AnalyticsService.shared.logEvent(.imageSelectionOpened, parameters: [
                "word": word,
                "user_subscription_status": SubscriptionService.shared.isProUser ? "pro" : "free"
            ])
            guard word.isNotEmpty else { return }
            searchQuery = word
            searchImages()
        }
    }

    private func searchImages() {
        guard !searchQuery.isEmpty else { return }

        screenState = .loading

        Task { @MainActor in
            do {
                let response = try await pexelsService.searchImages(
                    query: searchQuery,
                    language: language,
                    perPage: 15,
                    orientation: "landscape",
                    page: 1
                )
                
                // Log search analytics
                AnalyticsService.shared.logEvent(.imageSearchPerformed, parameters: [
                    "search_query": searchQuery,
                    "results_count": response.photos.count,
                    "total_results": response.totalResults,
                    "language": language.rawValue,
                    "word": word
                ])

                content = .init(
                    pexelsPhotos: response.photos,
                    hasMorePages: response.nextPage != nil,
                    isLoadingMore: false,
                    currentPage: response.page
                )
                screenState = .content
            } catch {
                screenState = .error(error.localizedDescription)
            }
        }
    }
    
    private func loadMoreImages() {
        guard let content, content.isLoadingMore == false else { return }

        self.content?.isLoadingMore = true

        Task { @MainActor in
            do {
                let response = try await pexelsService.searchImages(
                    query: searchQuery,
                    language: language,
                    perPage: 15,
                    orientation: "landscape",
                    page: content.currentPage + 1
                )
                
                let allPhotos = content.pexelsPhotos + response.photos

                // Log load more analytics
                AnalyticsService.shared.logEvent(.imageLoadMorePerformed, parameters: [
                    "search_query": searchQuery,
                    "page": content.currentPage + 1,
                    "new_results_count": response.photos.count,
                    "total_loaded": allPhotos.count,
                    "language": language.rawValue,
                    "word": word
                ])

                self.content?.pexelsPhotos = allPhotos
                self.content?.isLoadingMore = false
                self.content?.currentPage = response.page
            } catch {
                screenState = .error(error.localizedDescription)
            }
        }
    }

    private func selectImage() async {
        guard let photo = selectedPhoto else { return }

        do {
            // Use the word parameter for filename, but searchQuery for the actual search
            let localPath = try await pexelsService.downloadAndSaveImage(from: photo, for: word)
            await MainActor.run {
                // Log image selection analytics
                AnalyticsService.shared.logEvent(.imageSelected, parameters: [
                    "word": word,
                    "image_source": "pexels",
                    "image_url": photo.src.medium,
                    "download_success": true
                ])
                
                onImageSelected(photo.src.medium, localPath)
                onDismiss()
            }
        } catch {
            await MainActor.run {
                screenState = .error(Loc.WordImages.ImageSelection.failedToDownload(error.localizedDescription))
            }
        }
    }
}

struct ImageThumbnailView: View {
    let photo: PexelsPhoto
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        GeometryReader { geo in
            AsyncImage(url: URL(string: photo.src.small)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipShape(.rect(cornerRadius: 12))
            } placeholder: {
                ShimmerView(width: geo.size.width, height: geo.size.height)
            }
        }
        .frame(height: 100)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: 3)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                    .background(Color.white)
                    .clipShape(Circle())
                    .padding(4)
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    ImageSelectionView(
        word: "apple",
        language: .english,
        onImageSelected: { _, _ in },
        onDismiss: { }
    )
}
