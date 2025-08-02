package com.dor.mydictionary.core

import androidx.compose.ui.graphics.Color

enum class Difficulty(val displayName: String, val level: Int, val color: Color) {
    NEW("New", 0, Color(0xFF9E9E9E)), // Gray
    IN_PROGRESS("In Progress", 1, Color(0xFFFF9800)), // Orange
    NEEDS_REVIEW("Needs Review", 2, Color(0xFFF44336)), // Red
    MASTERED("Mastered", 3, Color(0xFF4CAF50)); // Green
    
    companion object {
        fun fromLevel(level: Int): Difficulty {
            return values().find { it.level == level } ?: NEW
        }
    }
} 