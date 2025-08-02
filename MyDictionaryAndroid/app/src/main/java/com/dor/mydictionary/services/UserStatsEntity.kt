package com.dor.mydictionary.services

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.dor.mydictionary.core.UserStats
import java.util.Date

@Entity(tableName = "user_stats")
data class UserStatsEntity(
    @PrimaryKey val id: String,
    val averageAccuracy: Double,
    val currentStreak: Int,
    val lastPracticeDate: Date?,
    val longestStreak: Int,
    val totalPracticeTime: Double,
    val totalSessions: Int,
    val totalWordsStudied: Int,
    val vocabularySize: Int,
    val practiceHardWordsOnly: Boolean = false,
    val wordsPerSession: Int = 10
) {
    fun toUserStats(): UserStats = UserStats(
        id = id,
        averageAccuracy = averageAccuracy,
        currentStreak = currentStreak,
        lastPracticeDate = lastPracticeDate,
        longestStreak = longestStreak,
        totalPracticeTime = totalPracticeTime,
        totalSessions = totalSessions,
        totalWordsStudied = totalWordsStudied,
        vocabularySize = vocabularySize,
        practiceHardWordsOnly = practiceHardWordsOnly,
        wordsPerSession = wordsPerSession
    )
    
    companion object {
        fun fromUserStats(userStats: UserStats): UserStatsEntity = UserStatsEntity(
            id = userStats.id,
            averageAccuracy = userStats.averageAccuracy,
            currentStreak = userStats.currentStreak,
            lastPracticeDate = userStats.lastPracticeDate,
            longestStreak = userStats.longestStreak,
            totalPracticeTime = userStats.totalPracticeTime,
            totalSessions = userStats.totalSessions,
            totalWordsStudied = userStats.totalWordsStudied,
            vocabularySize = userStats.vocabularySize,
            practiceHardWordsOnly = userStats.practiceHardWordsOnly,
            wordsPerSession = userStats.wordsPerSession
        )
    }
} 