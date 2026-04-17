package com.nateb.mymedtimer.feature.addedit

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TimePicker
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nateb.mymedtimer.common.TimeFormatting
import com.nateb.mymedtimer.common.toComposeColor
import com.nateb.mymedtimer.math.RiskLevel

private val colorOptions = listOf(
    "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
    "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F",
)

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun AddEditScreen(
    onNavigateBack: () -> Unit,
    viewModel: AddEditViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }
    var showTimePicker by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is AddEditEvent.Saved -> onNavigateBack()
                is AddEditEvent.Error -> snackbarHostState.showSnackbar(event.message)
            }
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { Text(if (state.isEditMode) "Edit Medication" else "Add Medication") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            // Name
            OutlinedTextField(
                value = state.name,
                onValueChange = viewModel::onNameChange,
                label = { Text("Medication Name") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )

            // Dosage
            OutlinedTextField(
                value = state.dosage,
                onValueChange = viewModel::onDosageChange,
                label = { Text("Dosage (e.g. 500mg)") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )

            // Color picker
            Text("Color", style = MaterialTheme.typography.labelLarge)
            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                colorOptions.forEach { hex ->
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(CircleShape)
                            .background(hex.toComposeColor())
                            .then(
                                if (hex == state.colorHex) {
                                    Modifier.border(3.dp, MaterialTheme.colorScheme.primary, CircleShape)
                                } else {
                                    Modifier
                                }
                            )
                            .clickable { viewModel.onColorChange(hex) },
                    )
                }
            }

            // PRN toggle
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column {
                    Text("As-needed (PRN)", style = MaterialTheme.typography.bodyLarge)
                    Text(
                        "Take only when needed, not on a schedule",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                Switch(
                    checked = state.isPRN,
                    onCheckedChange = viewModel::onIsPRNChange,
                )
            }

            // Schedule times (hidden for PRN)
            if (!state.isPRN) {
                Text("Schedule Times", style = MaterialTheme.typography.labelLarge)
                state.scheduleTimes.forEachIndexed { index, time ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            TimeFormatting.timeOfDay(time.hour, time.minute),
                            style = MaterialTheme.typography.bodyLarge,
                        )
                        IconButton(onClick = { viewModel.onRemoveScheduleTime(index) }) {
                            Icon(Icons.Default.Close, contentDescription = "Remove time")
                        }
                    }
                }
                Button(onClick = { showTimePicker = true }) {
                    Icon(Icons.Default.Add, contentDescription = null)
                    Spacer(Modifier.width(4.dp))
                    Text("Add Time")
                }
            } else {
                // Min interval for PRN
                OutlinedTextField(
                    value = if (state.minIntervalMinutes > 0) state.minIntervalMinutes.toString() else "",
                    onValueChange = { text ->
                        viewModel.onMinIntervalChange(text.toIntOrNull() ?: 0)
                    },
                    label = { Text("Minimum interval (minutes)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
            }

            // Adherence insight card (edit mode only)
            val insight = state.insight
            if (state.isEditMode && insight != null) {
                InsightCard(insight)
            }

            // Save button
            Spacer(Modifier.height(8.dp))
            Button(
                onClick = viewModel::onSave,
                enabled = !state.isSaving,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(if (state.isSaving) "Saving..." else "Save")
            }
        }
    }

    // Time picker dialog
    if (showTimePicker) {
        TimePickerDialog(
            onDismiss = { showTimePicker = false },
            onConfirm = { hour, minute ->
                viewModel.onAddScheduleTime(hour, minute)
                showTimePicker = false
            },
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TimePickerDialog(
    onDismiss: () -> Unit,
    onConfirm: (hour: Int, minute: Int) -> Unit,
) {
    val timePickerState = rememberTimePickerState()

    Dialog(onDismissRequest = onDismiss) {
        Card {
            Column(
                modifier = Modifier.padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text("Select Time", style = MaterialTheme.typography.titleMedium)
                Spacer(Modifier.height(16.dp))
                TimePicker(state = timePickerState)
                Spacer(Modifier.height(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End,
                ) {
                    Button(onClick = onDismiss) {
                        Text("Cancel")
                    }
                    Spacer(Modifier.width(8.dp))
                    Button(onClick = { onConfirm(timePickerState.hour, timePickerState.minute) }) {
                        Text("OK")
                    }
                }
            }
        }
    }
}

@Composable
private fun InsightCard(insight: com.nateb.mymedtimer.math.MedicationInsight) {
    val riskColor = when (insight.riskLevel) {
        RiskLevel.LOW -> MaterialTheme.colorScheme.primary
        RiskLevel.MEDIUM -> MaterialTheme.colorScheme.tertiary
        RiskLevel.HIGH -> MaterialTheme.colorScheme.error
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant,
        ),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Adherence Insight", style = MaterialTheme.typography.titleSmall)
            Spacer(Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text("Risk Level")
                Text(
                    insight.riskLevel.name,
                    color = riskColor,
                    style = MaterialTheme.typography.bodyMedium,
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text("Consistency")
                Text("${insight.consistencyScore}%")
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text("Miss Probability")
                Text("${(insight.missProbability * 100).toInt()}%")
            }

            val suggestedTime = insight.suggestedTime
            if (suggestedTime != null) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Text("Suggested Time")
                    Text(
                        TimeFormatting.timeOfDay(
                            suggestedTime.first,
                            suggestedTime.second,
                        )
                    )
                }
            }

            val drift = insight.timeDriftMinutes
            if (drift != null && drift != 0) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Text("Time Drift")
                    val driftText = if (drift > 0) {
                        "+${drift}m"
                    } else {
                        "${drift}m"
                    }
                    Text(driftText)
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text("Recommended Alert")
                Text(insight.recommendedAlertStyle.replaceFirstChar { it.uppercase() })
            }
        }
    }
}
