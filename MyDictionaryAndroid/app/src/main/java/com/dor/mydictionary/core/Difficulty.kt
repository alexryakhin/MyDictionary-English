package com.dor.mydictionary.core

import androidx.compose.ui.graphics.Color

enum class Difficulty(val displayName: String, val level: Int, val color: Color) {
    New("New", 0, Color(0xFF9E9E9E)), // Gray
    InProgress("In Progress", 1, Color(0xFFFF9800)), // Orange
    NeedsReview("Needs Review", 2, Color(0xFFF44336)), // Red
    Mastered("Mastered", 3, Color(0xFF4CAF50)); // Green
    
    companion object {
        fun fromLevel(level: Int): Difficulty {
            return values().find { it.level == level } ?: New
        }
        
        fun fromScore(score: Int): Difficulty {
            return when {
                score < 0 -> NeedsReview
                score >= 1 && score <= 49 -> InProgress
                score >= 50 -> Mastered
                else -> New
            }
        }
    }
} 