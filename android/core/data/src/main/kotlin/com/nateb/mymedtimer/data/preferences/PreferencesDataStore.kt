package com.nateb.mymedtimer.data.preferences

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

data class AppSettings(
    val defaultSnoozeMinutes: Int = 10,
    val nagIntervalMinutes: Int = 5,
    val defaultAlertStyle: String = "gentle"
)

class PreferencesDataStore @Inject constructor(
    private val dataStore: DataStore<Preferences>
) {
    private companion object {
        val DEFAULT_SNOOZE_MINUTES = intPreferencesKey("default_snooze_minutes")
        val NAG_INTERVAL_MINUTES = intPreferencesKey("nag_interval_minutes")
        val DEFAULT_ALERT_STYLE = stringPreferencesKey("default_alert_style")
    }

    val settings: Flow<AppSettings> = dataStore.data.map { prefs ->
        AppSettings(
            defaultSnoozeMinutes = prefs[DEFAULT_SNOOZE_MINUTES] ?: 10,
            nagIntervalMinutes = prefs[NAG_INTERVAL_MINUTES] ?: 5,
            defaultAlertStyle = prefs[DEFAULT_ALERT_STYLE] ?: "gentle"
        )
    }

    suspend fun updateDefaultSnoozeMinutes(minutes: Int) {
        dataStore.edit { prefs ->
            prefs[DEFAULT_SNOOZE_MINUTES] = minutes
        }
    }

    suspend fun updateNagIntervalMinutes(minutes: Int) {
        dataStore.edit { prefs ->
            prefs[NAG_INTERVAL_MINUTES] = minutes
        }
    }

    suspend fun updateDefaultAlertStyle(style: String) {
        dataStore.edit { prefs ->
            prefs[DEFAULT_ALERT_STYLE] = style
        }
    }
}
