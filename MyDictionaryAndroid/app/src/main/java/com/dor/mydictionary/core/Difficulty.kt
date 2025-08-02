package com.dor.mydictionary.core

enum class Difficulty(val displayName: String, val level: Int) {
    NEW("New", 0),
    IN_PROGRESS("In Progress", 1),
    NEEDS_REVIEW("Needs Review", 2),
    MASTERED("Mastered", 3);
    
    companion object {
        fun fromLevel(level: Int): Difficulty {
            return values().find { it.level == level } ?: NEW
        }
    }
} 