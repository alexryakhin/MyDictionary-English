package com.dor.mydictionary.core

enum class TagColor(val rawValue: String) {
    Blue("blue"),
    Red("red"),
    Green("green"),
    Orange("orange"),
    Purple("purple"),
    Pink("pink"),
    Yellow("yellow"),
    Grey("grey");

    companion object {
        fun fromRawValue(rawValue: String): TagColor {
            return values().find { it.rawValue == rawValue } ?: Blue
        }
    }
} 