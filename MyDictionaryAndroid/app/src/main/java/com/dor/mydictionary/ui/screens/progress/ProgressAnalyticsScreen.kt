package com.dor.mydictionary.ui.screens.progress

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
                title = { Text("Progress", style = Typography.displaySmall) },
                actions = {
                    IconButton(onClick = { viewModel.refreshData() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
                    }
                }
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
                contentPadding = PaddingValues(24.dp),
                verticalArrangement = Arrangement.spacedBy(24.dp)
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
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Progress Overview",
                style = Typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            // Progress Cards Grid
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Box(modifier = Modifier.weight(1f)) {
                    ProgressCard(
                        title = "In Progress",
                        value = "$inProgress",
                        color = MaterialTheme.colorScheme.primary,
                        icon = Icons.Default.Schedule
                    )
                }
                
                Box(modifier = Modifier.weight(1f)) {
                    ProgressCard(
                        title = "Mastered",
                        value = "$mastered",
                        color = MaterialTheme.colorScheme.primary,
                        icon = Icons.Default.CheckCircle
                    )
                }
                
                Box(modifier = Modifier.weight(1f)) {
                    ProgressCard(
                        title = "Need Review",
                        value = "$needsReview",
                        color = MaterialTheme.colorScheme.primary,
                        icon = Icons.Default.Warning
                    )
                }
            }

            // Stats Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Box(modifier = Modifier.weight(1f)) {
                    StatCard(
                        title = "Practice Time",
                        value = "${totalPracticeTime.toInt()} min",
                        icon = Icons.Default.Timer
                    )
                }
                
                Box(modifier = Modifier.weight(1f)) {
                    StatCard(
                        title = "Accuracy",
                        value = "${(averageAccuracy * 100).toInt()}%",
                        icon = Icons.Default.TrackChanges
                    )
                }
                
                Box(modifier = Modifier.weight(1f)) {
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

@Composable
private fun ProgressCard(
    title: String,
    value: String,
    color: Color,
    icon: ImageVector
) {
    Column(
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
            fontWeight = FontWeight.Bold
        )
        
        Text(
            text = title,
            style = Typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
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
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        
        Text(
            text = value,
            style = Typography.bodySmall,
            fontWeight = FontWeight.Medium
        )
        
        Text(
            text = title,
            style = Typography.bodySmall.copy(fontSize = 10.sp),
            color = MaterialTheme.colorScheme.onSurfaceVariant
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
            modifier = Modifier.padding(20.dp),
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
                            textAlign = androidx.compose.ui.text.style.TextAlign.Center
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
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            Text(
                text = result.quizType.capitalize(),
                style = Typography.titleSmall,
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
                text = "${result.score}",
                style = Typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = getScoreColor(result.score, result.totalWords)
            )
            Text(
                text = "${result.score}/${result.totalWords}",
                style = Typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun getScoreColor(score: Int, totalWords: Int): Color {
    val accuracy = if (totalWords > 0) score.toFloat() / totalWords else 0f
    return when {
        accuracy >= 0.8f -> MaterialTheme.colorScheme.primary
        accuracy >= 0.6f -> Color(0xFFFF9800) // Orange
        else -> MaterialTheme.colorScheme.error
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
            modifier = Modifier.padding(20.dp),
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
                
                Row {
                    ChartPeriod.values().forEach { period ->
                        FilterChip(
                            onClick = { onPeriodChanged(period) },
                            label = { Text(period.displayName) },
                            selected = selectedPeriod == period
                        )
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
                    
                    // TODO: Implement actual chart component
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(200.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "Chart: ${chartData.size} data points",
                            style = Typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
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
                            textAlign = androidx.compose.ui.text.style.TextAlign.Center
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