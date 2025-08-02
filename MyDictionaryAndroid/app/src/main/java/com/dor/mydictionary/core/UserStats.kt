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
    val vocabularySize: Int
) 