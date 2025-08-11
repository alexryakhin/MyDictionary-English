package com.dor.mydictionary.ui.screens.quizzes.spellingQuiz

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
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
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.dor.mydictionary.core.Word
import com.dor.mydictionary.core.PartOfSpeech
import com.dor.mydictionary.ui.theme.Typography
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SpellingQuizScreen(
    wordsPerSession: Int = 10,
    hardWordsOnly: Boolean = false,
    onQuizComplete: () -> Unit = {},
    onNavigateToQuizResults: () -> Unit = {}
) {
    val viewModel: SpellingQuizViewModel = hiltViewModel()
    val uiState by viewModel.uiState.collectAsState()
    
    // Handle back press to save progress
    BackHandler {
        if (!uiState.isQuizComplete && uiState.wordsPlayed.isNotEmpty()) {
            viewModel.saveCurrentProgress()
        }
    }

    // Handle navigation when user exits early
    LaunchedEffect(Unit) {
        viewModel.startQuiz(wordsPerSession, hardWordsOnly)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Spelling Quiz", style = Typography.displaySmall) },
                navigationIcon = {
                    IconButton(
                        onClick = {
                            // Save progress if quiz is in progress
                            if (!uiState.isQuizComplete && uiState.wordsPlayed.isNotEmpty()) {
                                viewModel.saveCurrentProgress()
                            }
                            // Navigate back
                            onQuizComplete()
                        }
                    ) {
                        Icon(
                            Icons.Default.ArrowBack, 
                            contentDescription = "Navigate back"
                        )
                    }
                }
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // Header with progress
            HeaderSection(
                currentQuestion = uiState.correctAnswers,
                totalQuestions = uiState.totalQuestions,
                progress = uiState.progress,
                score = uiState.score,
                currentStreak = uiState.currentStreak,
                bestStreak = uiState.bestStreak
            )
            
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                // Definition Card
                uiState.currentWord?.let { word ->
                    item {
                        DefinitionCard(
                            word = word,
                            isShowingHint = uiState.isShowingHint
                        )
                    }

                    // Answer Section
                    item {
                        AnswerSection(
                            userInput = uiState.userInput,
                            onInputChange = { viewModel.setUserInput(it) },
                            onSubmit = { viewModel.submitAnswer() },
                            isCorrect = uiState.isAnswerCorrect,
                            isRevealed = uiState.isShowingCorrectAnswer,
                            attemptCount = uiState.attemptCount,
                            currentWord = word
                        )
                    }

                    // Action Buttons
                    item {
                        ActionButtonsSection(
                            isAnswerSubmitted = uiState.isShowingCorrectAnswer,
                            attemptCount = uiState.attemptCount,
                            userInput = uiState.userInput,
                            onConfirmAnswer = { viewModel.submitAnswer() },
                            onNextWord = { viewModel.loadNextWord() },
                            onSkipWord = { viewModel.skipWord() }
                        )
                    }
                }

                // Quiz Complete Section
                if (uiState.isQuizComplete) {
                    item {
                        QuizCompleteSection(
                            score = uiState.score,
                            totalQuestions = uiState.wordsPlayed.size, // Use words actually played
                            correctAnswers = uiState.correctAnswers,
                            bestStreak = uiState.bestStreak,
                            accuracyContributions = uiState.accuracyContributions, // Pass accuracy contributions
                            onFinish = {
                                viewModel.finishQuiz()
                                onQuizComplete()
                            },
                            onRestart = {
                                viewModel.restartQuiz()
                            }
                        )
                    }
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
fun HeaderSection(
    currentQuestion: Int,
    totalQuestions: Int,
    progress: Float,
    score: Int,
    currentStreak: Int,
    bestStreak: Int
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surface)
            .padding(vertical = 6.dp)
    ) {
        // Progress Bar
        LinearProgressIndicator(
            progress = progress,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp),
            color = MaterialTheme.colorScheme.primary,
            trackColor = MaterialTheme.colorScheme.surfaceVariant
        )
        
        // Stats Row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Left side - Progress and Streak
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    text = "Progress: $currentQuestion/$totalQuestions",
                    style = Typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                if (currentStreak > 0) {
                    Text(
                        text = "🔥 Streak: $currentStreak",
                        style = Typography.bodySmall,
                        color = Color(0xFFFF9800),
                        fontWeight = FontWeight.Medium
                    )
                }
            }
            
            // Right side - Score and Best
            Column(
                horizontalAlignment = Alignment.End,
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                Text(
                    text = "Score: $score",
                    style = Typography.bodySmall,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.primary
                )
                
                Text(
                    text = "Best: $bestStreak",
                    style = Typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        
        Divider(
            modifier = Modifier.padding(top = 6.dp),
            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f)
        )
    }
}

@Composable
fun DefinitionCard(word: Word, isShowingHint: Boolean) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Header with icon and title
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.FormatQuote,
                    contentDescription = "Definition icon",
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(24.dp)
                )
                
                Text(
                    text = "Definition",
                    style = Typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                
                Spacer(modifier = Modifier)
            }
            
            // Definition text
            Text(
                text = word.definition,
                style = Typography.bodyLarge,
                lineHeight = 24.sp
            )
            
            // Part of speech chip
            if (word.partOfSpeech != PartOfSpeech.Unknown) {
                Row {
                    Surface(
                        shape = MaterialTheme.shapes.small,
                        color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)
                    ) {
                        Text(
                            text = word.partOfSpeech.rawValue,
                            style = Typography.bodySmall,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                    
                    Spacer(modifier = Modifier)
                }
            }
            
            // Hint section
            if (isShowingHint) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier
                        .padding(horizontal = 12.dp, vertical = 8.dp)
                        .background(
                            color = Color(0xFFFFEB3B).copy(alpha = 0.1f),
                            shape = MaterialTheme.shapes.small
                        )
                ) {
                    Icon(
                        imageVector = Icons.Default.Lightbulb,
                        contentDescription = "Hint",
                        tint = Color(0xFFFFEB3B)
                    )
                    Text(
                        text = "Hint: The word starts with '${word.wordItself.firstOrNull()?.uppercase() ?: ""}'",
                        style = Typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier)
                }
            }
        }
    }
}

@Composable
private fun AnswerSection(
    userInput: String,
    onInputChange: (String) -> Unit,
    onSubmit: () -> Unit,
    isCorrect: Boolean?,
    isRevealed: Boolean,
    attemptCount: Int,
    currentWord: Word
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Header with icon and title
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Edit,
                    contentDescription = "Answer input icon",
                    tint = Color(0xFF4CAF50),
                    modifier = Modifier.size(24.dp)
                )
                
                Text(
                    text = "Your Answer",
                    style = Typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                
                Spacer(modifier = Modifier)
                
                if (attemptCount > 0) {
                    Text(
                        text = "Attempt $attemptCount",
                        style = Typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            
            // Text input field
            OutlinedTextField(
                value = userInput,
                onValueChange = onInputChange,
                placeholder = { Text("Type the word here...") },
                modifier = Modifier
                    .fillMaxWidth(),
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Text,
                    imeAction = ImeAction.Done
                ),
                keyboardActions = KeyboardActions(
                    onDone = { 
                        if (!isRevealed && attemptCount < 3) {
                            onSubmit()
                        }
                    }
                ),
                enabled = !isRevealed && attemptCount < 3,
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = MaterialTheme.colorScheme.primary,
                    unfocusedBorderColor = MaterialTheme.colorScheme.outline
                )
            )
            
            // Feedback messages
            when {
                isRevealed && isCorrect == true -> {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier
                            .padding(horizontal = 12.dp, vertical = 8.dp)
                            .background(
                                color = Color(0xFF4CAF50).copy(alpha = 0.1f),
                                shape = MaterialTheme.shapes.small
                            )
                    ) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = "Correct answer",
                            tint = Color(0xFF4CAF50)
                        )
                        Text(
                            text = listOf("Correct!", "Well done!", "Keep up the good work!").random(),
                            style = Typography.bodySmall,
                            color = Color(0xFF4CAF50)
                        )
                        Spacer(modifier = Modifier)
                    }
                }
                attemptCount >= 3 -> {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier
                            .padding(horizontal = 12.dp, vertical = 8.dp)
                            .background(
                                color = Color(0xFFF44336).copy(alpha = 0.1f),
                                shape = MaterialTheme.shapes.small
                            )
                    ) {
                        Icon(
                            imageVector = Icons.Default.Warning,
                            contentDescription = "Maximum attempts reached",
                            tint = Color(0xFFF44336)
                        )
                        Text(
                            text = "The correct word is '${currentWord.wordItself}'. Moving to next word...",
                            style = Typography.bodySmall,
                            color = Color(0xFFF44336)
                        )
                        Spacer(modifier = Modifier)
                    }
                }
                isCorrect == false && attemptCount > 0 -> {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier
                            .padding(horizontal = 12.dp, vertical = 8.dp)
                            .background(
                                color = Color(0xFFFF9800).copy(alpha = 0.1f),
                                shape = MaterialTheme.shapes.small
                            )
                    ) {
                        Icon(
                            imageVector = Icons.Default.Warning,
                            contentDescription = "Incorrect answer",
                            tint = Color(0xFFFF9800)
                        )
                        Text(
                            text = if (attemptCount > 2) {
                                "Your word is '${currentWord.wordItself.trim()}'. Try harder :)"
                            } else {
                                "Incorrect. Try again"
                            },
                            style = Typography.bodySmall,
                            color = Color(0xFFFF9800)
                        )
                        Spacer(modifier = Modifier)
                    }
                }
            }
        }
    }
}

@Composable
fun ActionButtonsSection(
    isAnswerSubmitted: Boolean,
    attemptCount: Int,
    userInput: String,
    onConfirmAnswer: () -> Unit,
    onNextWord: () -> Unit,
    onSkipWord: () -> Unit
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Primary button
        Button(
            onClick = when {
                isAnswerSubmitted -> onNextWord
                attemptCount >= 3 -> onNextWord
                else -> onConfirmAnswer
            },
            enabled = when {
                isAnswerSubmitted -> true
                attemptCount >= 3 -> true
                else -> userInput.isNotBlank()
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = when {
                        isAnswerSubmitted || attemptCount >= 3 -> Icons.Default.ArrowForward
                        else -> Icons.Default.Check
                    },
                    contentDescription = when {
                        isAnswerSubmitted || attemptCount >= 3 -> "Next word"
                        else -> "Submit answer"
                    },
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = when {
                        isAnswerSubmitted || attemptCount >= 3 -> "Next Word"
                        else -> "Submit Answer"
                    },
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
        
        // Skip button
        OutlinedButton(
            onClick = onSkipWord,
            enabled = !isAnswerSubmitted && attemptCount < 3,
            modifier = Modifier.fillMaxWidth()
        ) {
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.SkipNext,
                    contentDescription = "Skip word",
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Skip Word (-2 points)")
            }
        }
    }
}

@Composable
fun QuizCompleteSection(
    score: Int,
    totalQuestions: Int,
    correctAnswers: Int,
    bestStreak: Int,
    accuracyContributions: Map<String, Double>, // Fix parameter type
    onFinish: () -> Unit,
    onRestart: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.weight(1f))
        
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // Success Icon
            Surface(
                shape = CircleShape,
                color = Color(0xFF4CAF50),
                modifier = Modifier.size(80.dp)
            ) {
                Icon(
                    Icons.Default.Check,
                    contentDescription = "Quiz completed successfully",
                    modifier = Modifier
                        .size(40.dp)
                        .padding(20.dp),
                    tint = Color.White
                )
            }
            
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = "Quiz Complete!",
                    style = Typography.headlineLarge,
                    fontWeight = FontWeight.Bold
                )
                
                Text(
                    text = "Great job! You've completed the spelling quiz.",
                    style = Typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
            }
            
            // Results Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        text = "Your Results",
                        style = Typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    
                    Column(
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("Final Score")
                            Text(
                                text = "$score",
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("Correct Answers")
                            Text(
                                text = "$correctAnswers/$totalQuestions",
                                fontWeight = FontWeight.Medium
                            )
                        }
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("Best Streak")
                            Text(
                                text = "$bestStreak",
                                fontWeight = FontWeight.Medium,
                                color = Color(0xFFFF9800)
                            )
                        }
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("Accuracy")
                            val accuracyPercentage = if (totalQuestions > 0) (accuracyContributions.values.sum() * 100 / totalQuestions).toInt() else 0
                            Text(
                                text = "$accuracyPercentage%",
                                fontWeight = FontWeight.Medium,
                                color = Color(0xFF4CAF50)
                            )
                        }
                        
                        // Debug info (can be removed later)
                        if (totalQuestions > 0) {
                            Text(
                                text = "Debug: contributions=${accuracyContributions.values.toList()}, total=${accuracyContributions.values.sum()}, avg=${accuracyContributions.values.sum() / totalQuestions}",
                                style = Typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        // Action Buttons
        Column(
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            Button(
                onClick = onRestart,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.Refresh,
                        contentDescription = "Try again",
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Try Again")
                }
            }
            
            OutlinedButton(
                onClick = onFinish,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.ArrowBack,
                        contentDescription = "Back to quizzes",
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Back to Quizzes")
                }
            }
        }
    }
}

 