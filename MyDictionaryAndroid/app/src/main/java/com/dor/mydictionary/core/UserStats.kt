package com.dor.mydictionary.core

import java.util.Date

data class UserStats(
    val id: String,
    val averageAccuracy: Double,
    val currentStreak: Int,
    val lastPracticeDate: Date?,
    val longestStreak: Int,
    val totalPracticeTime: Double,
    val totalSessions: Int,
    val totalWordsStudied: Int,
    val vocabularySize: Int,
    val practiceHardWordsOnly: Boolean = false,
    val wordsPerSession: Int = 10,
    val dailyRemindersEnabled: Boolean = false,
    val difficultWordsAlertsEnabled: Boolean = false,
    val selectedTTSLanguage: String = "English (US)"
) 