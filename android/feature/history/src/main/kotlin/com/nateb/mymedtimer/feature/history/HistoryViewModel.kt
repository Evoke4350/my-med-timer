package com.nateb.mymedtimer.feature.history

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.nateb.mymedtimer.domain.model.DoseLog
import com.nateb.mymedtimer.domain.model.Medication
import com.nateb.mymedtimer.domain.repository.MedicationRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import javax.inject.Inject

data class DayAdherence(
    val date: LocalDate,
    val taken: Int,
    val total: Int
) {
    val ratio: Float get() = if (total == 0) 0f else taken.toFloat() / total
}

data class HistoryEntry(
    val medication: Medication,
    val log: DoseLog
)

data class HistoryUiState(
    val entries: List<HistoryEntry> = emptyList(),
    val heatmapData: List<DayAdherence> = emptyList(),
    val selectedMedId: String? = null,
    val medications: List<Medication> = emptyList()
)

@HiltViewModel
class HistoryViewModel @Inject constructor(
    private val repository: MedicationRepository
) : ViewModel() {

    private val selectedMedId = MutableStateFlow<String?>(null)

    val uiState: StateFlow<HistoryUiState> = combine(
        repository.getAllMedications(),
        selectedMedId
    ) { medications, filterId ->
        val filtered = if (filterId != null) {
            medications.filter { it.id == filterId }
        } else {
            medications
        }

        val entries = filtered.flatMap { med ->
            med.doseLogs.map { log -> HistoryEntry(med, log) }
        }.sortedByDescending { it.log.scheduledTime }

        val zone = ZoneId.systemDefault()
        val today = LocalDate.now(zone)
        val startDate = today.minusDays(83) // 12 weeks = 84 days

        val logsByDate = filtered.flatMap { it.doseLogs }.groupBy { log ->
            log.scheduledTime.atZone(zone).toLocalDate()
        }

        val heatmapData = (0L..83L).map { offset ->
            val date = startDate.plusDays(offset)
            val logs = logsByDate[date] ?: emptyList()
            val taken = logs.count { it.status == "taken" }
            DayAdherence(date, taken, logs.size)
        }

        HistoryUiState(
            entries = entries,
            heatmapData = heatmapData,
            selectedMedId = filterId,
            medications = medications
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), HistoryUiState())

    fun selectMedication(medId: String?) {
        selectedMedId.value = medId
    }
}
