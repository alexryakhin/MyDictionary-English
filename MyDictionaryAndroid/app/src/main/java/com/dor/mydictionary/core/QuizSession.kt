package com.dor.mydictionary.core

import java.util.Date

data class QuizSession(
    val id: String,
    val quizType: String,
    val date: Date,
    val score: Int,
    val totalWords: Int,
    val correctAnswers: Int,
    val accuracy: Double,
    val duration: Double,
    val wordsPracticed: List<String>
) 