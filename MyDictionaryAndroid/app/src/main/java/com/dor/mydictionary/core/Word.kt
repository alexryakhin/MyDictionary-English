package com.dor.mydictionary.core

import com.dor.mydictionary.core.PartOfSpeech
import java.util.Date

data class Word(
    val wordItself: String,
    val definition: String,
    val partOfSpeech: PartOfSpeech,
    val phonetic: String?,
    val id: String,
    val timestamp: Date,
    val examples: List<String>,
    val isFavorite: Boolean,
    val difficultyLevel: Int
) {
    val difficultyLabel: String
        get() = when (difficultyLevel) {
            0 -> "new"
            1 -> "inProgress"
            2 -> "needsReview"
            3 -> "mastered"
            else -> "new"
        }
    
    val shouldShowDifficultyLabel: Boolean
        get() = difficultyLevel > 0
}