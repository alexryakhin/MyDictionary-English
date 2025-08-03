package com.dor.mydictionary.ui.screens.quizzes.chooseDefinitionQuiz

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.TextFields
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.Typography
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.dor.mydictionary.core.PartOfSpeech
import com.dor.mydictionary.core.Word

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChooseDefinitionQuizScreen(
    wordCount: Int = 10,
    hardWordsOnly: Boolean = false,
    onNavigateBack: () -> Unit,
    onQuizComplete: () -> Unit,
    viewModel: ChooseDefinitionQuizViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState(initial = ChooseDefinitionQuizUiState())

    LaunchedEffect(Unit) {
        viewModel.startQuiz(wordCount, hardWordsOnly)
    }

    // Handle cleanup when screen disappears
    DisposableEffect(Unit) {
        onDispose {
            viewModel.cleanupOnDisappear()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Choose Definition") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    // Skip button moved to action buttons section
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
                    progress = uiState.progress,
                    correctAnswers = uiState.correctAnswers,
                    currentStreak = uiState.currentStreak,
                    bestStreak = uiState.bestStreak,
                    score = uiState.score
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

                // Action Buttons (Skip button)
                if (!uiState.isAnswerSubmitted) {
                    item {
                        ActionButtonsSection(
                            onSkipWord = { viewModel.skipWord() }
                        )
                    }
                }

                // Feedback Section (shown immediately after answer selection)
                if (uiState.isAnswerSubmitted) {
                    item {
                        FeedbackSection(
                            isCorrect = uiState.isAnswerCorrect,
                            correctAnswer = uiState.options[uiState.correctAnswerIndex],
                            selectedAnswer = uiState.selectedOption?.let { uiState.options[it] }
                        )
                    }
                }
            }

            // Quiz Complete Section
            if (uiState.isQuizComplete) {
                item {
                    QuizCompleteSection(
                        score = uiState.score,
                        totalQuestions = uiState.totalQuestions,
                        correctAnswers = uiState.correctAnswers,
                        bestStreak = uiState.bestStreak,
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
    progress: Float,
    correctAnswers: Int,
    currentStreak: Int,
    bestStreak: Int,
    score: Int
) {
    Column(
        modifier = Modifier
            .background(MaterialTheme.colorScheme.surface)
            .padding(bottom = 6.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // Progress Bar
        LinearProgressIndicator(
            progress = progress,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp),
            color = MaterialTheme.colorScheme.primary
        )
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                Text(
                    text = "Progress: $currentQuestion/$totalQuestions",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                if (currentStreak > 0) {
                    Text(
                        text = "🔥 Streak: $currentStreak",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
            
            Spacer(modifier = Modifier)
            
            Column(
                verticalArrangement = Arrangement.spacedBy(2.dp),
                horizontalAlignment = Alignment.End,
                modifier = Modifier.padding(horizontal = 24.dp)
            ) {
                Text(
                    text = "Score: $score",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.primary
                )
                
                Text(
                    text = "Best: $bestStreak",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
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
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.TextFields,
                    contentDescription = null,
                    modifier = Modifier.size(24.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
                
                Spacer(modifier = Modifier.width(8.dp))
                
                Text(
                    text = "Word",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                
                Spacer(modifier = Modifier)
            }
            
            Text(
                text = word.wordItself,
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            
            if (word.partOfSpeech != PartOfSpeech.Unknown) {
                Row() {
                    Text(
                        text = word.partOfSpeech.name,
                        style = MaterialTheme.typography.bodySmall,
                        modifier = Modifier
                            .padding(horizontal = 8.dp, vertical = 4.dp)
                            .background(
                                MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                                shape = CircleShape
                            )
                            .padding(horizontal = 8.dp, vertical = 4.dp),
                        color = MaterialTheme.colorScheme.primary
                    )
                    
                    Spacer(modifier = Modifier)
                }
            }
            
            if (word.phonetic?.isNotEmpty() == true) {
                Text(
                    text = "/${word.phonetic}/",
                    style = MaterialTheme.typography.bodyMedium,
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
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Default.List,
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.width(8.dp))
            
            Text(
                text = "Choose the Correct Definition",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            
            Spacer(modifier = Modifier)
        }
        
        Column(
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier
                .padding(20.dp)
                .background(
                    MaterialTheme.colorScheme.surface,
                    shape = RoundedCornerShape(12.dp)
                )
                .shadow(elevation = 2.dp)
        ) {
            options.forEachIndexed { index, option ->
                OptionCard(
                    text = option,
                    isSelected = selectedOption == index,
                    isCorrect = if (isAnswerSubmitted) index == correctAnswerIndex else null,
                    isIncorrect = if (isAnswerSubmitted) selectedOption == index && index != correctAnswerIndex else null,
                    onClick = { onOptionSelected(index) },
                    enabled = selectedOption == null && !isAnswerSubmitted
                )
            }
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
        border = BorderStroke(
            width = 2.dp,
            color = borderColor
        ),
        shape = RoundedCornerShape(12.dp)
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
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.weight(1f),
                maxLines = 3
            )
            
            Spacer(modifier = Modifier.width(8.dp))
            
            Icon(
                Icons.Default.ChevronRight,
                contentDescription = null,
                modifier = Modifier.size(16.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun ActionButtonsSection(
    onSkipWord: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Button(
            onClick = onSkipWord,
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.surface
            )
        ) {
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.SkipNext,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Skip Word (-25 points)")
            }
        }
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
                    style = MaterialTheme.typography.titleMedium,
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
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onErrorContainer
                )
            }
            
            Text(
                text = "Correct answer: $correctAnswer",
                style = MaterialTheme.typography.bodyMedium,
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
private fun QuizCompleteSection(
    score: Int,
    totalQuestions: Int,
    correctAnswers: Int,
    bestStreak: Int,
    onFinish: () -> Unit,
    onRestart: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(32.dp)) {
        Spacer(modifier = Modifier)

        Column(
            verticalArrangement = Arrangement.spacedBy(24.dp),
            modifier = Modifier
                .padding(horizontal = 32.dp)
        ) {
            // Success Icon
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .background(
                        MaterialTheme.colorScheme.primary,
                        shape = CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Default.Check,
                    contentDescription = null,
                    modifier = Modifier.size(32.dp),
                    tint = MaterialTheme.colorScheme.onPrimary
                )
            }
            
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    text = "Quiz Complete!",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold
                )
                
                Text(
                    text = "Great job! You've completed the definition quiz.",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
            }
            
            // Score Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        text = "Your Results",
                        style = MaterialTheme.typography.titleLarge,
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
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("Accuracy")
                            Text(
                                text = "${if (totalQuestions > 0) (correctAnswers * 100 / totalQuestions) else 0}%",
                                fontWeight = FontWeight.Medium,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
            }
        }
        
        Column(
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier
                .padding(horizontal = 32.dp)
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
                        contentDescription = null,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Try Again")
                }
            }
            
            Button(
                onClick = onFinish,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            ) {
                Row(
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.ArrowBack,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Back to Quizzes")
                }
            }
        }

        
        Spacer(modifier = Modifier)
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
    val error: String? = null,
    val correctAnswers: Int = 0,
    val currentStreak: Int = 0,
    val bestStreak: Int = 0,
    val questionsAnswered: Int = 0
) 