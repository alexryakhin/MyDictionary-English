//
//  MusicListeningHistoryService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

@MainActor
final class MusicListeningHistoryService {
    static let shared = MusicListeningHistoryService()
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "music_listening_history"
    private let maxHistoryItems = 100
    
    private init() {}
    
    // MARK: - History Management
    
    func getHistory() async -> [MusicListeningHistory] {
        guard let data = userDefaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([MusicListeningHistory].self, from: data) else {
            return []
        }
        
        // Sort by most recent first
        return history.sorted { $0.listenedAt > $1.listenedAt }
    }
    
    func addToHistory(song: Song, listeningDuration: TimeInterval = 0, completed: Bool = false) async {
        var history = await getHistory()
        
        // Check if song already exists in history
        if let existingIndex = history.firstIndex(where: { $0.song.id == song.id }) {
            var existing = history[existingIndex]
            existing.incrementPlayCount()
            existing.updateListeningDuration(listeningDuration)
            existing.updatePosition(0) // Reset position for new play
            if completed {
                existing.markCompleted()
            }
            existing = MusicListeningHistory(
                id: existing.id,
                song: existing.song,
                listenedAt: Date(), // Update to current time
                listeningDuration: existing.listeningDuration,
                playCount: existing.playCount,
                completed: existing.completed,
                lastPosition: existing.lastPosition
            )
            history.remove(at: existingIndex)
            history.insert(existing, at: 0) // Move to top
        } else {
            // Add new entry
            let newEntry = MusicListeningHistory(
                song: song,
                listeningDuration: listeningDuration,
                playCount: 1,
                completed: completed,
                lastPosition: 0
            )
            history.insert(newEntry, at: 0)
        }
        
        // Limit history size
        if history.count > maxHistoryItems {
            history = Array(history.prefix(maxHistoryItems))
        }
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
    
    func updateHistory(songId: String, listeningDuration: TimeInterval, completed: Bool, position: TimeInterval) async {
        var history = await getHistory()
        
        guard let index = history.firstIndex(where: { $0.song.id == songId }) else {
            return
        }
        
        var entry = history[index]
        entry.updateListeningDuration(listeningDuration)
        entry.updatePosition(position)
        if completed {
            entry.markCompleted()
        }
        
        history[index] = entry
        
        // Save
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
    
    func removeFromHistory(_ historyEntry: MusicListeningHistory) async {
        var history = await getHistory()
        history.removeAll { $0.id == historyEntry.id }
        
        // Save
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
    
    func clearHistory() async {
        userDefaults.removeObject(forKey: historyKey)
    }
    
    func getHistoryForSong(_ songId: String) async -> MusicListeningHistory? {
        let history = await getHistory()
        return history.first { $0.song.id == songId }
    }
}

