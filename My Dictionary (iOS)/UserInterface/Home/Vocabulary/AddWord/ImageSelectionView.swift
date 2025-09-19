//
//  ImageSelectionView.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/8/25.
//

import SwiftUI

struct ImageSelectionView: View {
    private let pexelsService = PexelsService.shared

    @State private var searchQuery: String = ""
    @State private var language: InputLanguage = .english
    @State private var photos: [PexelsPhoto] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedPhoto: PexelsPhoto?
    @State private var isDownloading = false
    
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
            // Content
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Searching images for '\(searchQuery)'...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                ContentUnavailableView {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Retry") {
                        searchImages()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if photos.isEmpty {
                ContentUnavailableView {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                } description: {
                    Text("No images found for '\(word)'")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
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
            }
        }
        .groupedBackground()
        .navigation(
            title: "Select Image",
            mode: .inline,
            trailingContent: {
                HeaderButton(Loc.Actions.cancel) {
                    onDismiss()
                }
                HeaderButton(Loc.Actions.done, style: .borderedProminent) {
                    selectImage()
                }
                .disabled(selectedPhoto == nil)
            },
            bottomContent: {
                HStack(spacing: 8) {
                    InputView(
                        "Search for different images...",
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
            // Automatically start searching for the word
            searchQuery = word
            searchImages()
        }
    }
    
    private func searchImages() {
        guard !searchQuery.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let results = try await pexelsService.searchImages(
                    query: searchQuery,
                    language: language,
                    perPage: 15,
                    orientation: "landscape"
                )
                await MainActor.run {
                    self.photos = results
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func selectImage() {
        guard let photo = selectedPhoto else { return }
        
        isDownloading = true
        
        Task {
            do {
                // Use the word parameter for filename, but searchQuery for the actual search
                let localPath = try await pexelsService.downloadAndSaveImage(from: photo, for: word)
                await MainActor.run {
                    onImageSelected(photo.src.medium, localPath)
                    onDismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to download image: \(error.localizedDescription)"
                    isDownloading = false
                }
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
