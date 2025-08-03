package com.dor.mydictionary

import android.content.Context
import androidx.room.Room
import com.dor.mydictionary.services.LocalWordStorage
import com.dor.mydictionary.services.LocalIdiomStorage
import com.dor.mydictionary.services.LocalTagStorage
import com.dor.mydictionary.services.LocalQuizSessionStorage
import com.dor.mydictionary.services.LocalUserStatsStorage
import com.dor.mydictionary.services.LocalWordProgressStorage
import com.dor.mydictionary.services.MyDictionaryDatabase
import com.dor.mydictionary.services.WordManager
import com.dor.mydictionary.services.IdiomManager
import com.dor.mydictionary.services.TagManager
import com.dor.mydictionary.services.QuizSessionManager
import com.dor.mydictionary.services.UserStatsManager
import com.dor.mydictionary.services.WordProgressManager
import com.dor.mydictionary.services.NotificationService
import com.dor.mydictionary.services.CSVManager
import com.dor.mydictionary.services.FilePickerService
import com.dor.mydictionary.services.wordnik.WordnikApi
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): MyDictionaryDatabase {
        return Room.databaseBuilder(
            context,
            MyDictionaryDatabase::class.java,
            "my_dictionary_db"
        ).build()
    }

    @Provides
    fun provideLocalWordStorage(db: MyDictionaryDatabase): LocalWordStorage {
        return db.localWordStorage()
    }

    @Provides
    fun provideLocalIdiomStorage(db: MyDictionaryDatabase): LocalIdiomStorage {
        return db.localIdiomStorage()
    }

    @Provides
    fun provideLocalTagStorage(db: MyDictionaryDatabase): LocalTagStorage {
        return db.localTagStorage()
    }

    @Provides
    fun provideLocalQuizSessionStorage(db: MyDictionaryDatabase): LocalQuizSessionStorage {
        return db.localQuizSessionStorage()
    }

    @Provides
    fun provideLocalUserStatsStorage(db: MyDictionaryDatabase): LocalUserStatsStorage {
        return db.localUserStatsStorage()
    }

    @Provides
    fun provideLocalWordProgressStorage(db: MyDictionaryDatabase): LocalWordProgressStorage {
        return db.localWordProgressStorage()
    }

    @Provides
    fun provideWordManager(storage: LocalWordStorage): WordManager {
        return WordManager(storage)
    }

    @Provides
    fun provideIdiomManager(storage: LocalIdiomStorage): IdiomManager {
        return IdiomManager(storage)
    }

    @Provides
    fun provideTagManager(storage: LocalTagStorage): TagManager {
        return TagManager(storage)
    }

    @Provides
    fun provideQuizSessionManager(storage: LocalQuizSessionStorage): QuizSessionManager {
        return QuizSessionManager(storage)
    }

    @Provides
    fun provideUserStatsManager(storage: LocalUserStatsStorage): UserStatsManager {
        return UserStatsManager(storage)
    }

    @Provides
    fun provideWordProgressManager(storage: LocalWordProgressStorage): WordProgressManager {
        return WordProgressManager(storage)
    }

    @Provides
    @Singleton
    fun provideNotificationService(@ApplicationContext context: Context): NotificationService {
        return NotificationService(context)
    }

    @Provides
    @Singleton
    fun provideCSVManager(@ApplicationContext context: Context, wordManager: WordManager): CSVManager {
        return CSVManager(context, wordManager)
    }

    @Provides
    @Singleton
    fun provideFilePickerService(@ApplicationContext context: Context): FilePickerService {
        return FilePickerService(context)
    }

    @Provides
    fun provideRetrofit(): Retrofit {
        return Retrofit.Builder()
            .baseUrl("https://api.wordnik.com/v4/")
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    @Provides
    fun provideWordnikApi(retrofit: Retrofit): WordnikApi {
        return retrofit.create(WordnikApi::class.java)
    }
}