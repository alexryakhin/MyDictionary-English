package com.dor.mydictionary.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.dor.mydictionary.MainActivity
import com.dor.mydictionary.R
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Calendar
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NotificationService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        const val CHANNEL_ID_DAILY_REMINDER = "daily_reminder"
        const val CHANNEL_ID_DIFFICULT_WORDS = "difficult_words"
        const val NOTIFICATION_ID_DAILY_REMINDER = 1001
        const val NOTIFICATION_ID_DIFFICULT_WORDS = 1002
    }

    private val notificationManager = NotificationManagerCompat.from(context)

    init {
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val dailyReminderChannel = NotificationChannel(
                CHANNEL_ID_DAILY_REMINDER,
                "Daily Reminders",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Daily practice reminders"
            }

            val difficultWordsChannel = NotificationChannel(
                CHANNEL_ID_DIFFICULT_WORDS,
                "Difficult Words Alerts",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Alerts for words that need review"
            }

            notificationManager.createNotificationChannels(listOf(dailyReminderChannel, difficultWordsChannel))
        }
    }

    suspend fun requestPermission(): Boolean = withContext(Dispatchers.IO) {
        try {
            // For Android 13+ (API 33+), we need to request notification permission
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                // This would typically be handled in the UI layer with proper permission request
                // For now, we'll assume permission is granted
                return@withContext true
            }
            return@withContext true
        } catch (e: Exception) {
            return@withContext false
        }
    }

    fun scheduleDailyReminder(hour: Int = 9, minute: Int = 0) {
        // TODO: Implement actual scheduling with WorkManager or AlarmManager
        // For now, we'll just show a notification immediately for testing
        showDailyReminderNotification()
    }

    fun scheduleDifficultWordsAlert() {
        // TODO: Implement actual scheduling
        // For now, we'll just show a notification immediately for testing
        showDifficultWordsNotification()
    }

    fun cancelAllNotifications() {
        notificationManager.cancelAll()
    }

    private fun showDailyReminderNotification() {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID_DAILY_REMINDER)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle("Time to Practice!")
            .setContentText("Don't forget to practice your vocabulary today")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(NOTIFICATION_ID_DAILY_REMINDER, notification)
    }

    private fun showDifficultWordsNotification() {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID_DIFFICULT_WORDS)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle("Words Need Review")
            .setContentText("You have difficult words that need practice")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(NOTIFICATION_ID_DIFFICULT_WORDS, notification)
    }
} 