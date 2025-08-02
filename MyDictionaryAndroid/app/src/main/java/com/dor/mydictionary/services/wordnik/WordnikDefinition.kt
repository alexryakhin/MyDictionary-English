package com.dor.mydictionary.services.wordnik

import com.dor.mydictionary.core.PartOfSpeech
import com.dor.mydictionary.shared.removeHtmlTags
import com.google.gson.annotations.SerializedName

enum class WordnikPartOfSpeech(val rawValue: String) {
    Noun("noun"),
    Adjective("adjective"),
    Verb("verb"),
    Adverb("adverb"),
    Interjection("interjection"),
    Pronoun("pronoun"),
    Preposition("preposition"),
    Abbreviation("abbreviation"),
    Affix("affix"),
    Article("article"),
    AuxiliaryVerb("auxiliary verb"),
    Conjunction("conjunction"),
    DefiniteArticle("definite article"),
    FamilyName("family name"),
    GivenName("given name"),
    Idiom("idiom"),
    Imperative("imperative"),
    NounPlural("noun plural"),
    NounPossessive("noun possessive"),
    PastParticiple("past participle"),
    PhrasalPrefix("phrasal prefix"),
    ProperNoun("proper noun"),
    ProperNounPlural("proper noun plural"),
    ProperNounPossessive("proper noun possessive"),
    Suffix("suffix"),
    VerbIntransitive("intransitive verb"),
    VerbTransitive("transitive verb"),
    Unknown("unknown");

    companion object {
        fun fromRawValue(value: String?): WordnikPartOfSpeech {
            return entries.find { it.rawValue == value } ?: Unknown
        }
    }

    fun toCore(): PartOfSpeech = when (this) {
        Verb,
        AuxiliaryVerb,
        VerbIntransitive,
        VerbTransitive -> PartOfSpeech.Verb

        Adjective -> PartOfSpeech.Adjective
        Adverb -> PartOfSpeech.Adverb
        Conjunction -> PartOfSpeech.Conjunction
        Pronoun -> PartOfSpeech.Pronoun
        Preposition -> PartOfSpeech.Preposition
        Interjection -> PartOfSpeech.Exclamation

        Noun,
        NounPlural,
        NounPossessive,
        ProperNoun,
        ProperNounPlural,
        ProperNounPossessive,
        FamilyName,
        GivenName -> PartOfSpeech.Noun

        else -> PartOfSpeech.Unknown
    }
}

data class ExampleUseDto(
    @SerializedName("text") val text: String
)

data class WordnikDefinitionDto(
    @SerializedName("text") val text: String?,
    @SerializedName("partOfSpeech") val partOfSpeech: String?,
    @SerializedName("exampleUses") val exampleUses: List<ExampleUseDto>?
) {
    fun toDomain(): WordnikDefinition {
        return WordnikDefinition(
            definitionText = text.orEmpty().removeHtmlTags(),
            partOfSpeech = WordnikPartOfSpeech.fromRawValue(partOfSpeech).toCore(),
            examples = exampleUses?.map { it.text.removeHtmlTags() }.orEmpty()
        )
    }
}

data class WordnikDefinition(
    val definitionText: String,
    val partOfSpeech: PartOfSpeech,
    val examples: List<String>
)