package com.dor.mydictionary.core

import java.util.Date

data class WordProgress(
    val id: String,
    val wordId: String,
    val averageResponseTime: Double,
    val consecutiveCorrect: Int,
    val correctAttempts: Int,
    val difficultyScore: Double,
    val lastPracticed: Date?,
    val masteryLevel: String,
    val totalAttempts: Int
) 