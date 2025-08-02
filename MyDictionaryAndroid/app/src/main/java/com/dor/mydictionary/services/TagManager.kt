package com.dor.mydictionary.services

import com.dor.mydictionary.core.Tag
import com.dor.mydictionary.core.TagColor
import java.util.Date
import java.util.UUID
import javax.inject.Inject

class TagManager @Inject constructor(
    private val storage: LocalTagStorage
) {
    suspend fun getAllTags(): List<Tag> {
        return storage.getAll().map { it.toTag() }
    }

    suspend fun getById(id: String): Tag? {
        return storage.getById(id)?.toTag()
    }

    suspend fun getByName(name: String): Tag? {
        return storage.getByName(name)?.toTag()
    }

    suspend fun addTag(
        name: String,
        color: TagColor
    ): Tag {
        val tag = Tag(
            id = UUID.randomUUID().toString(),
            name = name,
            color = color,
            timestamp = Date()
        )
        
        storage.insert(TagEntity.fromTag(tag))
        return tag
    }

    suspend fun updateTag(tag: Tag) {
        storage.update(TagEntity.fromTag(tag))
    }

    suspend fun deleteTag(tag: Tag) {
        storage.delete(TagEntity.fromTag(tag))
    }
} 