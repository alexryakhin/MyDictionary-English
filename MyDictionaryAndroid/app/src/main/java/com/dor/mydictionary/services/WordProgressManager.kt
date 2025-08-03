package com.dor.mydictionary.services

import android.util.Log
import com.dor.mydictionary.core.WordProgress
import java.util.Date
import java.util.UUID
import javax.inject.Inject

class WordProgressManager @Inject constructor(
    private val storage: LocalWordProgressStorage,
    private val wordManager: WordManager
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
        try {
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
            
            // Calculate accuracy and difficulty score
            val accuracy = if (newTotalAttempts > 0) newCorrectAttempts.toDouble() / newTotalAttempts else 0.0
            val newDifficultyScore = 1.0 - accuracy
            
            // Determine mastery level (matching iOS logic exactly)
            val newMasteryLevel = when {
                accuracy >= 0.9 && newCorrectAttempts > 10 -> "mastered"
                accuracy >= 0.7 -> "inProgress"
                else -> "needsReview"
            }
            
            // Debug logging for mastery
            if (newMasteryLevel == "mastered") {
                Log.d("WordProgressManager", "Word $wordId mastered! accuracy=$accuracy, correctAttempts=$newCorrectAttempts")
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
            
            // Update word difficulty level based on mastery level
            updateWordDifficultyLevel(wordId, newMasteryLevel)
            
        } catch (e: Exception) {
            Log.e("WordProgressManager", "Failed to record quiz attempt: ${e.message}", e)
        }
    }

    private suspend fun updateWordDifficultyLevel(wordId: String, masteryLevel: String) {
        try {
            val word = wordManager.getById(wordId) ?: return
            
            val difficultyLevel = when (masteryLevel) {
                "mastered" -> 3
                "inProgress" -> 1
                "needsReview" -> 2
                else -> 0
            }
            
            wordManager.updateDifficulty(word, difficultyLevel)
            
        } catch (e: Exception) {
            Log.e("WordProgressManager", "Failed to update word difficulty level: ${e.message}", e)
        }
    }

    suspend fun deleteWordProgress(wordProgress: WordProgress) {
        storage.delete(WordProgressEntity.fromWordProgress(wordProgress))
    }

    suspend fun incrementCorrectAnswers(wordId: String) {
        try {
            recordQuizAttempt(wordId, isCorrect = true, responseTime = 0.0)
        } catch (e: Exception) {
            Log.e("WordProgressManager", "Failed to increment correct answers: ${e.message}", e)
        }
    }

    suspend fun incrementIncorrectAnswers(wordId: String) {
        try {
            recordQuizAttempt(wordId, isCorrect = false, responseTime = 0.0)
        } catch (e: Exception) {
            Log.e("WordProgressManager", "Failed to increment incorrect answers: ${e.message}", e)
        }
    }

    suspend fun markAsNeedsReview(wordId: String) {
        try {
            val currentProgress = getByWordId(wordId) ?: createWordProgress(wordId)
            val updatedProgress = currentProgress.copy(
                masteryLevel = "needsReview",
                lastPracticed = Date()
            )
            updateWordProgress(updatedProgress)
            
            // Update word difficulty level to needsReview (level 2)
            val word = wordManager.getById(wordId)
            word?.let { wordManager.updateDifficulty(it, 2) }
            
        } catch (e: Exception) {
            Log.e("WordProgressManager", "Failed to mark word as needs review: ${e.message}", e)
        }
    }
} 