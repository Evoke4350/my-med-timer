package com.nateb.mymedtimer.feature.settings

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import javax.inject.Inject

data class SettingsUiState(
    val defaultSnoozeMinutes: Int = 10,
    val nagIntervalMinutes: Int = 5,
    val defaultAlertStyle: String = "gentle",
    val notificationsEnabled: Boolean = false,
    val appVersion: String = ""
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    init {
        _uiState.update {
            it.copy(
                notificationsEnabled = checkNotificationPermission(),
                appVersion = getAppVersion()
            )
        }
    }

    fun updateSnoozeMinutes(minutes: Int) {
        _uiState.update { it.copy(defaultSnoozeMinutes = minutes) }
        // TODO: persist via PreferencesDataStore (wired in Plan 5)
    }

    fun updateNagInterval(minutes: Int) {
        _uiState.update { it.copy(nagIntervalMinutes = minutes) }
        // TODO: persist via PreferencesDataStore (wired in Plan 5)
    }

    fun updateAlertStyle(style: String) {
        _uiState.update { it.copy(defaultAlertStyle = style) }
        // TODO: persist via PreferencesDataStore (wired in Plan 5)
    }

    fun refreshNotificationStatus() {
        _uiState.update { it.copy(notificationsEnabled = checkNotificationPermission()) }
    }

    private fun checkNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun getAppVersion(): String {
        return try {
            val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
            packageInfo.versionName ?: "unknown"
        } catch (_: PackageManager.NameNotFoundException) {
            "unknown"
        }
    }
}
