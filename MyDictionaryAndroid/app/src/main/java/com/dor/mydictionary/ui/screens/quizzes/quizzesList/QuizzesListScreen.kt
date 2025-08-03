package com.dor.mydictionary.ui.screens.quizzes.quizzesList

import androidx.compose.foundation.clickable
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
import kotlin.math.max
import kotlin.math.min

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QuizzesListScreen(
    onNavigateToSpellingQuiz: (Int, Boolean) -> Unit = { _, _ -> },
    onNavigateToChooseDefinitionQuiz: (Int, Boolean) -> Unit = { _, _ -> },
    onNavigateToWords: () -> Unit = {},
    viewModel: QuizzesListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState(initial = QuizzesListUiState())

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "Quizzes",
                        style = Typography.displaySmall
                    )
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
                    practiceWordCount = uiState.practiceSettings.wordsPerSession,
                    practiceHardWordsOnly = uiState.practiceSettings.hardWordsOnly,
                    hasHardWords = uiState.hardWordsCount > 0,
                    availableWordsCount = uiState.availableWordsCount,
                    onPracticeWordCountChanged = { viewModel.setWordsPerSession(it) },
                    onPracticeHardWordsOnlyToggled = { viewModel.toggleHardWordsOnly() }
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

            // Check if user has enough words
            if (uiState.availableWordsCount < 10 && !uiState.practiceSettings.hardWordsOnly) {
                item {
                    NotEnoughWordsCard(
                        availableWords = uiState.availableWordsCount,
                        onNavigateToWords = onNavigateToWords
                    )
                }
            } else if (uiState.practiceSettings.hardWordsOnly && uiState.availableWordsCount < 1) {
                item {
                    NotEnoughHardWordsCard(
                        availableHardWords = uiState.availableWordsCount,
                        onNavigateToWords = onNavigateToWords
                    )
                }
            } else {
                // Spelling Quiz Card
                item {
                    QuizCard(
                        title = "Spelling Quiz",
                        description = "Test your spelling skills by typing words correctly",
                        icon = Icons.Default.Edit,
                        isEnabled = uiState.practiceSettings.wordsPerSession > 0,
                        onClick = { onNavigateToSpellingQuiz(uiState.practiceSettings.wordsPerSession, uiState.practiceSettings.hardWordsOnly) }
                    )
                }

                // Choose Definition Quiz Card
                item {
                    QuizCard(
                        title = "Choose Definition",
                        description = "Select the correct definition for each word",
                        icon = Icons.Default.List,
                        isEnabled = uiState.practiceSettings.wordsPerSession > 0,
                        onClick = { onNavigateToChooseDefinitionQuiz(uiState.practiceSettings.wordsPerSession, uiState.practiceSettings.hardWordsOnly) }
                    )
                }
            }
        }
    }
}

@Composable
private fun NotEnoughWordsCard(
    availableWords: Int,
    onNavigateToWords: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                Icons.Default.Book,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Text(
                text = "Not Enough Words",
                style = Typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Text(
                text = "You need at least 10 words to start quizzes. You currently have $availableWords words.",
                style = Typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
            
            Text(
                text = "Add more words to your vocabulary to unlock quizzes!",
                style = Typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
            
            Button(
                onClick = onNavigateToWords,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Add More Words")
            }
        }
    }
}

@Composable
private fun NotEnoughHardWordsCard(
    availableHardWords: Int,
    onNavigateToWords: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                Icons.Default.Star,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Text(
                text = "No Hard Words Available",
                style = Typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Text(
                text = "You need at least 1 hard word to practice in hard words mode. You currently have $availableHardWords hard words.",
                style = Typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
            
            Text(
                text = "Answer some words incorrectly to create hard words for practice!",
                style = Typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
            
            Button(
                onClick = onNavigateToWords,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Add Hard Words")
            }
        }
    }
}

@Composable
private fun PracticeSettingsSection(
    practiceWordCount: Int,
    practiceHardWordsOnly: Boolean,
    hasHardWords: Boolean,
    availableWordsCount: Int,
    onPracticeWordCountChanged: (Int) -> Unit,
    onPracticeHardWordsOnlyToggled: (Boolean) -> Unit
) {
    SettingsSection(
        title = "Practice Settings"
    ) {
        SettingsRow(
            title = "Words per session",
            subtitle = if (availableWordsCount < 10 && !practiceHardWordsOnly) {
                "Need at least 10 words to practice"
            } else if (practiceHardWordsOnly) {
                "Number of words to practice in each session (1-${min(availableWordsCount, 50)})"
            } else {
                "Number of words to practice in each session (10-${min(availableWordsCount, 50)})"
            },
            icon = Icons.Default.TextIncrease,
            trailing = {
                Text(
                    text = "$practiceWordCount",
                    style = Typography.bodySmall,
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Medium
                )
            }
        )
        
        Column(
            modifier = Modifier.padding(horizontal = 16.dp)
        ) {
            if (availableWordsCount >= 10 || practiceHardWordsOnly) {
                val maxWords = if (practiceHardWordsOnly) {
                    min(availableWordsCount, 50)
                } else {
                    min(availableWordsCount, 50)
                }
                val minWords = if (practiceHardWordsOnly) 1 else 10
                val range = maxWords - minWords
                val steps = if (range > 0) max(0, range / 5 - 1) else 0 // No steps if range is 0
                
                Slider(
                    value = practiceWordCount.toFloat(),
                    onValueChange = { onPracticeWordCountChanged(it.toInt()) },
                    valueRange = minWords.toFloat()..maxWords.toFloat(),
                    steps = steps,
                    enabled = !practiceHardWordsOnly // Disable when hard words only is enabled
                )
            } else {
                Text(
                    text = "Add more words to your vocabulary to enable practice settings",
                    style = Typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                )
            }
        }
        
        SettingsRow(
            title = "Practice hard words only",
            subtitle = if (hasHardWords) {
                "Focus on words that need review"
            } else {
                "No words need review yet"
            },
            icon = Icons.Default.Star,
            trailing = {
                Switch(
                    checked = practiceHardWordsOnly,
                    onCheckedChange = onPracticeHardWordsOnlyToggled,
                    enabled = hasHardWords
                )
            }
        )
    }
}

@Composable
private fun SettingsSection(
    title: String,
    footer: String? = null,
    content: @Composable () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = title,
                style = Typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            
            content()
            
            footer?.let {
                Text(
                    text = it,
                    style = Typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun SettingsRow(
    title: String,
    subtitle: String? = null,
    icon: ImageVector? = null,
    trailing: @Composable (() -> Unit)? = null,
    onClick: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
            .then(
                if (onClick != null) {
                    Modifier.clickable { onClick() }
                } else {
                    Modifier
                }
            ),
        verticalAlignment = Alignment.CenterVertically
    ) {
        icon?.let {
            Icon(
                imageVector = it,
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.width(12.dp))
        }
        
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = title,
                style = Typography.bodyMedium,
                fontWeight = FontWeight.Medium
            )
            subtitle?.let {
                Text(
                    text = it,
                    style = Typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        
        trailing?.invoke()
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
        modifier = Modifier
            .fillMaxWidth()
            .clickable(enabled = isEnabled) { onClick() },
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



data class QuizzesListUiState(
    val practiceSettings: PracticeSettings = PracticeSettings(),
    val availableWordsCount: Int = 0,
    val hardWordsCount: Int = 0,
    val isLoading: Boolean = false,
    val error: String? = null
)

data class PracticeSettings(
    val hardWordsOnly: Boolean = false,
    val wordsPerSession: Int = 10,
    val availableWordsCount: Int = 0
)

data class QuizResult(
    val quizType: String,
    val score: Int,
    val totalWords: Int,
    val date: String
) 