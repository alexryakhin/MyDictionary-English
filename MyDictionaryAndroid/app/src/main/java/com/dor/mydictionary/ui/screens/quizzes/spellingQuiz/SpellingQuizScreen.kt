package com.dor.mydictionary.ui.screens.quizzes.spellingQuiz

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.dor.mydictionary.core.Word
import com.dor.mydictionary.ui.theme.Typography

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SpellingQuizScreen(
    onNavigateBack: () -> Unit,
    onQuizComplete: () -> Unit,
    viewModel: SpellingQuizViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState(initial = SpellingQuizUiState())
    val focusRequester = remember { FocusRequester() }

    LaunchedEffect(Unit) {
        viewModel.startQuiz()
        focusRequester.requestFocus()
    }

    LaunchedEffect(uiState.currentWord) {
        if (uiState.currentWord != null) {
            focusRequester.requestFocus()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Spelling Quiz", style = Typography.displaySmall) },
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
                    WordSection(
                        word = word,
                        isRevealed = uiState.isWordRevealed
                    )
                }

                // Input Section
                item {
                    InputSection(
                        userInput = uiState.userInput,
                        onInputChange = { viewModel.setUserInput(it) },
                        onSubmit = { viewModel.submitAnswer() },
                        isCorrect = uiState.isAnswerCorrect,
                        isRevealed = uiState.isWordRevealed,
                        focusRequester = focusRequester
                    )
                }

                // Feedback Section
                if (uiState.isWordRevealed) {
                    item {
                        uiState.isAnswerCorrect?.let {
                            FeedbackSection(
                                isCorrect = it,
                                correctAnswer = word.wordItself,
                                userAnswer = uiState.userInput
                            )
                        }
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
private fun WordSection(
    word: Word,
    isRevealed: Boolean
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
            Text(
                text = "Spell this word:",
                style = Typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            if (isRevealed) {
                Text(
                    text = word.wordItself,
                    style = Typography.headlineLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )
            } else {
                Text(
                    text = "? ? ? ? ?",
                    style = Typography.headlineLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            if (word.definition.isNotEmpty()) {
                Text(
                    text = word.definition,
                    style = Typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun InputSection(
    userInput: String,
    onInputChange: (String) -> Unit,
    onSubmit: () -> Unit,
    isCorrect: Boolean?,
    isRevealed: Boolean,
    focusRequester: FocusRequester
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        OutlinedTextField(
            value = userInput,
            onValueChange = onInputChange,
            label = { Text("Type the word") },
            placeholder = { Text("Enter your answer") },
            modifier = Modifier
                .fillMaxWidth()
                .focusRequester(focusRequester),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Text,
                imeAction = ImeAction.Done
            ),
            keyboardActions = KeyboardActions(
                onDone = { onSubmit() }
            ),
            enabled = !isRevealed,
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = when (isCorrect) {
                    true -> MaterialTheme.colorScheme.primary
                    false -> MaterialTheme.colorScheme.error
                    null -> MaterialTheme.colorScheme.primary
                },
                unfocusedBorderColor = when (isCorrect) {
                    true -> MaterialTheme.colorScheme.primary
                    false -> MaterialTheme.colorScheme.error
                    null -> MaterialTheme.colorScheme.outline
                }
            )
        )
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            if (!isRevealed) {
                Button(
                    onClick = onSubmit,
                    enabled = userInput.isNotBlank(),
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Submit")
                }
            } else {
                Button(
                    onClick = onSubmit,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Next Word")
                }
            }
        }
    }
}

@Composable
private fun FeedbackSection(
    isCorrect: Boolean,
    correctAnswer: String,
    userAnswer: String
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
            
            if (!isCorrect) {
                Text(
                    text = "Your answer: $userAnswer",
                    style = Typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onErrorContainer
                )
                Text(
                    text = "Correct answer: $correctAnswer",
                    style = Typography.bodyMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onErrorContainer
                )
            }
        }
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

data class SpellingQuizUiState(
    val currentWord: Word? = null,
    val userInput: String = "",
    val currentQuestionIndex: Int = 0,
    val totalQuestions: Int = 0,
    val score: Int = 0,
    val progress: Float = 0f,
    val isWordRevealed: Boolean = false,
    val isAnswerCorrect: Boolean? = null,
    val isQuizComplete: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null
) 