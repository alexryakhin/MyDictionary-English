package com.dor.mydictionary.core

enum class PartOfSpeech(val rawValue: String) {
    Noun("noun"),
    Verb("verb"),
    Adjective("adjective"),
    Adverb("adverb"),
    Conjunction("conjunction"),
    Pronoun("pronoun"),
    Preposition("preposition"),
    Exclamation("exclamation"),
    Unknown("unknown");

    companion object {
        fun fromRawValue(value: String): PartOfSpeech {
            return entries.find { it.rawValue == value } ?: Unknown
        }
    }
}