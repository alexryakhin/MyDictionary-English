//
//  ImageSelectionView.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/8/25.
//

import SwiftUI

struct ImageSelectionView: View {

    enum ScreenState {
        case initial
        case loading
        case photosAvailable([PexelsPhoto])
        case error(String)
    }

    private let pexelsService = PexelsService.shared

    @State private var searchQuery: String = ""
    @State private var language: InputLanguage = .english
    @State private var screenState: ScreenState = .initial
    @State private var selectedPhoto: PexelsPhoto?

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
        VStack(spacing: 0) {
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
                VStack {
                    ProgressView()
                    Text(Loc.WordImages.ImageSelection.searching(searchQuery))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .photosAvailable(let photos):
                if photos.isNotEmpty {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(photos) { photo in
                                ImageThumbnailView(
                                    photo: photo,
                                    isSelected: selectedPhoto?.id == photo.id,
                                    onTap: {
                                        selectedPhoto = photo
                                    }
                                )
                            }
                        }
                        .padding()
                    }
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
        }
        .groupedBackground()
        .navigation(
            title: Loc.WordImages.ImageSelection.title,
            mode: .inline,
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
                let results = try await pexelsService.searchImages(
                    query: searchQuery,
                    language: language,
                    perPage: 15,
                    orientation: "landscape"
                )
                
                // Log search analytics
                AnalyticsService.shared.logEvent(.imageSearchPerformed, parameters: [
                    "search_query": searchQuery,
                    "results_count": results.count,
                    "language": language.rawValue,
                    "word": word
                ])
                
                screenState = .photosAvailable(results)
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
