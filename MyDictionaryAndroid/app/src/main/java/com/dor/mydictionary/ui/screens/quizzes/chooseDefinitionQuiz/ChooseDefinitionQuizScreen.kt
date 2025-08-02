package com.dor.mydictionary.ui.screens.quizzes.chooseDefinitionQuiz

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.dor.mydictionary.core.Word
import com.dor.mydictionary.ui.theme.Typography

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChooseDefinitionQuizScreen(
    onNavigateBack: () -> Unit,
    onQuizComplete: () -> Unit,
    viewModel: ChooseDefinitionQuizViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState(initial = ChooseDefinitionQuizUiState())

    LaunchedEffect(Unit) {
        viewModel.startQuiz()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Choose Definition", style = Typography.displaySmall) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.skipWord() }) {
                        Icon(Icons.Default.SkipNext, contentDescription = "Skip Word")
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
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // Progress Section
            item {
                ProgressSection(
                    currentQuestion = uiState.currentQuestionIndex + 1,
                    totalQuestions = uiState.totalQuestions,
                    progress = uiState.progress
                )
            }

            // Current Word Section
            uiState.currentWord?.let { word ->
                item {
                    WordSection(word = word)
                }

                // Options Section
                item {
                    OptionsSection(
                        options = uiState.options,
                        selectedOption = uiState.selectedOption,
                        onOptionSelected = { viewModel.selectOption(it) },
                        isAnswerSubmitted = uiState.isAnswerSubmitted,
                        correctAnswerIndex = uiState.correctAnswerIndex
                    )
                }

                // Submit Button
                if (!uiState.isAnswerSubmitted) {
                    item {
                        SubmitButton(
                            isEnabled = uiState.selectedOption != null,
                            onSubmit = { viewModel.submitAnswer() }
                        )
                    }
                } else {
                    // Feedback Section
                    item {
                        FeedbackSection(
                            isCorrect = uiState.isAnswerCorrect,
                            correctAnswer = uiState.options[uiState.correctAnswerIndex],
                            selectedAnswer = uiState.selectedOption?.let { uiState.options[it] }
                        )
                    }

                    // Next Button
                    item {
                        NextButton(onNext = { viewModel.loadNextWord() })
                    }
                }
            }

            // Quiz Complete Section
            if (uiState.isQuizComplete) {
                item {
                    QuizCompleteSection(
                        score = uiState.score,
                        totalQuestions = uiState.totalQuestions,
                        onFinish = {
                            viewModel.finishQuiz()
                            onQuizComplete()
                        }
                    )
                }
            }
        }
    }

    // Error Dialog
    uiState.error?.let { error ->
        AlertDialog(
            onDismissRequest = { viewModel.clearError() },
            title = { Text("Error") },
            text = { Text(error) },
            confirmButton = {
                TextButton(onClick = { viewModel.clearError() }) {
                    Text("OK")
                }
            }
        )
    }
}

@Composable
private fun ProgressSection(
    currentQuestion: Int,
    totalQuestions: Int,
    progress: Float
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Question $currentQuestion of $totalQuestions",
                    style = Typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                
                Text(
                    text = "${(progress * 100).toInt()}%",
                    style = Typography.bodyMedium,
                    color = MaterialTheme.colorScheme.primary
                )
            }
            
            LinearProgressIndicator(
                progress = progress,
                modifier = Modifier.fillMaxWidth(),
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}

@Composable
private fun WordSection(word: Word) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Choose the correct definition for:",
                style = Typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Text(
                text = word.wordItself,
                style = Typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            
            if (word.phonetic?.isNotEmpty() == true) {
                Text(
                    text = "/${word.phonetic}/",
                    style = Typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun OptionsSection(
    options: List<String>,
    selectedOption: Int?,
    onOptionSelected: (Int) -> Unit,
    isAnswerSubmitted: Boolean,
    correctAnswerIndex: Int
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        options.forEachIndexed { index, option ->
            OptionCard(
                text = option,
                isSelected = selectedOption == index,
                isCorrect = if (isAnswerSubmitted) index == correctAnswerIndex else null,
                isIncorrect = if (isAnswerSubmitted) selectedOption == index && index != correctAnswerIndex else null,
                onClick = { onOptionSelected(index) },
                enabled = !isAnswerSubmitted
            )
        }
    }
}

@Composable
private fun OptionCard(
    text: String,
    isSelected: Boolean,
    isCorrect: Boolean?,
    isIncorrect: Boolean?,
    onClick: () -> Unit,
    enabled: Boolean
) {
    val backgroundColor = when {
        isCorrect == true -> MaterialTheme.colorScheme.primaryContainer
        isIncorrect == true -> MaterialTheme.colorScheme.errorContainer
        isSelected -> MaterialTheme.colorScheme.secondaryContainer
        else -> MaterialTheme.colorScheme.surface
    }
    
    val borderColor = when {
        isCorrect == true -> MaterialTheme.colorScheme.primary
        isIncorrect == true -> MaterialTheme.colorScheme.error
        isSelected -> MaterialTheme.colorScheme.primary
        else -> MaterialTheme.colorScheme.outline
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = backgroundColor),
        border = androidx.compose.foundation.BorderStroke(
            width = 2.dp,
            color = borderColor
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (enabled) {
                RadioButton(
                    selected = isSelected,
                    onClick = onClick,
                    enabled = enabled
                )
            } else {
                Icon(
                    when {
                        isCorrect == true -> Icons.Default.Check
                        isIncorrect == true -> Icons.Default.Close
                        else -> Icons.Default.RadioButtonUnchecked
                    },
                    contentDescription = null,
                    tint = when {
                        isCorrect == true -> MaterialTheme.colorScheme.primary
                        isIncorrect == true -> MaterialTheme.colorScheme.error
                        else -> MaterialTheme.colorScheme.onSurfaceVariant
                    }
                )
            }
            
            Spacer(modifier = Modifier.width(12.dp))
            
            Text(
                text = text,
                style = Typography.bodyMedium,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun SubmitButton(
    isEnabled: Boolean,
    onSubmit: () -> Unit
) {
    Button(
        onClick = onSubmit,
        enabled = isEnabled,
        modifier = Modifier.fillMaxWidth()
    ) {
        Text("Submit Answer")
    }
}

@Composable
private fun FeedbackSection(
    isCorrect: Boolean,
    correctAnswer: String,
    selectedAnswer: String?
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (isCorrect) 
                MaterialTheme.colorScheme.primaryContainer 
            else 
                MaterialTheme.colorScheme.errorContainer
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    if (isCorrect) Icons.Default.Check else Icons.Default.Close,
                    contentDescription = null,
                    tint = if (isCorrect) 
                        MaterialTheme.colorScheme.onPrimaryContainer 
                    else 
                        MaterialTheme.colorScheme.onErrorContainer
                )
                Text(
                    text = if (isCorrect) "Correct!" else "Incorrect",
                    style = Typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = if (isCorrect) 
                        MaterialTheme.colorScheme.onPrimaryContainer 
                    else 
                        MaterialTheme.colorScheme.onErrorContainer
                )
            }
            
            if (!isCorrect && selectedAnswer != null) {
                Text(
                    text = "Your answer: $selectedAnswer",
                    style = Typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onErrorContainer
                )
            }
            
            Text(
                text = "Correct answer: $correctAnswer",
                style = Typography.bodyMedium,
                fontWeight = FontWeight.Bold,
                color = if (isCorrect) 
                    MaterialTheme.colorScheme.onPrimaryContainer 
                else 
                    MaterialTheme.colorScheme.onErrorContainer
            )
        }
    }
}

@Composable
private fun NextButton(onNext: () -> Unit) {
    Button(
        onClick = onNext,
        modifier = Modifier.fillMaxWidth()
    ) {
        Text("Next Word")
    }
}

@Composable
private fun QuizCompleteSection(
    score: Int,
    totalQuestions: Int,
    onFinish: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                Icons.Default.Star,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            
            Text(
                text = "Quiz Complete!",
                style = Typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
            
            Text(
                text = "You got $score out of $totalQuestions correct",
                style = Typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Text(
                text = "${(score * 100 / totalQuestions)}%",
                style = Typography.displaySmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            
            Button(
                onClick = onFinish,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Finish")
            }
        }
    }
}

data class ChooseDefinitionQuizUiState(
    val currentWord: Word? = null,
    val options: List<String> = emptyList(),
    val selectedOption: Int? = null,
    val correctAnswerIndex: Int = 0,
    val currentQuestionIndex: Int = 0,
    val totalQuestions: Int = 0,
    val score: Int = 0,
    val progress: Float = 0f,
    val isAnswerSubmitted: Boolean = false,
    val isAnswerCorrect: Boolean = false,
    val isQuizComplete: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null
) 