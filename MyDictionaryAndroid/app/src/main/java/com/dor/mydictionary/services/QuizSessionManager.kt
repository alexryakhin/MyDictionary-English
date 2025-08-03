package com.dor.mydictionary.services

import com.dor.mydictionary.core.QuizSession
import java.util.Date
import java.util.UUID
import javax.inject.Inject

class QuizSessionManager @Inject constructor(
    private val storage: LocalQuizSessionStorage,
    private val userStatsManager: UserStatsManager
) {
    suspend fun getAllQuizSessions(): List<QuizSession> {
        return storage.getAll().map { it.toQuizSession() }
    }

    suspend fun getById(id: String): QuizSession? {
        return storage.getById(id)?.toQuizSession()
    }

    suspend fun getByQuizType(quizType: String): List<QuizSession> {
        return storage.getByQuizType(quizType).map { it.toQuizSession() }
    }

    suspend fun getFromDate(startDate: Date): List<QuizSession> {
        return storage.getFromDate(startDate).map { it.toQuizSession() }
    }

    suspend fun saveQuizSession(
        quizType: String,
        score: Int,
        totalWords: Int,
        correctAnswers: Int,
        accuracy: Double,
        duration: Double,
        wordsPracticed: List<String>
    ): QuizSession {
        val quizSession = QuizSession(
            id = UUID.randomUUID().toString(),
            quizType = quizType,
            date = Date(),
            score = score,
            totalWords = totalWords,
            correctAnswers = correctAnswers,
            accuracy = accuracy,
            duration = duration,
            wordsPracticed = wordsPracticed
        )
        
        storage.insert(QuizSessionEntity.fromQuizSession(quizSession))
        
        // Update user stats with this practice session
        userStatsManager.updatePracticeSession(
            accuracy = accuracy,
            practiceTime = duration,
            wordsStudied = totalWords
        )
        
        return quizSession
    }

    suspend fun deleteQuizSession(quizSession: QuizSession) {
        storage.delete(QuizSessionEntity.fromQuizSession(quizSession))
    }

    suspend fun getRecentSessions(limit: Int): List<QuizSession> {
        return storage.getRecent(limit).map { it.toQuizSession() }
    }

    suspend fun saveQuizSession(
        id: String,
        quizType: String,
        totalQuestions: Int,
        correctAnswers: Int,
        timestamp: Date,
        duration: Double = 0.0,
        accuracy: Double? = null,
        score: Int = 0
    ): QuizSession {
        val calculatedAccuracy = accuracy ?: if (totalQuestions > 0) correctAnswers.toDouble() / totalQuestions else 0.0
        
        // Debug logging
        android.util.Log.d("QuizSessionManager", "Saving quiz session: accuracy=$calculatedAccuracy, totalQuestions=$totalQuestions, correctAnswers=$correctAnswers, score=$score")
        
        val quizSession = QuizSession(
            id = id,
            quizType = quizType,
            date = timestamp,
            score = score, // Use actual score
            totalWords = totalQuestions,
            correctAnswers = correctAnswers,
            accuracy = calculatedAccuracy,
            duration = duration,
            wordsPracticed = emptyList()
        )
        
        storage.insert(QuizSessionEntity.fromQuizSession(quizSession))
        
        // Update user stats with this practice session
        userStatsManager.updatePracticeSession(
            accuracy = calculatedAccuracy,
            practiceTime = duration,
            wordsStudied = totalQuestions
        )
        
        return quizSession
    }
} 