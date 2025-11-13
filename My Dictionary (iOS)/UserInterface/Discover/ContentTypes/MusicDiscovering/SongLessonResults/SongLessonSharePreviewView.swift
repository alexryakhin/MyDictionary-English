import SwiftUI
import UIKit

@MainActor
final class SongLessonSharePreviewViewModel: ObservableObject {
    enum Aspect: String, CaseIterable, Identifiable {
        case square
        case portrait
        case landscape
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .square:
                return "1:1"
            case .portrait:
                return "9:16"
            case .landscape:
                return "16:9"
            }
        }
        
        var aspectRatio: CGFloat {
            switch self {
            case .square:
                return 1
            case .portrait:
                return 9.0 / 16.0
            case .landscape:
                return 16.0 / 9.0
            }
        }

        var size: CGSize {
            switch self {
            case .square:
                return .init(width: 750, height: 750)
            case .portrait:
                return .init(width: 480, height: 854)
            case .landscape:
                return .init(width: 854, height: 480)
            }
        }

        var label: String {
            switch self {
            case .square:
                return Loc.MusicDiscovering.Share.Aspect.square
            case .portrait:
                return Loc.MusicDiscovering.Share.Aspect.story
            case .landscape:
                return Loc.MusicDiscovering.Share.Aspect.wide
            }
        }
    }
    
    let data: SongLessonSharePreviewData
    @Published var selectedAspect: Aspect {
        didSet {
            renderedImage = renderSelectedImage()
        }
    }
    @Published private(set) var artworkImage: UIImage?
    @Published private(set) var renderedImage: UIImage?

    init(data: SongLessonSharePreviewData) {
        self.data = data
        self.selectedAspect = .portrait
        setup()
    }

    func setup() {
        Task {
            await loadArtwork()
            renderedImage = renderSelectedImage()
        }
    }

    func loadArtwork() async {
        guard artworkImage == nil, let url = data.song.albumArtURL else { return }
        do {
            let (rawData, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: rawData) {
                artworkImage = image
            }
        } catch {
            // Ignore artwork loading errors
        }
    }
    
    func renderSelectedImage() -> UIImage? {
        renderImage(for: selectedAspect)
    }
    
    private func renderImage(for aspect: Aspect) -> UIImage? {
        let content = SongLessonShareCard(
            data: data,
            aspect: selectedAspect,
            artwork: artworkImage
        )

        let renderer = ImageRenderer(content: content)
        renderer.scale = UIScreen.main.scale
        #if os(iOS)
        return renderer.uiImage
        #else
        return nil
        #endif
    }
}

struct SongLessonSharePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SongLessonSharePreviewViewModel
    @State private var shareImage: UIImage?
    @State private var isPresentingShareSheet = false

    init(data: SongLessonSharePreviewData) {
        _viewModel = StateObject(wrappedValue: SongLessonSharePreviewViewModel(data: data))
    }
    
    var body: some View {
        Group {
            if let image = viewModel.renderedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 24))
                    .shadow(color: Color.black.opacity(0.25), radius: 20, y: 10)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Loc.MusicDiscovering.Share.Accessibility.previewCard)
            } else {
                ProgressView()
            }
        }
        .padding(vertical: 12, horizontal: 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .groupedBackground()
        .navigation(
            title: Loc.MusicDiscovering.Share.Navigation.title,
            mode: .regular,
            trailingContent: {
                HeaderButton(Loc.Actions.cancel) {
                    dismiss()
                }
            },
            bottomContent: {
                aspectPicker
            }
        )
        .safeAreaBarIfAvailable {
            shareButton
                .padding(vertical: 12, horizontal: 16)
        }
        .task {
            await viewModel.loadArtwork()
        }
        .sheet(isPresented: $isPresentingShareSheet, onDismiss: {
            shareImage = nil
        }) {
            if let shareImage {
                ActivityViewController(activityItems: [shareImage])
            }
        }
    }
    
    private var aspectPicker: some View {
        Picker(Loc.MusicDiscovering.Share.Picker.aspectRatio, selection: $viewModel.selectedAspect) {
            ForEach(SongLessonSharePreviewViewModel.Aspect.allCases) { aspect in
                Text(aspect.label)
                    .tag(aspect)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private var shareButton: some View {
        AsyncActionButton(Loc.MusicDiscovering.Share.Actions.share, systemImage: "square.and.arrow.up") {
            await generateShareImage()
        }
    }
    
    private func generateShareImage() async {
        if let image = viewModel.renderSelectedImage() {
            shareImage = image
            isPresentingShareSheet = true
        } else {
            showAlertWithMessage(Loc.MusicDiscovering.Share.Alert.generateFailed)
        }
    }
}

private struct SongLessonShareCard: View {
    let data: SongLessonSharePreviewData
    let aspect: SongLessonSharePreviewViewModel.Aspect
    let artwork: UIImage?

    var body: some View {
        switch aspect {
        case .square, .portrait:
            VStack(spacing: 28) {
                header
                artworkView
                songDetails
                statsSection
                footer
            }
            .padding(.vertical, 48)
            .padding(.horizontal, 42)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.white)
            .frame(width: aspect.size.width, height: aspect.size.height)
            .background(Color.accent.gradient)
            .aspectRatio(aspect.aspectRatio, contentMode: .fit)
        case .landscape:
            HStack(spacing: 15) {
                VStack(spacing: 30) {
                    artworkView
                    songDetails
                }
                .padding(40)

                VStack(spacing: 40) {
                    header
                    statsSection
                    footer
                }
                .padding(40)
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.white)
            .frame(width: aspect.size.width, height: aspect.size.height)
            .background(Color.accent.gradient)
            .aspectRatio(aspect.aspectRatio, contentMode: .fit)
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Text(Loc.MusicDiscovering.Share.Card.header)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .textCase(.uppercase)
                .opacity(0.9)
            
            if let cefr = data.cefrLevel {
                Text(Loc.MusicDiscovering.Share.Card.cefr(cefr.rawValue.uppercased()))
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Capsule())
            }
        }
    }
    
    private var artworkView: some View {
        Group {
            if let artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 260, height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 12, y: 8)
            } else {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 260, height: 260)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 44, weight: .semibold))
                            
                            Text(Loc.MusicDiscovering.Share.Card.artworkMissing)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .opacity(0.7)
                        }
                        .foregroundStyle(Color.white.opacity(0.85))
                    )
            }
        }
    }
    
    private var songDetails: some View {
        VStack(spacing: 6) {
            Text(data.song.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(2)
            
            Text(Loc.MusicDiscovering.Share.Card.byArtist(data.song.artist))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .opacity(0.85)
                .lineLimit(1)
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                shareStat(title: Loc.MusicDiscovering.Results.Stats.accuracy, value: "\(data.accuracy)%", systemImage: "target")
                shareStat(title: Loc.MusicDiscovering.Results.Stats.newWords, value: "\(data.discoveredWordsCount)", systemImage: "book.closed")
                shareStat(title: Loc.MusicDiscovering.Results.Stats.time, value: data.formattedListeningTime, systemImage: "clock")
            }
            
            if data.totalQuestions > 0 {
                Text(Loc.MusicDiscovering.Share.Card.answered(data.correctAnswers, data.totalQuestions))
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .opacity(0.8)
            }
        }
    }
    
    private func shareStat(title: String, value: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .opacity(0.85)
            
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
            
            Text(title)
                .textCase(.uppercase)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .opacity(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .clippedWithPaddingAndBackground(Color.white.opacity(0.14))
    }
    
    private var footer: some View {
        VStack(spacing: 4) {
            Text(Loc.MusicDiscovering.Share.Card.Footer.tagline)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .opacity(0.7)
            
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(Loc.MusicDiscovering.Share.Card.Footer.brand)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .opacity(0.85)
        }
    }
}

#if DEBUG
struct SongLessonSharePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        let song = Song(
            id: "preview-song",
            title: "Le Festin",
            artist: "Camille",
            album: "Ratatouille",
            albumArtURL: nil,
            duration: 210,
            serviceId: "123",
            cefrLevel: .b1
        )
        let data = SongLessonSharePreviewData(
            song: song,
            accuracy: 92,
            correctAnswers: 11,
            totalQuestions: 12,
            discoveredWordsCount: 5,
            formattedListeningTime: "6:23",
            cefrLevel: song.cefrLevel
        )
        
        SongLessonSharePreviewView(data: data)
    }
}
#endif

