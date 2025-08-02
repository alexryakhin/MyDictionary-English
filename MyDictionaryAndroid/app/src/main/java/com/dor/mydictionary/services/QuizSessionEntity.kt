package com.dor.mydictionary.services

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.dor.mydictionary.core.QuizSession
import java.util.Date

@Entity(tableName = "quiz_sessions")
data class QuizSessionEntity(
    @PrimaryKey val id: String,
    val quizType: String,
    val date: Date,
    val score: Int,
    val totalWords: Int,
    val correctAnswers: Int,
    val accuracy: Double,
    val duration: Double,
    val wordsPracticed: List<String>
) {
    fun toQuizSession(): QuizSession = QuizSession(
        id = id,
        quizType = quizType,
        date = date,
        score = score,
        totalWords = totalWords,
        correctAnswers = correctAnswers,
        accuracy = accuracy,
        duration = duration,
        wordsPracticed = wordsPracticed
    )
    
    companion object {
        fun fromQuizSession(quizSession: QuizSession): QuizSessionEntity = QuizSessionEntity(
            id = quizSession.id,
            quizType = quizSession.quizType,
            date = quizSession.date,
            score = quizSession.score,
            totalWords = quizSession.totalWords,
            correctAnswers = quizSession.correctAnswers,
            accuracy = quizSession.accuracy,
            duration = quizSession.duration,
            wordsPracticed = quizSession.wordsPracticed
        )
    }
} 