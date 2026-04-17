package com.nateb.mymedtimer.feature.medlist

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.nateb.mymedtimer.domain.model.Medication
import com.nateb.mymedtimer.domain.repository.MedicationRepository
import com.nateb.mymedtimer.math.AdherenceEngine
import com.nateb.mymedtimer.math.MedicationInsight
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.time.Duration
import java.time.Instant
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZonedDateTime
import javax.inject.Inject

data class MedListUiState(
    val medications: List<Medication> = emptyList(),
    val insights: Map<String, MedicationInsight> = emptyMap(),
    val now: Instant = Instant.now(),
    val toastMessage: String? = null,
    val loggingMedication: Medication? = null,
    val deletingMedication: Medication? = null,
)

@HiltViewModel
class MedListViewModel @Inject constructor(
    private val repository: MedicationRepository,
) : ViewModel() {

    private val _now = MutableStateFlow(Instant.now())
    private val _insights = MutableStateFlow<Map<String, MedicationInsight>>(emptyMap())
    private val _toastMessage = MutableStateFlow<String?>(null)
    private val _loggingMedication = MutableStateFlow<Medication?>(null)
    private val _deletingMedication = MutableStateFlow<Medication?>(null)

    private val _dialogState = combine(
        _toastMessage,
        _loggingMedication,
        _deletingMedication,
    ) { toast, logging, deleting ->
        Triple(toast, logging, deleting)
    }

    val uiState: StateFlow<MedListUiState> = combine(
        repository.getAllMedications(),
        _insights,
        _now,
        _dialogState,
    ) { medications, insights, now, (toast, logging, deleting) ->
        val sorted = sortedByNextDose(medications.filter { it.isActive }, now)
        MedListUiState(
            medications = sorted,
            insights = insights,
            now = now,
            toastMessage = toast,
            loggingMedication = logging,
            deletingMedication = deleting,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), MedListUiState())

    init {
        // Tick every second for countdown timers
        viewModelScope.launch {
            while (isActive) {
                _now.value = Instant.now()
                delay(1000)
            }
        }
        // Refresh insights when medications change
        viewModelScope.launch {
            repository.getAllMedications().collect { medications ->
                refreshInsights(medications)
            }
        }
        // Refresh insights every 60 seconds
        viewModelScope.launch {
            while (isActive) {
                delay(60_000)
                val meds = uiState.value.medications
                refreshInsights(meds)
            }
        }
    }

    fun showLogDialog(medication: Medication) {
        _loggingMedication.value = medication
    }

    fun dismissLogDialog() {
        _loggingMedication.value = null
    }

    fun showDeleteDialog(medication: Medication) {
        _deletingMedication.value = medication
    }

    fun dismissDeleteDialog() {
        _deletingMedication.value = null
    }

    fun logDose(status: String) {
        val med = _loggingMedication.value ?: return
        val scheduledTime = nextDoseTime(med, _now.value) ?: _now.value
        viewModelScope.launch {
            repository.logDose(med.id, scheduledTime, status)
            _loggingMedication.value = null

            val label = when (status) {
                "taken" -> "${med.name} \u2014 taken"
                "skipped" -> "${med.name} \u2014 skipped"
                "snoozed" -> "${med.name} \u2014 snoozed"
                else -> med.name
            }
            _toastMessage.value = label
            delay(2000)
            _toastMessage.value = null
        }
    }

    fun deleteMedication() {
        val med = _deletingMedication.value ?: return
        viewModelScope.launch {
            repository.deleteMedication(med.id)
            _deletingMedication.value = null
        }
    }

    private fun refreshInsights(medications: List<Medication>) {
        val now = Instant.now()
        val results = medications.filter { it.isActive }.associate { med ->
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
                now = now,
            )
            med.id to insight
        }
        _insights.value = results
    }

    companion object {
        fun nextDoseTime(medication: Medication, now: Instant): Instant? {
            val times = medication.scheduleTimes
            if (times.isEmpty()) return null

            val zone = ZoneId.systemDefault()
            val today = now.atZone(zone).toLocalDate()

            // Check today's remaining times
            val nowTime = now.atZone(zone).toLocalTime()
            val todayCandidates = times
                .map { LocalTime.of(it.hour, it.minute) }
                .filter { it.isAfter(nowTime) }
                .map { ZonedDateTime.of(today, it, zone).toInstant() }

            if (todayCandidates.isNotEmpty()) {
                return todayCandidates.min()
            }

            // Use earliest time tomorrow
            val tomorrow = today.plusDays(1)
            return times
                .map { ZonedDateTime.of(tomorrow, LocalTime.of(it.hour, it.minute), zone).toInstant() }
                .minOrNull()
        }

        fun lastTakenTime(medication: Medication): Instant? {
            return medication.doseLogs
                .filter { it.status == "taken" }
                .mapNotNull { it.actualTime }
                .maxOrNull()
        }

        fun canTakePRN(medication: Medication, now: Instant): Boolean {
            if (!medication.isPRN || medication.minIntervalMinutes <= 0) return true
            val last = lastTakenTime(medication) ?: return true
            val elapsed = Duration.between(last, now).seconds
            return elapsed >= medication.minIntervalMinutes * 60L
        }

        fun minutesUntilCanTake(medication: Medication, now: Instant): Int {
            if (!medication.isPRN || medication.minIntervalMinutes <= 0) return 0
            val last = lastTakenTime(medication) ?: return 0
            val elapsed = Duration.between(last, now).seconds
            val remaining = medication.minIntervalMinutes * 60L - elapsed
            return if (remaining > 0) ((remaining + 59) / 60).toInt() else 0
        }

        fun sortedByNextDose(medications: List<Medication>, now: Instant): List<Medication> {
            return medications.sortedBy { nextDoseTime(it, now) ?: Instant.MAX }
        }
    }
}
