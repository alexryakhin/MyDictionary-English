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
    val difficultyScore: Int
) {
    val difficultyLevel: Difficulty
        get() = Difficulty.fromScore(difficultyScore)
    
    val difficultyLabel: String
        get() = difficultyLevel.displayName
    
    val shouldShowDifficultyLabel: Boolean
        get() = difficultyScore > 0
}