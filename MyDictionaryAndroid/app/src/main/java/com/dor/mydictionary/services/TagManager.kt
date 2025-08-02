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

    suspend fun createTag(tag: Tag): Tag {
        val newTag = tag.copy(id = UUID.randomUUID().toString())
        storage.insert(TagEntity.fromTag(newTag))
        return newTag
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

    suspend fun getTagsForWord(wordId: String): List<Tag> {
        return storage.getTagsForWord(wordId).map { it.toTag() }
    }

    suspend fun addTagToWord(wordId: String, tagId: String) {
        storage.addTagToWord(WordTagCrossRef(wordId = wordId, tagId = tagId))
    }

    suspend fun removeTagFromWord(wordId: String, tagId: String) {
        storage.removeTagFromWord(wordId, tagId)
    }
} 