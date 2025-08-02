package com.dor.mydictionary.core

enum class TagColor(val rawValue: String) {
    BLUE("blue"),
    RED("red"),
    GREEN("green"),
    YELLOW("yellow"),
    PURPLE("purple"),
    ORANGE("orange"),
    PINK("pink"),
    TEAL("teal");
    
    companion object {
        fun fromRawValue(rawValue: String): TagColor {
            return values().find { it.rawValue == rawValue } ?: BLUE
        }
    }
} 