package com.dor.mydictionary.services

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.dor.mydictionary.core.Idiom
import java.util.Date

@Entity(tableName = "idioms")
data class IdiomEntity(
    @PrimaryKey val id: String,
    val idiomItself: String,
    val definition: String,
    val timestamp: Date,
    val isFavorite: Boolean,
    val examples: List<String>
) {
    fun toIdiom(): Idiom = Idiom(
        id = id,
        idiomItself = idiomItself,
        definition = definition,
        timestamp = timestamp,
        isFavorite = isFavorite,
        examples = examples
    )
    
    companion object {
        fun fromIdiom(idiom: Idiom): IdiomEntity = IdiomEntity(
            id = idiom.id,
            idiomItself = idiom.idiomItself,
            definition = idiom.definition,
            timestamp = idiom.timestamp,
            isFavorite = idiom.isFavorite,
            examples = idiom.examples
        )
    }
} 