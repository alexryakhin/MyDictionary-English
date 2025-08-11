package com.dor.mydictionary.services

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import com.dor.mydictionary.core.PartOfSpeech
import com.dor.mydictionary.core.Word
import java.util.Date

@Entity(tableName = "words")
data class WordEntity(
    @PrimaryKey val id: String,
    val wordItself: String,
    val definition: String,
    val partOfSpeech: String,
    val phonetic: String?,
    val timestamp: Date,
    val isFavorite: Boolean,
    val examples: List<String>,
    val difficultyScore: Int
) {
    fun toWord(): Word = Word(
        wordItself, 
        definition, 
        PartOfSpeech.fromRawValue(partOfSpeech),
        phonetic, 
        id, 
        timestamp, 
        examples, 
        isFavorite,
        difficultyScore
    )
    
    companion object {
        fun fromWord(word: Word): WordEntity = WordEntity(
            id = word.id,
            wordItself = word.wordItself,
            definition = word.definition,
            partOfSpeech = word.partOfSpeech.rawValue,
            phonetic = word.phonetic,
            timestamp = word.timestamp,
            isFavorite = word.isFavorite,
            examples = word.examples,
            difficultyScore = word.difficultyScore
        )
    }
}