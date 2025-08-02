package com.dor.mydictionary.core

enum class TagColor(val rawValue: String) {
    Red("red"),
    Pink("pink"),
    Purple("purple"),
    DeepPurple("deepPurple"),
    Indigo("indigo"),
    Blue("blue"),
    LightBlue("lightBlue"),
    Cyan("cyan"),
    Teal("teal"),
    Green("green"),
    LightGreen("lightGreen"),
    Lime("lime"),
    Yellow("yellow"),
    Orange("orange"),
    DeepOrange("deepOrange"),
    Brown("brown"),
    Grey("grey");
    
    companion object {
        fun fromRawValue(rawValue: String): TagColor {
            return values().find { it.rawValue == rawValue } ?: Blue
        }
    }
} 