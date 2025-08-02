package com.dor.mydictionary.ui.screens.quizzes.quizzesList

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.dor.mydictionary.ui.theme.Typography

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QuizzesListScreen(
    onNavigateToSpellingQuiz: () -> Unit = {},
    onNavigateToChooseDefinitionQuiz: () -> Unit = {},
    viewModel: QuizzesListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState(initial = QuizzesListUiState())

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Quizzes", style = Typography.displaySmall) },
                actions = {
                    IconButton(onClick = { viewModel.togglePracticeSettings() }) {
                        Icon(Icons.Default.Settings, contentDescription = "Practice Settings")
                    }
                }
            )
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Practice Settings Section
            item {
                PracticeSettingsSection(
                    practiceSettings = uiState.practiceSettings,
                    onToggleHardWordsOnly = { viewModel.toggleHardWordsOnly() },
                    onToggleWordsPerSession = { count -> viewModel.setWordsPerSession(count) }
                )
            }

            // Quiz Types Section
            item {
                Text(
                    text = "Available Quizzes",
                    style = Typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
            }

            // Spelling Quiz Card
            item {
                QuizCard(
                    title = "Spelling Quiz",
                    description = "Test your spelling skills by typing words correctly",
                    icon = Icons.Default.Edit,
                    isEnabled = uiState.practiceSettings.wordsPerSession > 0,
                    onClick = onNavigateToSpellingQuiz
                )
            }

            // Choose Definition Quiz Card
            item {
                QuizCard(
                    title = "Choose Definition",
                    description = "Select the correct definition for each word",
                    icon = Icons.Default.List,
                    isEnabled = uiState.practiceSettings.wordsPerSession > 0,
                    onClick = onNavigateToChooseDefinitionQuiz
                )
            }

            // Recent Results Section
            if (uiState.recentQuizResults.isNotEmpty()) {
                item {
                    Text(
                        text = "Recent Results",
                        style = Typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                }

                items(uiState.recentQuizResults.take(3)) { result ->
                    QuizResultCard(
                        quizType = result.quizType,
                        score = result.score,
                        totalWords = result.totalWords,
                        date = result.date
                    )
                }

                if (uiState.recentQuizResults.size > 3) {
                    item {
                        TextButton(
                            onClick = { /* TODO: Navigate to full results */ },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("View All Results")
                        }
                    }
                }
            }
        }
    }

    // Practice Settings Dialog
    if (uiState.showPracticeSettings) {
        PracticeSettingsDialog(
            practiceSettings = uiState.practiceSettings,
            onToggleHardWordsOnly = { viewModel.toggleHardWordsOnly() },
            onToggleWordsPerSession = { count -> viewModel.setWordsPerSession(count) },
            onDismiss = { viewModel.togglePracticeSettings() }
        )
    }
}

@Composable
private fun PracticeSettingsSection(
    practiceSettings: PracticeSettings,
    onToggleHardWordsOnly: () -> Unit,
    onToggleWordsPerSession: (Int) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "Practice Settings",
                style = Typography.titleMedium,
                fontWeight = FontWeight.Bold
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Hard words only",
                    style = Typography.bodyMedium
                )
                Switch(
                    checked = practiceSettings.hardWordsOnly,
                    onCheckedChange = { onToggleHardWordsOnly() }
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Words per session",
                    style = Typography.bodyMedium
                )
                Text(
                    text = "${practiceSettings.wordsPerSession}",
                    style = Typography.bodyMedium,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@Composable
private fun QuizCard(
    title: String,
    description: String,
    icon: ImageVector,
    isEnabled: Boolean,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isEnabled) MaterialTheme.colorScheme.surface 
            else MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = if (isEnabled) MaterialTheme.colorScheme.primary 
                else MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.width(16.dp))

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = Typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = if (isEnabled) MaterialTheme.colorScheme.onSurface 
                    else MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                Text(
                    text = description,
                    style = Typography.bodyMedium,
                    color = if (isEnabled) MaterialTheme.colorScheme.onSurfaceVariant 
                    else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                )
            }

            Icon(
                Icons.Default.ChevronRight,
                contentDescription = null,
                tint = if (isEnabled) MaterialTheme.colorScheme.onSurfaceVariant 
                else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
            )
        }
    }
}

@Composable
private fun QuizResultCard(
    quizType: String,
    score: Int,
    totalWords: Int,
    date: String
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = quizType,
                    style = Typography.titleSmall,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = date,
                    style = Typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Column(
                horizontalAlignment = Alignment.End
            ) {
                Text(
                    text = "$score/$totalWords",
                    style = Typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = "${(score * 100 / totalWords)}%",
                    style = Typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun PracticeSettingsDialog(
    practiceSettings: PracticeSettings,
    onToggleHardWordsOnly: () -> Unit,
    onToggleWordsPerSession: (Int) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Practice Settings") },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Hard words only")
                    Switch(
                        checked = practiceSettings.hardWordsOnly,
                        onCheckedChange = { onToggleHardWordsOnly() }
                    )
                }

                Column {
                    Text(
                        text = "Words per session",
                        style = Typography.bodyMedium
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        listOf(5, 10, 15, 20).forEach { count ->
                            FilterChip(
                                onClick = { onToggleWordsPerSession(count) },
                                label = { Text("$count") },
                                selected = practiceSettings.wordsPerSession == count
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Done")
            }
        }
    )
}

data class QuizzesListUiState(
    val practiceSettings: PracticeSettings = PracticeSettings(),
    val recentQuizResults: List<QuizResult> = emptyList(),
    val showPracticeSettings: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null
)

data class PracticeSettings(
    val hardWordsOnly: Boolean = false,
    val wordsPerSession: Int = 10
)

data class QuizResult(
    val quizType: String,
    val score: Int,
    val totalWords: Int,
    val date: String
) 