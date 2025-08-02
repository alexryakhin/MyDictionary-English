package com.dor.mydictionary.services

import com.dor.mydictionary.core.WordProgress
import java.util.Date
import java.util.UUID
import javax.inject.Inject

class WordProgressManager @Inject constructor(
    private val storage: LocalWordProgressStorage
) {
    suspend fun getAllWordProgress(): List<WordProgress> {
        return storage.getAll().map { it.toWordProgress() }
    }

    suspend fun getByWordId(wordId: String): WordProgress? {
        return storage.getByWordId(wordId)?.toWordProgress()
    }

    suspend fun getByMasteryLevel(masteryLevel: String): List<WordProgress> {
        return storage.getByMasteryLevel(masteryLevel).map { it.toWordProgress() }
    }

    suspend fun createWordProgress(wordId: String): WordProgress {
        val wordProgress = WordProgress(
            id = UUID.randomUUID().toString(),
            wordId = wordId,
            averageResponseTime = 0.0,
            consecutiveCorrect = 0,
            correctAttempts = 0,
            difficultyScore = 0.0,
            lastPracticed = null,
            masteryLevel = "new",
            totalAttempts = 0
        )
        
        storage.insert(WordProgressEntity.fromWordProgress(wordProgress))
        return wordProgress
    }

    suspend fun updateWordProgress(wordProgress: WordProgress) {
        storage.update(WordProgressEntity.fromWordProgress(wordProgress))
    }

    suspend fun recordQuizAttempt(
        wordId: String,
        isCorrect: Boolean,
        responseTime: Double
    ) {
        val currentProgress = getByWordId(wordId) ?: createWordProgress(wordId)
        
        val newTotalAttempts = currentProgress.totalAttempts + 1
        val newCorrectAttempts = if (isCorrect) currentProgress.correctAttempts + 1 else currentProgress.correctAttempts
        val newConsecutiveCorrect = if (isCorrect) currentProgress.consecutiveCorrect + 1 else 0
        
        // Calculate new average response time
        val newAverageResponseTime = if (newTotalAttempts > 0) {
            ((currentProgress.averageResponseTime * currentProgress.totalAttempts) + responseTime) / newTotalAttempts
        } else {
            responseTime
        }
        
        // Calculate difficulty score (0.0 to 1.0, higher = more difficult)
        val accuracy = if (newTotalAttempts > 0) newCorrectAttempts.toDouble() / newTotalAttempts else 0.0
        val newDifficultyScore = 1.0 - accuracy
        
        // Determine mastery level
        val newMasteryLevel = when {
            accuracy >= 0.9 && newConsecutiveCorrect >= 5 -> "mastered"
            accuracy >= 0.7 -> "inProgress"
            accuracy < 0.5 -> "needsReview"
            else -> "new"
        }
        
        val updatedProgress = currentProgress.copy(
            averageResponseTime = newAverageResponseTime,
            consecutiveCorrect = newConsecutiveCorrect,
            correctAttempts = newCorrectAttempts,
            difficultyScore = newDifficultyScore,
            lastPracticed = Date(),
            masteryLevel = newMasteryLevel,
            totalAttempts = newTotalAttempts
        )
        
        updateWordProgress(updatedProgress)
    }

    suspend fun deleteWordProgress(wordProgress: WordProgress) {
        storage.delete(WordProgressEntity.fromWordProgress(wordProgress))
    }

    suspend fun incrementCorrectAnswers(wordId: String) {
        recordQuizAttempt(wordId, isCorrect = true, responseTime = 0.0)
    }

    suspend fun incrementIncorrectAnswers(wordId: String) {
        recordQuizAttempt(wordId, isCorrect = false, responseTime = 0.0)
    }

    suspend fun markAsNeedsReview(wordId: String) {
        val currentProgress = getByWordId(wordId) ?: createWordProgress(wordId)
        val updatedProgress = currentProgress.copy(
            masteryLevel = "needsReview",
            lastPracticed = Date()
        )
        updateWordProgress(updatedProgress)
    }
} 