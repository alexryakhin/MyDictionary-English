package com.dor.mydictionary.services

import com.dor.mydictionary.core.UserStats
import java.util.Date
import java.util.UUID
import javax.inject.Inject

class UserStatsManager @Inject constructor(
    private val storage: LocalUserStatsStorage
) {
    suspend fun getCurrentStats(): UserStats? {
        return storage.getCurrent()?.toUserStats()
    }

    suspend fun createInitialStats(): UserStats {
        val userStats = UserStats(
            id = UUID.randomUUID().toString(),
            averageAccuracy = 0.0,
            currentStreak = 0,
            lastPracticeDate = null,
            longestStreak = 0,
            totalPracticeTime = 0.0,
            totalSessions = 0,
            totalWordsStudied = 0,
            vocabularySize = 0
        )
        
        storage.insert(UserStatsEntity.fromUserStats(userStats))
        return userStats
    }

    suspend fun updateStats(userStats: UserStats) {
        storage.update(UserStatsEntity.fromUserStats(userStats))
    }

    suspend fun updateVocabularySize(newSize: Int) {
        val currentStats = getCurrentStats() ?: createInitialStats()
        val updatedStats = currentStats.copy(vocabularySize = newSize)
        updateStats(updatedStats)
    }

    suspend fun updatePracticeSession(
        accuracy: Double,
        practiceTime: Double,
        wordsStudied: Int
    ) {
        val currentStats = getCurrentStats() ?: createInitialStats()
        
        val newTotalSessions = currentStats.totalSessions + 1
        val newTotalPracticeTime = currentStats.totalPracticeTime + practiceTime
        val newTotalWordsStudied = currentStats.totalWordsStudied + wordsStudied
        
        // Calculate new average accuracy
        val newAverageAccuracy = if (newTotalSessions > 0) {
            ((currentStats.averageAccuracy * currentStats.totalSessions) + accuracy) / newTotalSessions
        } else {
            accuracy
        }
        
        // Update streak logic
        val today = Date()
        val lastPractice = currentStats.lastPracticeDate
        val newCurrentStreak = if (lastPractice != null && isConsecutiveDay(lastPractice, today)) {
            currentStats.currentStreak + 1
        } else {
            1
        }
        
        val newLongestStreak = maxOf(currentStats.longestStreak, newCurrentStreak)
        
        val updatedStats = currentStats.copy(
            averageAccuracy = newAverageAccuracy,
            currentStreak = newCurrentStreak,
            lastPracticeDate = today,
            longestStreak = newLongestStreak,
            totalPracticeTime = newTotalPracticeTime,
            totalSessions = newTotalSessions,
            totalWordsStudied = newTotalWordsStudied
        )
        
        updateStats(updatedStats)
    }

    private fun isConsecutiveDay(lastDate: Date, currentDate: Date): Boolean {
        val diffInMillis = currentDate.time - lastDate.time
        val diffInDays = diffInMillis / (24 * 60 * 60 * 1000)
        return diffInDays <= 1
    }
} 