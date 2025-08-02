package com.dor.mydictionary.services

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.dor.mydictionary.core.Tag
import com.dor.mydictionary.core.TagColor
import java.util.Date

@Entity(tableName = "tags")
data class TagEntity(
    @PrimaryKey val id: String,
    val name: String,
    val color: String,
    val timestamp: Date
) {
    fun toTag(): Tag = Tag(
        id = id,
        name = name,
        color = TagColor.fromRawValue(color),
        timestamp = timestamp
    )
    
    companion object {
        fun fromTag(tag: Tag): TagEntity = TagEntity(
            id = tag.id,
            name = tag.name,
            color = tag.color.rawValue,
            timestamp = tag.timestamp
        )
    }
} 