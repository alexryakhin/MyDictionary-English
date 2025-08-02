package com.dor.mydictionary.shared

import com.dor.mydictionary.core.Word
import com.dor.mydictionary.services.WordEntity

fun Word.toEntity(): WordEntity {
    return WordEntity(
        id = id,
        wordItself = wordItself,
        definition = definition,
        partOfSpeech = partOfSpeech.rawValue,
        phonetic = phonetic,
        timestamp = timestamp,
        examples = examples,
        isFavorite = isFavorite,
        difficultyLevel = difficultyLevel
    )
}