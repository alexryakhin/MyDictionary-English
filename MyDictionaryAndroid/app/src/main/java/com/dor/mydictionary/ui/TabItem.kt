package com.dor.mydictionary.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Abc
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.TextIncrease
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.ui.graphics.vector.ImageVector

sealed class TabItem(val route: String, val label: String, val icon: ImageVector) {
    object Words : TabItem("words", "Words", Icons.Default.Abc)
    object Idioms : TabItem("idioms", "Idioms", Icons.Default.Book)
    object Quizzes : TabItem("quizzes", "Quizzes", Icons.Default.TextIncrease)
    object Progress : TabItem("progress", "Progress", Icons.Default.TrendingUp)
    object Settings : TabItem("settings", "Settings", Icons.Default.Settings)

    companion object {
        val all = listOf(Words, Idioms, Quizzes, Progress, Settings)
    }
}