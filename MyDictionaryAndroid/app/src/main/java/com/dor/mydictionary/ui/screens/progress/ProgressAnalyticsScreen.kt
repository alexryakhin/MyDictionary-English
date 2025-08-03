package com.dor.mydictionary.ui.screens.progress

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.dor.mydictionary.ui.components.VocabularyLineChart
import com.dor.mydictionary.ui.theme.Typography

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProgressAnalyticsScreen(
    onNavigateToQuizResults: () -> Unit = {},
    viewModel: ProgressAnalyticsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState(initial = ProgressAnalyticsUiState())

    LaunchedEffect(Unit) {
        viewModel.loadProgressData()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Progress", style = Typography.displaySmall) }
            )
        }
    ) { innerPadding ->
        if (uiState.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    CircularProgressIndicator(
                        modifier = Modifier.scale(1.5f)
                    )
                    Text(
                        text = "Loading progress data...",
                        style = Typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Progress Overview Section
                item {
                    ProgressOverviewSection(
                        inProgress = uiState.inProgress,
                        mastered = uiState.mastered,
                        needsReview = uiState.needsReview,
                        totalPracticeTime = uiState.totalPracticeTime,
                        averageAccuracy = uiState.averageAccuracy,
                        totalSessions = uiState.totalSessions
                    )
                }

                // Quiz Results Section
                item {
                    QuizResultsSection(
                        recentQuizResults = uiState.recentQuizResults,
                        onNavigateToQuizResults = onNavigateToQuizResults
                    )
                }

                // Vocabulary Growth Section
                item {
                    VocabularyGrowthSection(
                        chartData = uiState.vocabularyGrowthData,
                        selectedPeriod = uiState.selectedPeriod,
                        onPeriodChanged = { viewModel.setSelectedPeriod(it) }
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
private fun ProgressOverviewSection(
    inProgress: Int,
    mastered: Int,
    needsReview: Int,
    totalPracticeTime: Double,
    averageAccuracy: Double,
    totalSessions: Int
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Progress Overview",
                style = Typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            // Progress Cards Grid - 3x2 grid like iOS
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // First row - Progress cards
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Box(
                        modifier = Modifier.weight(1f),
                        contentAlignment = Alignment.Center
                    ) {
                        ProgressCard(
                            title = "In Progress",
                            value = "$inProgress",
                            color = Color(0xFF2196F3), // Blue
                            icon = Icons.Default.Schedule
                        )
                    }
                    
                    Box(
                        modifier = Modifier.weight(1f),
                        contentAlignment = Alignment.Center
                    ) {
                        ProgressCard(
                            title = "Mastered",
                            value = "$mastered",
                            color = Color(0xFF4CAF50), // Green
                            icon = Icons.Default.CheckCircle
                        )
                    }
                    
                    Box(
                        modifier = Modifier.weight(1f),
                        contentAlignment = Alignment.Center
                    ) {
                        ProgressCard(
                            title = "Need Review",
                            value = "$needsReview",
                            color = Color(0xFFFF9800), // Orange
                            icon = Icons.Default.Warning
                        )
                    }
                }

                // Second row - Stat cards
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Box(
                        modifier = Modifier.weight(1f),
                        contentAlignment = Alignment.Center
                    ) {
                        StatCard(
                            title = "Practice Time",
                            value = "${totalPracticeTime.toInt()} min",
                            icon = Icons.Default.Timer
                        )
                    }
                    
                    Box(
                        modifier = Modifier.weight(1f),
                        contentAlignment = Alignment.Center
                    ) {
                        StatCard(
                            title = "Accuracy",
                            value = "${(averageAccuracy * 100).toInt()}%",
                            icon = Icons.Default.TrackChanges
                        )
                    }
                    
                    Box(
                        modifier = Modifier.weight(1f),
                        contentAlignment = Alignment.Center
                    ) {
                        StatCard(
                            title = "Sessions",
                            value = "$totalSessions",
                            icon = Icons.Default.PlayCircle
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ProgressCard(
    title: String,
    value: String,
    color: Color,
    icon: ImageVector
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                color = color.copy(alpha = 0.1f),
                shape = MaterialTheme.shapes.medium
            ).padding(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(24.dp),
            tint = color
        )
        
        Text(
            text = value,
            style = Typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = color,
            textAlign = TextAlign.Center
        )
        
        Text(
            text = title,
            style = Typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun StatCard(
    title: String,
    value: String,
    icon: ImageVector
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                color = MaterialTheme.colorScheme.surfaceVariant,
                shape = MaterialTheme.shapes.medium
            )
            .padding(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        
        Text(
            text = value,
            style = Typography.titleSmall,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center
        )
        
        Text(
            text = title,
            style = Typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun QuizResultsSection(
    recentQuizResults: List<QuizResult>,
    onNavigateToQuizResults: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Recent Quiz Results",
                    style = Typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                
                if (recentQuizResults.size > 3) {
                    TextButton(onClick = onNavigateToQuizResults) {
                        Text(
                            text = "View All",
                            style = Typography.bodySmall,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }

            if (recentQuizResults.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(120.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            Icons.Default.BarChart,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = "No Quiz Results Yet",
                            style = Typography.titleSmall,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = "Complete your first quiz to see results here",
                            style = Typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            } else {
                Column(
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    recentQuizResults.take(3).forEach { result ->
                        QuizResultRow(result = result)
                    }
                }
            }
        }
    }
}

@Composable
private fun QuizResultRow(result: QuizResult) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = result.quizType.capitalize(),
                    style = Typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = result.date,
                    style = Typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            Column(
                horizontalAlignment = Alignment.End
            ) {
                Text(
                    text = "${result.score} pts",
                    style = Typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = "${(result.score.toFloat() / result.totalWords * 100).toInt()}%",
                    style = Typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}



@Composable
private fun VocabularyGrowthSection(
    chartData: List<ChartDataPoint>,
    selectedPeriod: ChartPeriod,
    onPeriodChanged: (ChartPeriod) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Vocabulary Growth",
                    style = Typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                
                // Dropdown menu like iOS
                var expanded by remember { mutableStateOf(false) }
                Box {
                    TextButton(
                        onClick = { expanded = true }
                    ) {
                        Text(
                            text = selectedPeriod.displayName,
                            style = Typography.bodySmall,
                            color = MaterialTheme.colorScheme.primary
                        )
                        Icon(
                            Icons.Default.ArrowDropDown,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                    
                    DropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        ChartPeriod.values().forEach { period ->
                            DropdownMenuItem(
                                text = { Text(period.displayName) },
                                onClick = {
                                    onPeriodChanged(period)
                                    expanded = false
                                }
                            )
                        }
                    }
                }
            }

            if (chartData.isNotEmpty()) {
                Column(
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Last ${selectedPeriod.displayName.lowercase()}",
                        style = Typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    VocabularyLineChart(
                        data = chartData,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            } else {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(200.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            Icons.Default.ShowChart,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = "No Growth Data Yet",
                            style = Typography.titleSmall,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = "Complete quizzes to see your vocabulary growth over time",
                            style = Typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
        }
    }
}





data class ProgressAnalyticsUiState(
    val inProgress: Int = 0,
    val mastered: Int = 0,
    val needsReview: Int = 0,
    val totalPracticeTime: Double = 0.0,
    val averageAccuracy: Double = 0.0,
    val totalSessions: Int = 0,
    val vocabularyGrowthData: List<ChartDataPoint> = emptyList(),
    val selectedPeriod: ChartPeriod = ChartPeriod.Week,
    val recentQuizResults: List<QuizResult> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

data class ChartDataPoint(
    val date: String,
    val value: Int
)

data class QuizResult(
    val quizType: String,
    val score: Int,
    val totalWords: Int,
    val date: String
)

enum class ChartPeriod(val displayName: String) {
    Week("Week"),
    Month("Month"),
    Year("Year")
} 