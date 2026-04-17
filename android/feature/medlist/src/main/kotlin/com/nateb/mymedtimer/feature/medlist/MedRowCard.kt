package com.nateb.mymedtimer.feature.medlist

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.nateb.mymedtimer.common.TimeFormatting
import com.nateb.mymedtimer.common.toComposeColor
import com.nateb.mymedtimer.math.RiskLevel
import java.time.Duration
import java.time.Instant

@Composable
fun MedRowCard(
    name: String,
    dosage: String,
    colorHex: String,
    isPRN: Boolean,
    nextDoseTime: Instant?,
    lastTakenTime: Instant?,
    prnWarning: String?,
    now: Instant,
    riskLevel: RiskLevel?,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val countdownText = when {
        isPRN -> null
        nextDoseTime != null -> {
            val seconds = Duration.between(now, nextDoseTime).seconds
            TimeFormatting.countdown(seconds)
        }
        else -> "--"
    }

    val isUrgent = if (!isPRN && nextDoseTime != null) {
        Duration.between(now, nextDoseTime).seconds < 300
    } else {
        false
    }

    val accessibilityDesc = buildString {
        append(name)
        if (dosage.isNotEmpty()) append(", $dosage")
        if (isPRN) {
            append(", as needed")
            if (prnWarning != null) {
                append(", $prnWarning")
            } else if (lastTakenTime != null) {
                val elapsed = Duration.between(lastTakenTime, now).seconds
                append(", last taken ${TimeFormatting.countdown(elapsed)} ago")
            } else {
                append(", not taken")
            }
        } else if (nextDoseTime != null) {
            val seconds = Duration.between(now, nextDoseTime).seconds
            if (seconds < 0) {
                append(", overdue")
            } else {
                append(", next dose in ${TimeFormatting.countdown(seconds)}")
            }
        }
    }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 12.dp, horizontal = 16.dp)
            .semantics { contentDescription = accessibilityDesc },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // Color bar
        Box(
            modifier = Modifier
                .width(6.dp)
                .height(48.dp)
                .clip(RoundedCornerShape(4.dp))
                .background(colorHex.toComposeColor()),
        )

        Spacer(modifier = Modifier.width(12.dp))

        // Name + dosage
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = name,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface,
            )
            if (dosage.isNotEmpty()) {
                Text(
                    text = dosage,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }

        // Countdown / PRN status
        if (isPRN) {
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "PRN",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                when {
                    prnWarning != null -> {
                        Text(
                            text = prnWarning,
                            style = MaterialTheme.typography.bodySmall,
                            color = Color(0xFFFF9800),
                        )
                    }
                    lastTakenTime != null -> {
                        val elapsed = Duration.between(lastTakenTime, now).seconds
                        Text(
                            text = "${TimeFormatting.countdown(elapsed)} ago",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    else -> {
                        Text(
                            text = "not taken",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }
        } else if (countdownText != null) {
            Text(
                text = countdownText,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = if (isUrgent) Color(0xFFFF5252) else MaterialTheme.colorScheme.onSurface,
            )
        }

        // Risk indicator
        if (riskLevel != null && riskLevel >= RiskLevel.MEDIUM) {
            Spacer(modifier = Modifier.width(8.dp))
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(
                        if (riskLevel == RiskLevel.HIGH) Color(0xFFFF5252) else Color(0xFFFFEB3B)
                    ),
            )
        }
    }
}
