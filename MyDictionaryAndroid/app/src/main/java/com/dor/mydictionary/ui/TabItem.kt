package com.dor.mydictionary.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Abc
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.TextIncrease
import androidx.compose.ui.graphics.vector.ImageVector

sealed class TabItem(val route: String, val label: String, val icon: ImageVector) {
    object Words : TabItem("words", "Words", Icons.Default.Abc)
    object Idioms : TabItem("idioms", "Idioms", Icons.Default.Book)
    object Quizzes : TabItem("quizzes", "Quizzes", Icons.Default.TextIncrease)
    object More : TabItem("more", "More", Icons.Default.MoreHoriz)

    companion object {
        val all = listOf(Words, Idioms, Quizzes, More)
    }
}