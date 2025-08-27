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
    Interjection("interjection"),
    Idiom("idiom"),
    Phrase("phrase"),
    Unknown("unknown");

    val isExpression: Boolean
        get() = this == Idiom || this == Phrase

    companion object {
        fun fromRawValue(value: String): PartOfSpeech {
            return entries.find { it.rawValue == value } ?: Unknown
        }
        
        val wordCases: List<PartOfSpeech>
            get() = entries.filter { !it.isExpression && it != Unknown }
        
        val expressionCases: List<PartOfSpeech>
            get() = listOf(Idiom, Phrase)
    }
}