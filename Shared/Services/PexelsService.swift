//
//  PexelsService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 1/8/25.
//

import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Pexels API Models

struct PexelsPhoto: Codable, Identifiable {
    let id: Int
    let width: Int
    let height: Int
    let url: String
    let photographer: String
    let photographerUrl: String
    let photographerId: Int
    let avgColor: String
    let src: PexelsPhotoSource
    let liked: Bool
    let alt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, width, height, url, photographer, liked, alt
        case photographerUrl = "photographer_url"
        case photographerId = "photographer_id"
        case avgColor = "avg_color"
        case src
    }
}

struct PexelsPhotoSource: Codable {
    let original: String
    let large2x: String
    let large: String
    let medium: String
    let small: String
    let portrait: String
    let landscape: String
    let tiny: String
    
    enum CodingKeys: String, CodingKey {
        case original, large, medium, small, portrait, landscape, tiny
        case large2x = "large2x"
    }
}

struct PexelsSearchResponse: Codable {
    let totalResults: Int
    let page: Int
    let perPage: Int
    let photos: [PexelsPhoto]
    let nextPage: String?
    
    enum CodingKeys: String, CodingKey {
        case page, photos
        case totalResults = "total_results"
        case perPage = "per_page"
        case nextPage = "next_page"
    }
}

// MARK: - Pexels Service

final class PexelsService {
    static let shared = PexelsService()
    
    private var apiKey: String {
        GlobalConstant.pexelsAPIKey
    }
    private let baseURL = "https://api.pexels.com/v1"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Image Search
    
    func searchImages(query: String, language: InputLanguage, perPage: Int = 15, orientation: String = "landscape", page: Int = 1) async throws -> PexelsSearchResponse {
        print("🔍 [PexelsService] Starting image search for query: '\(query)' with perPage: \(perPage), orientation: \(orientation)")
        
        guard apiKey.isNotEmpty else {
            print("❌ [PexelsService] API key is not set")
            throw PexelsError.apiKeyNotSet
        }
        
        // Detect language and translate to English if needed
        let searchQuery = await getEnglishSearchQuery(for: query, language: language)
        print("🌍 [PexelsService] Final search query: '\(searchQuery)'")
        
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/search?query=\(encodedQuery)&per_page=\(perPage)&orientation=\(orientation)&page=\(page)"
        
        print("🌐 [PexelsService] Request URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [PexelsService] Invalid URL: \(urlString)")
            throw PexelsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("📡 [PexelsService] Making API request...")
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [PexelsService] Invalid response type")
            throw PexelsError.invalidResponse
        }
        
        print("📊 [PexelsService] HTTP Status Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ [PexelsService] HTTP error: \(httpResponse.statusCode)")
            throw PexelsError.httpError(httpResponse.statusCode)
        }
        
        print("📦 [PexelsService] Response data size: \(data.count) bytes")
        let searchResponse = try JSONDecoder().decode(PexelsSearchResponse.self, from: data)
        print("✅ [PexelsService] Successfully decoded \(searchResponse.photos.count) photos from \(searchResponse.totalResults) total results")
        print("📄 [PexelsService] Current page: \(searchResponse.page), Next page available: \(searchResponse.nextPage != nil)")
        
        return searchResponse
    }
    
    // MARK: - Image Download and Storage
    
    func downloadAndSaveImage(from photo: PexelsPhoto, for word: String) async throws -> String {
        print("📥 [PexelsService] Starting image download for word: '\(word)'")
        print("🖼️ [PexelsService] Photo ID: \(photo.id), Photographer: \(photo.photographer)")
        print("📏 [PexelsService] Photo dimensions: \(photo.width)x\(photo.height)")
        
        // Use medium size for good quality without excessive file size
        let imageURL = photo.src.large
        print("🌐 [PexelsService] Downloading from URL: \(imageURL)")
        
        guard let url = URL(string: imageURL) else {
            print("❌ [PexelsService] Invalid image URL: \(imageURL)")
            throw PexelsError.invalidURL
        }
        
        print("📡 [PexelsService] Making download request...")
        let (data, response) = try await session.data(from: url)
        
        print("📦 [PexelsService] Downloaded data size: \(data.count) bytes")
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("❌ [PexelsService] Download failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw PexelsError.downloadFailed
        }
        
        print("✅ [PexelsService] Download successful, creating UIImage...")
#if os(iOS)
        guard let image = UIImage(data: data) else {
            print("❌ [PexelsService] Failed to create UIImage from downloaded data")
            throw PexelsError.invalidImageData
        }
#elseif os(macOS)
        guard let image = NSImage(data: data) else {
            print("❌ [PexelsService] Failed to create UIImage from downloaded data")
            throw PexelsError.invalidImageData
        }
#endif
        print("🖼️ [PexelsService] UIImage created successfully, size: \(image.size)")
        
        // Compress image to optimize storage
        print("🗜️ [PexelsService] Compressing image with quality 0.8...")
        guard let compressedData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ [PexelsService] Failed to compress image")
            throw PexelsError.compressionFailed
        }
                
        // Generate unique filename
        let filename = "\(word.replacingOccurrences(of: " ", with: "_"))_\(photo.id).jpg"
        print("📝 [PexelsService] Generated filename: \(filename)")
        
        let documentsDir = try getDocumentsDirectory()
        let fileURL = documentsDir.appendingPathComponent(filename)
        print("💾 [PexelsService] Full file path: \(fileURL.path)")
        
        print("💾 [PexelsService] Writing compressed image to disk...")
        try compressedData.write(to: fileURL)
        
        // Verify file was written
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0
            print("✅ [PexelsService] Image saved successfully! File size: \(fileSize) bytes")
        } else {
            print("❌ [PexelsService] File was not created at expected path!")
        }
        
        // Return only the filename, not the full path
        print("📤 [PexelsService] Returning relative filename: \(filename)")
        return filename
    }
    
    func getImageFromLocalPath(_ path: String) -> Image? {
        print("🔍 [PexelsService] Attempting to load image from path: '\(path)'")
        
        // Construct full path from documents directory
        let fullPath: String
        if path.hasPrefix("/") {
            // Absolute path (legacy) - use as is
            fullPath = path
            print("📍 [PexelsService] Using absolute path (legacy): \(fullPath)")
        } else {
            // Relative path - construct from documents directory
            do {
                let documentsDir = try getDocumentsDirectory()
                fullPath = documentsDir.appendingPathComponent(path).path
                print("📍 [PexelsService] Constructed full path from relative: \(fullPath)")
                print("📁 [PexelsService] Documents directory: \(documentsDir.path)")
            } catch {
                print("❌ [PexelsService] Failed to get documents directory: \(error)")
                return nil
            }
        }
        
        let url = URL(fileURLWithPath: fullPath)
        print("🔍 [PexelsService] Checking if file exists at: \(fullPath)")
        
        guard FileManager.default.fileExists(atPath: fullPath) else {
            print("❌ [PexelsService] Image file does not exist at path: \(fullPath)")
            
            // List contents of documents directory for debugging
            do {
                let documentsDir = try getDocumentsDirectory()
                let contents = try FileManager.default.contentsOfDirectory(atPath: documentsDir.path)
                print("📁 [PexelsService] Documents directory contents: \(contents)")
            } catch {
                print("⚠️ [PexelsService] Could not list documents directory contents: \(error)")
            }
            
            return nil
        }
        
        print("✅ [PexelsService] File exists, reading data...")
        guard let data = try? Data(contentsOf: url) else { 
            print("❌ [PexelsService] Failed to read image data from path: \(fullPath)")
            return nil 
        }
        
        print("📦 [PexelsService] Read \(data.count) bytes from file")
#if os(iOS)
        guard let image = UIImage(data: data) else {
            print("❌ [PexelsService] Failed to create UIImage from data at path: \(fullPath)")
            return nil
        }
#elseif os(macOS)
        guard let image = NSImage(data: data) else {
            print("❌ [PexelsService] Failed to create UIImage from data at path: \(fullPath)")
            return nil
        }
#endif

        print("✅ [PexelsService] Successfully loaded image from path: \(fullPath)")
        print("🖼️ [PexelsService] Image size: \(image.size)")
#if os(iOS)
        return Image(uiImage: image)
#elseif os(macOS)
        return Image(nsImage: image)
#endif
    }
    
    // MARK: - Fallback Image Loading
    
    func getImageWithFallback(localPath: String, webUrl: String?) async -> (image: Image?, newLocalPath: String?) {
        print("🔄 [PexelsService] Starting fallback image loading...")
        print("📍 [PexelsService] Local path: '\(localPath)'")
        print("🌐 [PexelsService] Web URL: '\(webUrl ?? "nil")'")
        
        // First, try to load from local path
        if let localImage = getImageFromLocalPath(localPath) {
            print("✅ [PexelsService] Successfully loaded from local path")
            return (localImage, nil) // No new path needed
        }
        
        print("⚠️ [PexelsService] Local loading failed, attempting web fallback...")
        
        // If local fails and we have a web URL, try to re-download
        guard let webUrl = webUrl, !webUrl.isEmpty else {
            print("❌ [PexelsService] No web URL available for fallback")
            return (nil, nil)
        }
        
        do {
            print("📥 [PexelsService] Attempting to re-download from web URL...")
            let reDownloadedImage = try await downloadImageFromUrl(webUrl)
            #if os(iOS)
            let image = Image(uiImage: reDownloadedImage)
            #elseif os(macOS)
            let image = Image(nsImage: reDownloadedImage)
            #endif

            // Extract filename from the path (handle both absolute and relative paths)
            let filename: String
            if localPath.hasPrefix("/") {
                // Absolute path - extract just the filename
                filename = URL(fileURLWithPath: localPath).lastPathComponent
                print("📝 [PexelsService] Extracted filename from absolute path: \(filename)")
            } else {
                // Relative path - use as is
                filename = localPath
                print("📝 [PexelsService] Using relative path as filename: \(filename)")
            }
            
            // Try to save it locally with the extracted filename
            if let imageData = reDownloadedImage.jpegData(compressionQuality: 0.8) {
                let documentsDir = try getDocumentsDirectory()
                let fileURL = documentsDir.appendingPathComponent(filename)
                
                try imageData.write(to: fileURL)
                print("💾 [PexelsService] Re-downloaded image saved locally: \(fileURL.path)")
                
                // Verify the file was saved
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0
                    print("✅ [PexelsService] Fallback successful! File size: \(fileSize) bytes")
                    print("📝 [PexelsService] New relative path: \(filename)")
                    return (image, filename) // Return image and new path
                } else {
                    print("❌ [PexelsService] Failed to save re-downloaded image")
                    return (image, nil) // Return the image even if saving failed
                }
            } else {
                print("❌ [PexelsService] Failed to compress re-downloaded image")
                return (image, nil) // Return the image even if compression failed
            }
        } catch {
            print("❌ [PexelsService] Fallback download failed: \(error.localizedDescription)")
            return (nil, nil)
        }
    }

#if os(iOS)
    private func downloadImageFromUrl(_ urlString: String) async throws -> UIImage {
        print("🌐 [PexelsService] Downloading image from: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ [PexelsService] Invalid URL: \(urlString)")
            throw PexelsError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("❌ [PexelsService] Download failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw PexelsError.downloadFailed
        }

        print("📦 [PexelsService] Downloaded \(data.count) bytes from web URL")

        guard let image = UIImage(data: data) else {
            print("❌ [PexelsService] Failed to create UIImage from web data")
            throw PexelsError.invalidImageData
        }

        print("✅ [PexelsService] Successfully created UIImage from web URL")
        print("🖼️ [PexelsService] Image size: \(image.size)")
        return image
    }
#elseif os(macOS)
    private func downloadImageFromUrl(_ urlString: String) async throws -> NSImage {
        print("🌐 [PexelsService] Downloading image from: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ [PexelsService] Invalid URL: \(urlString)")
            throw PexelsError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("❌ [PexelsService] Download failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw PexelsError.downloadFailed
        }

        print("📦 [PexelsService] Downloaded \(data.count) bytes from web URL")

        guard let image = NSImage(data: data) else {
            print("❌ [PexelsService] Failed to create UIImage from web data")
            throw PexelsError.invalidImageData
        }

        print("✅ [PexelsService] Successfully created UIImage from web URL")
        print("🖼️ [PexelsService] Image size: \(image.size)")
        return image
    }
#endif

    func deleteImage(at path: String) throws {
        print("🗑️ [PexelsService] Attempting to delete image at path: '\(path)'")
        
        // Construct full path from documents directory
        let fullPath: String
        if path.hasPrefix("/") {
            // Absolute path (legacy) - use as is
            fullPath = path
            print("📍 [PexelsService] Using absolute path (legacy): \(fullPath)")
        } else {
            // Relative path - construct from documents directory
            let documentsDir = try getDocumentsDirectory()
            fullPath = documentsDir.appendingPathComponent(path).path
            print("📍 [PexelsService] Constructed full path from relative: \(fullPath)")
        }
        
        let url = URL(fileURLWithPath: fullPath)
        
        // Check if file exists before attempting to delete
        if FileManager.default.fileExists(atPath: fullPath) {
            print("✅ [PexelsService] File exists, proceeding with deletion...")
            try FileManager.default.removeItem(at: url)
            print("✅ [PexelsService] Successfully deleted image at: \(fullPath)")
        } else {
            print("⚠️ [PexelsService] File does not exist at path: \(fullPath), skipping deletion")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getDocumentsDirectory() throws -> URL {
        print("📁 [PexelsService] Getting documents directory...")
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsDirectory = paths.first else {
            print("❌ [PexelsService] Documents directory not found")
            throw PexelsError.documentsDirectoryNotFound
        }
        print("📁 [PexelsService] Documents directory: \(documentsDirectory.path)")
        return documentsDirectory
    }

    private func getEnglishSearchQuery(for query: String, language: InputLanguage) async -> String {

        // If it's already English, use the original query
        guard language != .english else {
            print("🌍 [PexelsService] Query is already in English: '\(query)'")
            return query
        }

        do {
            let translationResponse = try await GoogleTranslateService.shared.translateFromLanguage(query, from: language.rawValue)
            print("🌍 [PexelsService] Translated '\(query)' to '\(translationResponse.text)'")
            return translationResponse.text
        } catch {
            print("⚠️ [PexelsService] Translation failed, using original query: \(error)")
            return query
        }
    }
}

// MARK: - Pexels Errors

enum PexelsError: LocalizedError {
    case apiKeyNotSet
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case downloadFailed
    case invalidImageData
    case compressionFailed
    case documentsDirectoryNotFound
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotSet:
            return "Pexels API key is not configured"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .downloadFailed:
            return "Failed to download image"
        case .invalidImageData:
            return "Invalid image data"
        case .compressionFailed:
            return "Failed to compress image"
        case .documentsDirectoryNotFound:
            return "Documents directory not found"
        }
    }
}

#if os(macOS)
extension NSImage {
    func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        return bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: compressionQuality]
        )
    }
}
#endif
