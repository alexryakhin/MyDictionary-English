package com.dor.mydictionary.services

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update

@Dao
interface LocalTagStorage {
    @Query("SELECT * FROM tags ORDER BY name ASC")
    suspend fun getAll(): List<TagEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(tag: TagEntity)

    @Delete
    suspend fun delete(tag: TagEntity)

    @Update
    suspend fun update(tag: TagEntity)

    @Query("SELECT * FROM tags WHERE id = :id")
    suspend fun getById(id: String): TagEntity?

    @Query("SELECT * FROM tags WHERE name = :name")
    suspend fun getByName(name: String): TagEntity?

    @Query("""
        SELECT t.* FROM tags t
        INNER JOIN word_tag_cross_ref wt ON t.id = wt.tagId
        WHERE wt.wordId = :wordId
        ORDER BY t.name ASC
    """)
    suspend fun getTagsForWord(wordId: String): List<TagEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun addTagToWord(crossRef: WordTagCrossRef)

    @Query("DELETE FROM word_tag_cross_ref WHERE wordId = :wordId AND tagId = :tagId")
    suspend fun removeTagFromWord(wordId: String, tagId: String)
} 