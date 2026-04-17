package com.nateb.mymedtimer.feature.medlist

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MedListScreen(
    onAddMed: () -> Unit,
    onEditMed: (String) -> Unit,
    viewModel: MedListViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }

    // Show toast via snackbar
    LaunchedEffect(state.toastMessage) {
        state.toastMessage?.let { message ->
            snackbarHostState.showSnackbar(message)
        }
    }

    // Log dose confirmation dialog
    state.loggingMedication?.let { med ->
        val title = if (med.isPRN && !MedListViewModel.canTakePRN(med, state.now)) {
            val mins = MedListViewModel.minutesUntilCanTake(med, state.now)
            "${med.name} \u2014 wait ${mins}m before next dose"
        } else {
            med.name
        }

        AlertDialog(
            onDismissRequest = { viewModel.dismissLogDialog() },
            title = { Text(title) },
            text = null,
            confirmButton = {
                if (med.isPRN) {
                    val canTake = MedListViewModel.canTakePRN(med, state.now)
                    TextButton(onClick = { viewModel.logDose("taken") }) {
                        Text(if (canTake) "Take now" else "Take anyway")
                    }
                } else {
                    Column {
                        TextButton(onClick = { viewModel.logDose("taken") }) {
                            Text("Taken")
                        }
                        TextButton(onClick = { viewModel.logDose("skipped") }) {
                            Text("Skipped")
                        }
                        TextButton(onClick = { viewModel.logDose("snoozed") }) {
                            Text("Snooze")
                        }
                    }
                }
            },
            dismissButton = {
                TextButton(onClick = { viewModel.dismissLogDialog() }) {
                    Text("Cancel")
                }
            },
        )
    }

    // Delete confirmation dialog
    state.deletingMedication?.let { med ->
        AlertDialog(
            onDismissRequest = { viewModel.dismissDeleteDialog() },
            title = { Text("Delete ${med.name}?") },
            text = { Text("This will remove all schedules and dose history for this medication.") },
            confirmButton = {
                TextButton(onClick = { viewModel.deleteMedication() }) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { viewModel.dismissDeleteDialog() }) {
                    Text("Cancel")
                }
            },
        )
    }

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(onClick = onAddMed) {
                Icon(Icons.Default.Add, contentDescription = "Add medication")
            }
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { innerPadding ->
        if (state.medications.isEmpty()) {
            // Empty state
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Text(
                    text = "no meds",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Spacer(modifier = Modifier.height(16.dp))
                TextButton(onClick = onAddMed) {
                    Text("+ add medication")
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
            ) {
                items(
                    items = state.medications,
                    key = { it.id },
                ) { med ->
                    val dismissState = rememberSwipeToDismissBoxState(
                        confirmValueChange = { value ->
                            when (value) {
                                SwipeToDismissBoxValue.EndToStart -> {
                                    viewModel.showDeleteDialog(med)
                                    false // Don't actually dismiss, show dialog
                                }
                                SwipeToDismissBoxValue.StartToEnd -> {
                                    onEditMed(med.id)
                                    false
                                }
                                SwipeToDismissBoxValue.Settled -> false
                            }
                        },
                    )

                    SwipeToDismissBox(
                        state = dismissState,
                        backgroundContent = {
                            val direction = dismissState.dismissDirection
                            val color by animateColorAsState(
                                when (direction) {
                                    SwipeToDismissBoxValue.EndToStart -> Color(0xFFFF5252)
                                    SwipeToDismissBoxValue.StartToEnd -> Color(0xFF757575)
                                    else -> Color.Transparent
                                },
                                label = "swipe_bg",
                            )
                            val icon = when (direction) {
                                SwipeToDismissBoxValue.EndToStart -> Icons.Default.Delete
                                SwipeToDismissBoxValue.StartToEnd -> Icons.Default.Edit
                                else -> Icons.Default.Edit
                            }
                            val alignment = when (direction) {
                                SwipeToDismissBoxValue.EndToStart -> Alignment.CenterEnd
                                else -> Alignment.CenterStart
                            }

                            Box(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .background(color)
                                    .padding(horizontal = 20.dp),
                                contentAlignment = alignment,
                            ) {
                                Icon(icon, contentDescription = null, tint = Color.White)
                            }
                        },
                    ) {
                        val prnWarning = if (med.isPRN && !MedListViewModel.canTakePRN(med, state.now)) {
                            "wait ${MedListViewModel.minutesUntilCanTake(med, state.now)}m"
                        } else {
                            null
                        }

                        MedRowCard(
                            name = med.name,
                            dosage = med.dosage,
                            colorHex = med.colorHex,
                            isPRN = med.isPRN,
                            nextDoseTime = if (med.isPRN) null else MedListViewModel.nextDoseTime(med, state.now),
                            lastTakenTime = if (med.isPRN) MedListViewModel.lastTakenTime(med) else null,
                            prnWarning = prnWarning,
                            now = state.now,
                            riskLevel = state.insights[med.id]?.riskLevel,
                            onClick = { viewModel.showLogDialog(med) },
                            modifier = Modifier.background(MaterialTheme.colorScheme.surface),
                        )
                    }

                    HorizontalDivider(
                        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
                    )
                }
            }
        }
    }
}
