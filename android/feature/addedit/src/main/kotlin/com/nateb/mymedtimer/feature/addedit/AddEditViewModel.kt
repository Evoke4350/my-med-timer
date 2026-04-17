package com.nateb.mymedtimer.feature.addedit

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.nateb.mymedtimer.domain.model.Medication
import com.nateb.mymedtimer.domain.model.ScheduleTime
import com.nateb.mymedtimer.domain.repository.MedicationRepository
import com.nateb.mymedtimer.math.AdherenceEngine
import com.nateb.mymedtimer.math.MedicationInsight
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.Instant
import java.util.UUID
import javax.inject.Inject

data class AddEditUiState(
    val name: String = "",
    val dosage: String = "",
    val colorHex: String = "#FF6B6B",
    val alertStyle: String = "gentle",
    val isPRN: Boolean = false,
    val minIntervalMinutes: Int = 0,
    val scheduleTimes: List<ScheduleTime> = emptyList(),
    val isEditMode: Boolean = false,
    val insight: MedicationInsight? = null,
    val isSaving: Boolean = false,
)

sealed interface AddEditEvent {
    data object Saved : AddEditEvent
    data class Error(val message: String) : AddEditEvent
}

@HiltViewModel
class AddEditViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val repository: MedicationRepository,
) : ViewModel() {

    private val medId: String? = savedStateHandle.get<String>("medId")

    private val _uiState = MutableStateFlow(AddEditUiState())
    val uiState: StateFlow<AddEditUiState> = _uiState.asStateFlow()

    private val _events = MutableSharedFlow<AddEditEvent>()
    val events: SharedFlow<AddEditEvent> = _events.asSharedFlow()

    init {
        if (medId != null) {
            viewModelScope.launch {
                val med = repository.getMedication(medId).firstOrNull() ?: return@launch
                _uiState.update {
                    it.copy(
                        name = med.name,
                        dosage = med.dosage,
                        colorHex = med.colorHex,
                        alertStyle = med.alertStyle,
                        isPRN = med.isPRN,
                        minIntervalMinutes = med.minIntervalMinutes,
                        scheduleTimes = med.scheduleTimes,
                        isEditMode = true,
                    )
                }

                // Compute adherence insight from dose logs
                val missTimestamps = med.doseLogs
                    .filter { it.status == "skipped" }
                    .map { it.scheduledTime }
                val takenTimestamps = med.doseLogs
                    .filter { it.status == "taken" }
                    .mapNotNull { it.actualTime }
                val firstSchedule = med.scheduleTimes.firstOrNull()
                val insight = AdherenceEngine.analyze(
                    missTimestamps = missTimestamps,
                    takenTimestamps = takenTimestamps,
                    scheduledHour = firstSchedule?.hour,
                    scheduledMinute = firstSchedule?.minute,
                    recentEscalationCount = 0,
                    now = Instant.now(),
                )
                _uiState.update { it.copy(insight = insight) }
            }
        }
    }

    fun onNameChange(name: String) {
        _uiState.update { it.copy(name = name) }
    }

    fun onDosageChange(dosage: String) {
        _uiState.update { it.copy(dosage = dosage) }
    }

    fun onColorChange(colorHex: String) {
        _uiState.update { it.copy(colorHex = colorHex) }
    }

    fun onAlertStyleChange(alertStyle: String) {
        _uiState.update { it.copy(alertStyle = alertStyle) }
    }

    fun onIsPRNChange(isPRN: Boolean) {
        _uiState.update { it.copy(isPRN = isPRN) }
    }

    fun onMinIntervalChange(minutes: Int) {
        _uiState.update { it.copy(minIntervalMinutes = minutes) }
    }

    fun onAddScheduleTime(hour: Int, minute: Int) {
        _uiState.update {
            it.copy(scheduleTimes = it.scheduleTimes + ScheduleTime(hour, minute))
        }
    }

    fun onRemoveScheduleTime(index: Int) {
        _uiState.update {
            it.copy(scheduleTimes = it.scheduleTimes.toMutableList().apply { removeAt(index) })
        }
    }

    fun onSave() {
        val state = _uiState.value
        if (state.name.isBlank()) {
            viewModelScope.launch {
                _events.emit(AddEditEvent.Error("Name is required"))
            }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true) }
            try {
                val medication = Medication(
                    id = medId ?: UUID.randomUUID().toString(),
                    name = state.name.trim(),
                    dosage = state.dosage.trim(),
                    colorHex = state.colorHex,
                    alertStyle = state.insight?.recommendedAlertStyle ?: state.alertStyle,
                    isPRN = state.isPRN,
                    minIntervalMinutes = state.minIntervalMinutes,
                    scheduleTimes = state.scheduleTimes,
                )
                repository.saveMedication(medication)
                _events.emit(AddEditEvent.Saved)
            } catch (e: Exception) {
                _events.emit(AddEditEvent.Error(e.message ?: "Save failed"))
            } finally {
                _uiState.update { it.copy(isSaving = false) }
            }
        }
    }
}
