package com.dor.mydictionary.services

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.dor.mydictionary.core.WordProgress
import java.util.Date

@Entity(tableName = "word_progress")
data class WordProgressEntity(
    @PrimaryKey val id: String,
    val wordId: String,
    val averageResponseTime: Double,
    val consecutiveCorrect: Int,
    val correctAttempts: Int,
    val difficultyScore: Double,
    val lastPracticed: Date?,
    val masteryLevel: String,
    val totalAttempts: Int
) {
    fun toWordProgress(): WordProgress = WordProgress(
        id = id,
        wordId = wordId,
        averageResponseTime = averageResponseTime,
        consecutiveCorrect = consecutiveCorrect,
        correctAttempts = correctAttempts,
        difficultyScore = difficultyScore,
        lastPracticed = lastPracticed,
        masteryLevel = masteryLevel,
        totalAttempts = totalAttempts
    )
    
    companion object {
        fun fromWordProgress(wordProgress: WordProgress): WordProgressEntity = WordProgressEntity(
            id = wordProgress.id,
            wordId = wordProgress.wordId,
            averageResponseTime = wordProgress.averageResponseTime,
            consecutiveCorrect = wordProgress.consecutiveCorrect,
            correctAttempts = wordProgress.correctAttempts,
            difficultyScore = wordProgress.difficultyScore,
            lastPracticed = wordProgress.lastPracticed,
            masteryLevel = wordProgress.masteryLevel,
            totalAttempts = wordProgress.totalAttempts
        )
    }
} 