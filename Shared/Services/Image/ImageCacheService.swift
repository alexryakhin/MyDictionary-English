//
//  ImageCacheService.swift
//  My Dictionary
//
//  Created by Assistant on 11/11/25.
//

import Foundation

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

actor ImageCacheService {
    static let shared = ImageCacheService()

    private let memoryCache = NSCache<NSURL, PlatformImage>()
    private let fileManager: FileManager
    private let diskCacheURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        memoryCache.countLimit = 200
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // ~50 MB

        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let cacheFolderURL = cachesDirectory.appendingPathComponent("ImageCache", isDirectory: true)

        if !fileManager.fileExists(atPath: cacheFolderURL.path) {
            try? fileManager.createDirectory(at: cacheFolderURL, withIntermediateDirectories: true)
        }

        diskCacheURL = cacheFolderURL
    }

    func image(for url: URL) async throws -> PlatformImage {
        let cacheKey = url as NSURL
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return cachedImage
        }

        if let diskImage = loadFromDisk(forKey: url) {
            memoryCache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        guard let image = PlatformImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }

        memoryCache.setObject(image, forKey: cacheKey)
        saveToDisk(data: data, forKey: url)

        return image
    }

    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    private func loadFromDisk(forKey url: URL) -> PlatformImage? {
        let fileURL = cacheFileURL(for: url)
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = PlatformImage(data: data) else {
            return nil
        }

        return image
    }

    private func saveToDisk(data: Data, forKey url: URL) {
        let fileURL = cacheFileURL(for: url)
        try? data.write(to: fileURL, options: [.atomic])
    }

    private func cacheFileURL(for url: URL) -> URL {
        let hash = url.absoluteString.data(using: .utf8)?.sha256Hash ?? UUID().uuidString
        let fileExtension = url.pathExtension.isEmpty ? "dat" : url.pathExtension
        return diskCacheURL.appendingPathComponent("\(hash).\(fileExtension)")
    }
}


