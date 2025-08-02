package com.dor.mydictionary.services

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.dor.mydictionary.services.LocalWordStorage
import com.dor.mydictionary.services.LocalIdiomStorage
import com.dor.mydictionary.services.LocalTagStorage
import com.dor.mydictionary.services.LocalQuizSessionStorage
import com.dor.mydictionary.services.LocalUserStatsStorage
import com.dor.mydictionary.services.LocalWordProgressStorage
import com.dor.mydictionary.services.WordEntity
import com.dor.mydictionary.services.IdiomEntity
import com.dor.mydictionary.services.TagEntity
import com.dor.mydictionary.services.QuizSessionEntity
import com.dor.mydictionary.services.UserStatsEntity
import com.dor.mydictionary.services.WordProgressEntity
import com.dor.mydictionary.services.WordTagCrossRef
import com.dor.mydictionary.services.WordTypeConverters

@Database(
    entities = [
        WordEntity::class,
        IdiomEntity::class,
        TagEntity::class,
        QuizSessionEntity::class,
        UserStatsEntity::class,
        WordProgressEntity::class,
        WordTagCrossRef::class
    ],
    version = 1,
    exportSchema = false
)
@TypeConverters(WordTypeConverters::class)
abstract class MyDictionaryDatabase : RoomDatabase() {
    abstract fun localWordStorage(): LocalWordStorage
    abstract fun localIdiomStorage(): LocalIdiomStorage
    abstract fun localTagStorage(): LocalTagStorage
    abstract fun localQuizSessionStorage(): LocalQuizSessionStorage
    abstract fun localUserStatsStorage(): LocalUserStatsStorage
    abstract fun localWordProgressStorage(): LocalWordProgressStorage
}