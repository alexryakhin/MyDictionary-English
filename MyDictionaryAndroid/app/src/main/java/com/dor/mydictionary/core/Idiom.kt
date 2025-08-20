package com.dor.mydictionary.core

import java.util.Date

data class Idiom(
    val id: String,
    val idiomItself: String,
    val definition: String,
    val timestamp: Date,
    val isFavorite: Boolean,
    val examples: List<String>,
    val difficultyScore: Int = 0,
    val languageCode: String = "en"
) {
    val difficultyLevel: Difficulty
        get() = Difficulty.fromScore(difficultyScore)
    
    val difficultyLabel: String
        get() = difficultyLevel.displayName
    
    val shouldShowDifficultyLabel: Boolean
        get() = difficultyScore > 0
} 