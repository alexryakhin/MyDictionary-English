//
//  MusicRecommendationService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import FirebaseFirestore

/// Service for managing music recommendations with Firestore caching
/// Path: recommendationItems/{language.rawValue}/{cefrLevel}
final class MusicRecommendationService {
    
    static let shared = MusicRecommendationService()
    
    private let db = Firestore.firestore()
    private let aiService = AIService.shared
    private let appleMusicService = AppleMusicService.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Get recommendations for all CEFR levels (2 random songs per level, 12 total)
    /// - Parameters:
    ///   - language: InputLanguage
    ///   - userProfile: User profile for AI generation if needed
    /// - Returns: Array of RecommendationSong (2 per CEFR level, 12 total)
    func getAllLevelRecommendations(language: InputLanguage, userProfile: UserOnboardingProfile) async throws -> [RecommendationSong] {
        let allLevels = CEFRLevel.allCases
        var allSongs: [RecommendationSong] = []
        
        // Try to get 2 random songs per level from Firestore
        for level in allLevels {
            // Try to get recommendations from Firestore
            if let recommendation = try? await getRecommendations(language: language, cefrLevel: level) {
                // Get 2 random songs from this level's recommendations
                // All songs in this recommendation should already have the correct CEFR level
                let randomSongs = Array(recommendation.songs.shuffled().prefix(2))
                allSongs.append(contentsOf: randomSongs)
                print("✅ [MusicRecommendationService] Found \(randomSongs.count) songs for \(level.rawValue) in Firestore")
            }
        }
        
        // If we don't have enough songs (less than 12), generate all levels with AI
        if allSongs.count < 12 {
            print("⚠️ [MusicRecommendationService] Only found \(allSongs.count) songs, generating recommendations for all levels with AI...")
            
            do {
                // Generate all 12 songs (2 per level) with a single AI request
                // We just need to call it once with any level - it generates all levels
                let _ = try await generateRecommendationsWithAI(
                    language: language,
                    cefrLevel: .a1, // Placeholder - AI generates for all levels
                    userProfile: userProfile,
                    count: 12 // Request 12 songs (2 per level)
                )
                
                // Fetch all songs again from Firestore after AI generation
                allSongs = []
                for level in allLevels {
                    if let recommendation = try? await getRecommendations(language: language, cefrLevel: level) {
                        let randomSongs = Array(recommendation.songs.shuffled().prefix(2))
                        allSongs.append(contentsOf: randomSongs)
                        print("✅ [MusicRecommendationService] Loaded \(randomSongs.count) songs for \(level.rawValue) after AI generation")
                    }
                }
            } catch {
                print("⚠️ [MusicRecommendationService] AI generation failed: \(error.localizedDescription)")
            }
        }
        
        // Shuffle all songs to mix levels
        let shuffledSongs = allSongs.shuffled()
        print("✅ [MusicRecommendationService] Returning \(shuffledSongs.count) total recommendations (target: 12)")
        return shuffledSongs
    }
    
    /// Get recommendations from Firestore cache
    /// Path: recommendationSongs/{language.englishName.lowercased()}/{cefrLevel}
    /// - Parameters:
    ///   - language: InputLanguage
    ///   - cefrLevel: CEFR level enum
    /// - Returns: FirestoreRecommendation if found, nil otherwise
    func getRecommendations(language: InputLanguage, cefrLevel: CEFRLevel) async throws -> FirestoreRecommendation? {
        let languagePath = language.englishName.lowercased()
        let docRef = db.collection("recommendationSongs")
            .document(languagePath)
            .collection(cefrLevel.rawValue)
            .document("recommendations")
        
        print("📥 [MusicRecommendationService] Fetching from Firestore: recommendationSongs/\(languagePath)/\(cefrLevel)/recommendations")

        let document = try await docRef.getDocument()
        
        guard document.exists else {
            print("ℹ️ [MusicRecommendationService] Document does not exist in Firestore")
            return nil
        }
        
        guard let data = document.data() else {
            print("⚠️ [MusicRecommendationService] Document exists but has no data")
            return nil
        }
        
        print("✅ [MusicRecommendationService] Found document in Firestore")
        
        // Convert Firestore Timestamp to ISO8601 string before serialization
        var convertedData = data
        if let timestamp = data["generated_at"] as? Timestamp {
            let date = timestamp.dateValue()
            let formatter = ISO8601DateFormatter()
            convertedData["generated_at"] = formatter.string(from: date)
        }
        
        // Convert Firestore data to FirestoreRecommendation
        let jsonData = try JSONSerialization.data(withJSONObject: convertedData)
        let decoder = JSONDecoder()
        
        // Handle Date decoding from ISO8601 string
        decoder.dateDecodingStrategy = .iso8601
        
        let recommendation = try decoder.decode(FirestoreRecommendation.self, from: jsonData)
        return recommendation
    }
    
    /// Save recommendations to Firestore
    /// Path: recommendationSongs/{language.englishName.lowercased()}/{cefrLevel}
    /// - Parameters:
    ///   - recommendation: The recommendation to save (only songs)
    ///   - language: InputLanguage
    ///   - cefrLevel: CEFR level enum
    func saveRecommendations(_ recommendation: FirestoreRecommendation, language: InputLanguage, cefrLevel: CEFRLevel) async throws {
        let languagePath = language.englishName.lowercased()
        let docRef = db.collection("recommendationSongs")
            .document(languagePath)
            .collection(cefrLevel.rawValue)
            .document("recommendations")
        
        // Convert to dictionary for Firestore
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(recommendation)
        var dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
        
        // Convert Date to Timestamp
        dictionary["generated_at"] = Timestamp(date: recommendation.generatedAt)
        
        print("💾 [MusicRecommendationService] Writing to Firestore document...")
        try await docRef.setData(dictionary, merge: false)
        print("✅ [MusicRecommendationService] Successfully wrote to Firestore: recommendationSongs/\(languagePath)/\(cefrLevel)/recommendations")
    }
    
    /// Generate recommendations using OpenAI
    /// - Parameters:
    ///   - language: InputLanguage
    ///   - cefrLevel: CEFR level enum (used for return value only, AI generates all levels)
    ///   - userProfile: User profile for personalization
    ///   - count: Number of songs to generate (default: 12 - 2 per level)
    /// - Returns: FirestoreRecommendation for requested level (after generating all)
    func generateRecommendationsWithAI(language: InputLanguage, cefrLevel: CEFRLevel, userProfile: UserOnboardingProfile, count: Int = 12) async throws -> FirestoreRecommendation {
        print("🤖 [MusicRecommendationService] Starting OpenAI recommendation generation for all CEFR levels...")
        
        guard aiService.canMakeAIRequest() else {
            print("❌ [MusicRecommendationService] AI request not allowed (Pro required)")
            throw AIError.proRequired
        }
        
        print("🤖 [MusicRecommendationService] Making OpenAI request for \(language.englishName) (all levels)...")
        print("🤖 [MusicRecommendationService] Request details - User: \(userProfile.userName), Languages: \(userProfile.studyLanguages.map { $0.language.rawValue }.joined(separator: ", "))")
        
        // Request AI recommendations
        let aiResponse: AIMusicRecommendationsResponse
        do {
            aiResponse = try await aiService.request(
                .musicRecommendations(
                    language: language,
                    userProfile: userProfile
                )
            )
            print("✅ [MusicRecommendationService] Received response from OpenAI: \(aiResponse.songs.count) songs across all CEFR levels")
        } catch {
            print("❌ [MusicRecommendationService] OpenAI request failed with error: \(error)")
            print("❌ [MusicRecommendationService] Error type: \(type(of: error))")
            print("❌ [MusicRecommendationService] Error description: \(error.localizedDescription)")
            throw error // Re-throw to let caller handle
        }
        
        // Convert AI response to songs by searching Apple Music
        print("🔄 [MusicRecommendationService] Converting AI response to actual songs...")
        print("🔍 [MusicRecommendationService] Searching Apple Music for actual songs...")
        let allSongs = try await convertAIRecommendationsToSongs(aiResponse)
        
        // Group songs by CEFR level and save to Firestore
        let songsByLevel = Dictionary(grouping: allSongs, by: { $0.cefrLevel })
        
        print("💾 [MusicRecommendationService] Saving \(allSongs.count) songs to Firestore across \(songsByLevel.count) CEFR levels...")
        
        for (cefrLevel, songs) in songsByLevel {
            let recommendation = FirestoreRecommendation(
                languageCode: language.rawValue,
                cefrLevel: cefrLevel,
                songs: songs,
                generatedAt: Date(),
                version: 1
            )
            
            try await saveRecommendations(recommendation, language: language, cefrLevel: cefrLevel)
            print("✅ [MusicRecommendationService] Saved \(songs.count) songs for \(cefrLevel.rawValue)")
        }
        
        // Return recommendation for requested CEFR level
        if let songsForLevel = songsByLevel[cefrLevel] {
            return FirestoreRecommendation(
                languageCode: language.rawValue,
                cefrLevel: cefrLevel,
                songs: songsForLevel,
                generatedAt: Date(),
                version: 1
            )
        } else {
            // Fallback: return first available level's recommendation
            if let firstLevel = songsByLevel.keys.first,
               let songs = songsByLevel[firstLevel] {
                return FirestoreRecommendation(
                    languageCode: language.rawValue,
                    cefrLevel: firstLevel,
                    songs: songs,
                    generatedAt: Date(),
                    version: 1
                )
            }
            throw MusicError.noRecommendationsAvailable
        }
    }
    
    /// Generate recommendations using Apple Music search (fallback)
    /// - Parameters:
    ///   - language: InputLanguage
    ///   - cefrLevel: CEFR level enum
    /// - Returns: FirestoreRecommendation generated from search
    func generateRecommendationsWithSearch(language: InputLanguage, cefrLevel: CEFRLevel) async throws -> FirestoreRecommendation {
        guard appleMusicService.isAuthorized else {
            throw MusicError.authenticationRequired
        }
        
        // Search for popular songs in the language
        let songs = try await appleMusicService.searchSongs(query: language.englishName, language: language.englishName)

        // Convert to FirestoreRecommendation format with cefrLevel and appleMusicId
        let recommendationSongs = Array(songs.prefix(20)).map { song in
            RecommendationSong(
                title: song.title,
                artist: song.artist,
                cefrLevel: cefrLevel,
                appleMusicId: song.serviceId.isEmpty ? nil : song.serviceId,
                reason: "Popular song in \(language.englishName)"
            )
        }
        
        let recommendation = FirestoreRecommendation(
            languageCode: language.rawValue,
            cefrLevel: cefrLevel,
            songs: recommendationSongs,
            generatedAt: Date(),
            version: 1
        )
        
        print("💾 [MusicRecommendationService] Saving search-based recommendations to Firestore...")
        // Save to Firestore for future cache hits
        try? await saveRecommendations(recommendation, language: language, cefrLevel: cefrLevel)
        print("✅ [MusicRecommendationService] Saved search-based recommendations for \(language.englishName)/\(cefrLevel)")
        
        return recommendation
    }
    
    // MARK: - Private Methods
    
    /// Convert AI recommendations to actual songs by searching Apple Music
    /// Searches for songs from AI recommendations and includes cefrLevel from AI and appleMusicId
    private func convertAIRecommendationsToSongs(_ aiResponse: AIMusicRecommendationsResponse) async throws -> [RecommendationSong] {
        guard appleMusicService.isAuthorized else {
            throw MusicError.authenticationRequired
        }
        
        var allSongs: [RecommendationSong] = []
        
        // Search for song recommendations from AI
        for aiSong in aiResponse.songs {
            do {
                let query = "\(aiSong.title) \(aiSong.artist)"
                let songs = try await appleMusicService.searchSongs(query: query, language: nil)
                if let foundSong = songs.first(where: {
                    $0.title.lowercased().contains(aiSong.title.lowercased()) &&
                    $0.artist.lowercased().contains(aiSong.artist.lowercased())
                }) ?? songs.first {
                    allSongs.append(RecommendationSong(
                        title: foundSong.title,
                        artist: foundSong.artist,
                        cefrLevel: aiSong.cefrLevel, // Use CEFR level from AI
                        appleMusicId: foundSong.serviceId.isEmpty ? nil : foundSong.serviceId,
                        reason: aiSong.reason
                    ))
                    print("✅ [MusicRecommendationService] Found song: \(foundSong.title) (\(aiSong.cefrLevel.rawValue))")
                }
            } catch {
                print("⚠️ [MusicRecommendationService] Failed to find song \(aiSong.title): \(error)")
            }
        }
        
        // Remove duplicates
        var uniqueSongs: [RecommendationSong] = []
        var seen = Set<String>()
        for song in allSongs {
            let key = "\(song.title.lowercased())-\(song.artist.lowercased())"
            if !seen.contains(key) {
                uniqueSongs.append(song)
                seen.insert(key)
            }
        }
        
        print("✅ [MusicRecommendationService] Converted to \(uniqueSongs.count) unique songs")
        return uniqueSongs
    }
}
