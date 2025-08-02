package com.dor.mydictionary.services

import androidx.room.Entity

@Entity(
    tableName = "word_tag_cross_ref",
    primaryKeys = ["wordId", "tagId"]
)
data class WordTagCrossRef(
    val wordId: String,
    val tagId: String
) 