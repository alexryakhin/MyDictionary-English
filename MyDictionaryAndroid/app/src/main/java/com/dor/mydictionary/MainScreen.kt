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
import androidx.navigation.NavType
import androidx.navigation.navArgument
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.AnimatedContentTransitionScope.SlideDirection
import androidx.compose.animation.core.tween

import com.dor.mydictionary.ui.TabItem
import com.dor.mydictionary.ui.screens.idioms.idiomsList.IdiomsListScreen
import com.dor.mydictionary.ui.screens.more.screen.MoreScreen
import com.dor.mydictionary.ui.screens.words.wordsList.WordsListScreen
import com.dor.mydictionary.ui.screens.words.wordDetails.WordDetailsScreen
import com.dor.mydictionary.ui.screens.idioms.idiomDetails.IdiomDetailsScreen
import com.dor.mydictionary.ui.screens.quizzes.quizzesList.QuizzesListScreen
import com.dor.mydictionary.ui.screens.quizzes.spellingQuiz.SpellingQuizScreen

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
            composable(
                route = TabItem.Words.route,
                enterTransition = {
                    slideIntoContainer(
                        towards = SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                exitTransition = {
                    slideOutOfContainer(
                        towards = SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                popEnterTransition = {
                    slideIntoContainer(
                        towards = SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                },
                popExitTransition = {
                    slideOutOfContainer(
                        towards = SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                }
            ) { 
                WordsListScreen(
                    onNavigateToWordDetails = { wordId ->
                        navController.navigate("word_details/$wordId")
                    }
                ) 
            }
            composable(
                route = TabItem.Idioms.route,
                enterTransition = {
                    slideIntoContainer(
                        towards = SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                exitTransition = {
                    slideOutOfContainer(
                        towards = SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                popEnterTransition = {
                    slideIntoContainer(
                        towards = SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                },
                popExitTransition = {
                    slideOutOfContainer(
                        towards = SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                }
            ) { 
                IdiomsListScreen(
                    onNavigateToIdiomDetails = { idiomId ->
                        navController.navigate("idiom_details/$idiomId")
                    }
                ) 
            }
            composable(
                route = TabItem.Quizzes.route,
                enterTransition = {
                    slideIntoContainer(
                        towards = SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                exitTransition = {
                    slideOutOfContainer(
                        towards = SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                popEnterTransition = {
                    slideIntoContainer(
                        towards = SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                },
                popExitTransition = {
                    slideOutOfContainer(
                        towards = SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                }
            ) { 
                QuizzesListScreen(
                    onNavigateToSpellingQuiz = {
                        navController.navigate("spelling_quiz")
                    },
                    onNavigateToChooseDefinitionQuiz = {
                        navController.navigate("choose_definition_quiz")
                    }
                ) 
            }
            composable(
                route = TabItem.More.route,
                enterTransition = {
                    slideIntoContainer(
                        towards = SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                exitTransition = {
                    slideOutOfContainer(
                        towards = SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                popEnterTransition = {
                    slideIntoContainer(
                        towards = SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                },
                popExitTransition = {
                    slideOutOfContainer(
                        towards = SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                }
            ) { MoreScreen() }
            
            // Word Details route
            composable(
                route = "word_details/{wordId}",
                arguments = listOf(
                    androidx.navigation.navArgument("wordId") { type = NavType.StringType }
                ),
                enterTransition = {
                    slideIntoContainer(
                        towards = SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                exitTransition = {
                    slideOutOfContainer(
                        towards = SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                popEnterTransition = {
                    slideIntoContainer(
                        towards = SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                },
                popExitTransition = {
                    slideOutOfContainer(
                        towards = SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                }
            ) { backStackEntry ->
                val wordId = backStackEntry.arguments?.getString("wordId") ?: ""
                WordDetailsScreen(
                    wordId = wordId,
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToAddWord = { 
                        // TODO: Navigate to edit word screen
                        navController.popBackStack()
                    }
                )
            }
            
            // Idiom Details route
            composable(
                route = "idiom_details/{idiomId}",
                arguments = listOf(
                    androidx.navigation.navArgument("idiomId") { type = NavType.StringType }
                ),
                enterTransition = {
                    slideIntoContainer(
                        towards = SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                exitTransition = {
                    slideOutOfContainer(
                        towards = SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                popEnterTransition = {
                    slideIntoContainer(
                        towards = SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                },
                popExitTransition = {
                    slideOutOfContainer(
                        towards = SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                }
            ) { backStackEntry ->
                val idiomId = backStackEntry.arguments?.getString("idiomId") ?: ""
                IdiomDetailsScreen(
                    idiomId = idiomId,
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToAddIdiom = { 
                        // TODO: Navigate to edit idiom screen
                        navController.popBackStack()
                    }
                )
            }
            
            // Spelling Quiz route
            composable(
                route = "spelling_quiz",
                enterTransition = {
                    slideIntoContainer(
                        towards = SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                exitTransition = {
                    slideOutOfContainer(
                        towards = SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                popEnterTransition = {
                    slideIntoContainer(
                        towards = SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                },
                popExitTransition = {
                    slideOutOfContainer(
                        towards = SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                }
            ) {
                SpellingQuizScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onQuizComplete = { navController.popBackStack() }
                )
            }
        }
    }
}