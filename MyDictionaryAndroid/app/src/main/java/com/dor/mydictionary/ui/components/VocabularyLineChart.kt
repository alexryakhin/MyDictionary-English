package com.dor.mydictionary.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.dor.mydictionary.ui.screens.progress.ChartDataPoint

@Composable
fun VocabularyLineChart(
    data: List<ChartDataPoint>,
    modifier: Modifier = Modifier
) {
    val primaryColor = MaterialTheme.colorScheme.primary
    if (data.isEmpty()) {
        Box(
            modifier = modifier.height(200.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "No data available",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        return
    }

    val maxValue = data.maxOfOrNull { it.value } ?: 1
    val minValue = data.minOfOrNull { it.value } ?: 0
    val valueRange = maxValue - minValue

    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // Chart
        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .height(200.dp)
        ) {
            val width = size.width
            val height = size.height
            val padding = 40f

            val chartWidth = width - (padding * 2)
            val chartHeight = height - (padding * 2)

            // Draw grid lines
            val gridLines = 5
            for (i in 0..gridLines) {
                val y = padding + (chartHeight / gridLines) * i
                drawLine(
                    color = Color.Gray.copy(alpha = 0.3f),
                    start = Offset(padding, y),
                    end = Offset(width - padding, y),
                    strokeWidth = 1f
                )
            }

            // Draw data points and line
            if (data.size > 1) {
                val path = Path()
                val points = mutableListOf<Offset>()

                data.forEachIndexed { index, point ->
                    val x = padding + (chartWidth / (data.size - 1)) * index
                    val normalizedValue = if (valueRange > 0) {
                        (point.value - minValue).toFloat() / valueRange
                    } else {
                        0.5f
                    }
                    val y = height - padding - (chartHeight * normalizedValue)
                    
                    points.add(Offset(x, y))
                }

                // Draw line
                if (points.isNotEmpty()) {
                    path.moveTo(points.first().x, points.first().y)
                    points.drop(1).forEach { point ->
                        path.lineTo(point.x, point.y)
                    }

                    drawPath(
                        path = path,
                        color = primaryColor,
                        style = Stroke(
                            width = 3f,
                            cap = StrokeCap.Round
                        )
                    )
                }

                // Draw data points
                points.forEach { point ->
                    drawCircle(
                        color = primaryColor,
                        radius = 4f,
                        center = point
                    )
                }
            }

            // Note: Axis labels are drawn outside the Canvas using Text composables
        }

        // Axis labels
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = "$minValue words",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Text(
                text = "$maxValue words",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
} 