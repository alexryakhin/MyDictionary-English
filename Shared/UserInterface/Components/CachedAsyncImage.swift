//
//  CachedAsyncImage.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View, Failure: View>: View {
    private let url: URL?
    private let transaction: Transaction
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    private let failure: (Error) -> Failure

    @State private var phase: Phase = .empty

    init(
        url: URL?,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder failure: @escaping (Error) -> Failure = { _ in EmptyView() }
    ) {
        self.url = url
        self.transaction = transaction
        self.content = content
        self.placeholder = placeholder
        self.failure = failure
    }

    init(
        url: URL?,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) where Failure == EmptyView {
        self.init(url: url, transaction: transaction, content: content, placeholder: placeholder, failure: { _ in EmptyView() })
    }

    var body: some View {
        Group {
            switch phase {
            case .empty:
                placeholder()
            case .success(let image):
                content(image)
            case .failure(let error):
                failure(error)
            }
        }
        .animation(transaction.animation, value: phase)
        .task(id: url) {
            await loadImage()
        }
    }
}

extension CachedAsyncImage {
    enum Phase: Equatable {
        case empty
        case success(Image)
        case failure(Error)

        static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
            case (.empty, .empty):
                return true
            case (.success, .success):
                return true
            case (.failure, .failure):
                return true
            default:
                return false
            }
        }
    }
}

private extension CachedAsyncImage {
    func loadImage() async {
        guard let url else {
            await MainActor.run {
                phase = .empty
            }
            return
        }

        await MainActor.run {
            phase = .empty
        }

        do {
            let platformImage = try await ImageCacheService.shared.image(for: url)
            guard !Task.isCancelled else { return }
            let image = Image(platformImage: platformImage)
            await MainActor.run {
                phase = .success(image)
            }
        } catch {
            guard !Task.isCancelled else { return }
            await MainActor.run {
                phase = .failure(error)
            }
        }
    }
}

#if canImport(UIKit)
private extension Image {
    init(platformImage: PlatformImage) {
        self = Image(uiImage: platformImage)
    }
}
#elseif canImport(AppKit)
private extension Image {
    init(platformImage: PlatformImage) {
        self = Image(nsImage: platformImage)
    }
}
#endif

extension CachedAsyncImage where Placeholder == EmptyView {
    init(
        url: URL?,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content
    ) where Failure == EmptyView {
        self.init(
            url: url,
            transaction: transaction,
            content: content,
            placeholder: { EmptyView() },
            failure: { _ in EmptyView() }
        )
    }
}


