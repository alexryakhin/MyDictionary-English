package com.dor.mydictionary

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.dor.mydictionary.ui.TabItem
import com.dor.mydictionary.ui.screens.idioms.idiomsList.IdiomsListScreen
import com.dor.mydictionary.ui.screens.more.screen.MoreScreen
import com.dor.mydictionary.ui.screens.quizzes.list.QuizzesScreen
import com.dor.mydictionary.ui.screens.words.wordsList.WordsListScreen

@Composable
fun MainScreen() {
    val navController = rememberNavController()
    val currentBackStack by navController.currentBackStackEntryAsState()
    val currentRoute = currentBackStack?.destination?.route

    Scaffold(
        bottomBar = {
            NavigationBar {
                TabItem.all.forEach { tab ->
                    NavigationBarItem(
                        selected = currentRoute == tab.route,
                        onClick = {
                            if (currentRoute != tab.route) {
                                navController.navigate(tab.route) {
                                    popUpTo(navController.graph.startDestinationId) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        },
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label) },
                        alwaysShowLabel = true
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = TabItem.Words.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(TabItem.Words.route) { WordsListScreen() }
            composable(TabItem.Idioms.route) { IdiomsListScreen() }
            composable(TabItem.Quizzes.route) { QuizzesScreen() }
            composable(TabItem.More.route) { MoreScreen() }
        }
    }
}