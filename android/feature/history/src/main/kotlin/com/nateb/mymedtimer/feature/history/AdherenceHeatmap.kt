package com.nateb.mymedtimer.feature.history

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.unit.dp
import java.time.format.TextStyle
import java.util.Locale

@Composable
fun AdherenceHeatmap(
    data: List<DayAdherence>,
    modifier: Modifier = Modifier
) {
    if (data.isEmpty()) return

    val emptyColor = MaterialTheme.colorScheme.surfaceVariant
    val fullColor = MaterialTheme.colorScheme.primary

    Column(modifier = modifier.padding(horizontal = 16.dp)) {
        Text(
            text = "Adherence — last 12 weeks",
            style = MaterialTheme.typography.titleSmall,
            color = MaterialTheme.colorScheme.onSurface
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Month labels
        val months = data.mapNotNull { day ->
            if (day.date.dayOfMonth == 1 || day == data.first()) {
                day.date.month.getDisplayName(TextStyle.SHORT, Locale.getDefault())
            } else null
        }.distinct()

        Text(
            text = months.joinToString("   "),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(4.dp))

        // Grid: 7 rows (days of week) x 12 columns (weeks)
        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .height(112.dp)
        ) {
            val cellSize = size.width / 13f // 12 weeks + spacing
            val cellPadding = 2.dp.toPx()
            val actualCellSize = cellSize - cellPadding

            data.forEachIndexed { index, day ->
                val week = index / 7
                val dayOfWeek = index % 7

                val color = when {
                    day.total == 0 -> emptyColor
                    else -> lerp(emptyColor, fullColor, day.ratio)
                }

                drawRect(
                    color = color,
                    topLeft = Offset(
                        x = week * cellSize,
                        y = dayOfWeek * (actualCellSize + cellPadding)
                    ),
                    size = Size(actualCellSize, actualCellSize)
                )
            }
        }
    }
}
