# Android Port Plan 4: UI Layer (Jetpack Compose)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the entire UI layer — all four screens, ViewModels, theme, navigation, and shared utilities — using Jetpack Compose with Material 3. Dark theme only, monospace typography, matching the iOS app's design language.

**Architecture:** Feature modules (:feature:medlist, :feature:addedit, :feature:history, :feature:settings) each contain one screen composable and one ViewModel. The :app module owns Theme, Navigation, and MainActivity. The :core:common module provides shared formatting and color utilities.

**Tech Stack:** Jetpack Compose (BOM), Material 3, Navigation Compose, Hilt ViewModel injection, Kotlin coroutines + Flow, Lifecycle runtime compose.

**Important:** This is a first Compose app. Code should be straightforward and idiomatic, avoiding clever abstractions.

---

## File Map

### Module Registration (update)
- `android/settings.gradle.kts` — add feature modules

### Feature Module Build Files (new)
- `android/feature/medlist/build.gradle.kts`
- `android/feature/addedit/build.gradle.kts`
- `android/feature/history/build.gradle.kts`
- `android/feature/settings/build.gradle.kts`

### Core Common Utilities (new)
- `android/core/common/src/main/kotlin/com/nateb/mymedtimer/common/TimeFormatting.kt`
- `android/core/common/src/main/kotlin/com/nateb/mymedtimer/common/ColorUtils.kt`

### App Module — Theme + Navigation (new)
- `android/app/src/main/kotlin/com/nateb/mymedtimer/ui/theme/Theme.kt`
- `android/app/src/main/kotlin/com/nateb/mymedtimer/ui/navigation/Navigation.kt`
- `android/app/src/main/kotlin/com/nateb/mymedtimer/ui/navigation/Screen.kt`
- `android/app/src/main/kotlin/com/nateb/mymedtimer/MainActivity.kt`

### Feature: Med List (new)
- `android/feature/medlist/src/main/kotlin/com/nateb/mymedtimer/feature/medlist/MedListViewModel.kt`
- `android/feature/medlist/src/main/kotlin/com/nateb/mymedtimer/feature/medlist/MedListScreen.kt`
- `android/feature/medlist/src/main/kotlin/com/nateb/mymedtimer/feature/medlist/MedRowCard.kt`

### Feature: Add/Edit (new)
- `android/feature/addedit/src/main/kotlin/com/nateb/mymedtimer/feature/addedit/AddEditViewModel.kt`
- `android/feature/addedit/src/main/kotlin/com/nateb/mymedtimer/feature/addedit/AddEditScreen.kt`

### Feature: History (new)
- `android/feature/history/src/main/kotlin/com/nateb/mymedtimer/feature/history/HistoryViewModel.kt`
- `android/feature/history/src/main/kotlin/com/nateb/mymedtimer/feature/history/HistoryScreen.kt`
- `android/feature/history/src/main/kotlin/com/nateb/mymedtimer/feature/history/AdherenceHeatmap.kt`

### Feature: Settings (new)
- `android/feature/settings/src/main/kotlin/com/nateb/mymedtimer/feature/settings/SettingsViewModel.kt`
- `android/feature/settings/src/main/kotlin/com/nateb/mymedtimer/feature/settings/SettingsScreen.kt`

---

### Task 1: Feature Module Build Files + settings.gradle.kts Update

**Files:**
- Edit: `android/settings.gradle.kts`
- Create: `android/feature/medlist/build.gradle.kts`
- Create: `android/feature/addedit/build.gradle.kts`
- Create: `android/feature/history/build.gradle.kts`
- Create: `android/feature/settings/build.gradle.kts`

- [ ] **Step 1: Update settings.gradle.kts to include feature modules**

```kotlin
// android/settings.gradle.kts
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolution {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "MyMedTimer"

include(":app")
include(":math")
include(":core:domain")
include(":core:data")
include(":core:common")
include(":feature:medlist")
include(":feature:addedit")
include(":feature:history")
include(":feature:settings")
```

- [ ] **Step 2: Create feature/medlist build file**

```kotlin
// android/feature/medlist/build.gradle.kts
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
}

android {
    namespace = "com.nateb.mymedtimer.feature.medlist"
    compileSdk = libs.versions.compileSdk.get().toInt()

    defaultConfig {
        minSdk = libs.versions.minSdk.get().toInt()
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }
}

dependencies {
    implementation(project(":core:domain"))
    implementation(project(":core:common"))
    implementation(project(":math"))

    implementation(platform(libs.compose.bom))
    implementation(libs.compose.material3)
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)
    implementation(libs.lifecycle.runtime.compose)
    implementation(libs.lifecycle.viewmodel.compose)
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)
    implementation(libs.navigation.compose)
    implementation(libs.coroutines.android)
}
```

- [ ] **Step 3: Create feature/addedit build file**

```kotlin
// android/feature/addedit/build.gradle.kts
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
}

android {
    namespace = "com.nateb.mymedtimer.feature.addedit"
    compileSdk = libs.versions.compileSdk.get().toInt()

    defaultConfig {
        minSdk = libs.versions.minSdk.get().toInt()
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }
}

dependencies {
    implementation(project(":core:domain"))
    implementation(project(":core:common"))
    implementation(project(":math"))

    implementation(platform(libs.compose.bom))
    implementation(libs.compose.material3)
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)
    implementation(libs.lifecycle.runtime.compose)
    implementation(libs.lifecycle.viewmodel.compose)
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)
    implementation(libs.navigation.compose)
    implementation(libs.coroutines.android)
}
```

- [ ] **Step 4: Create feature/history build file**

```kotlin
// android/feature/history/build.gradle.kts
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
}

android {
    namespace = "com.nateb.mymedtimer.feature.history"
    compileSdk = libs.versions.compileSdk.get().toInt()

    defaultConfig {
        minSdk = libs.versions.minSdk.get().toInt()
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }
}

dependencies {
    implementation(project(":core:domain"))
    implementation(project(":core:common"))

    implementation(platform(libs.compose.bom))
    implementation(libs.compose.material3)
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)
    implementation(libs.lifecycle.runtime.compose)
    implementation(libs.lifecycle.viewmodel.compose)
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)
    implementation(libs.navigation.compose)
    implementation(libs.coroutines.android)
}
```

- [ ] **Step 5: Create feature/settings build file**

```kotlin
// android/feature/settings/build.gradle.kts
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
}

android {
    namespace = "com.nateb.mymedtimer.feature.settings"
    compileSdk = libs.versions.compileSdk.get().toInt()

    defaultConfig {
        minSdk = libs.versions.minSdk.get().toInt()
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }
}

dependencies {
    implementation(project(":core:domain"))
    implementation(project(":core:common"))

    implementation(platform(libs.compose.bom))
    implementation(libs.compose.material3)
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)
    implementation(libs.lifecycle.runtime.compose)
    implementation(libs.lifecycle.viewmodel.compose)
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)
    implementation(libs.navigation.compose)
    implementation(libs.coroutines.android)
}
```

- [ ] **Step 6: Update app/build.gradle.kts to depend on feature modules**

Add these to the dependencies block of `android/app/build.gradle.kts`:

```kotlin
    implementation(project(":feature:medlist"))
    implementation(project(":feature:addedit"))
    implementation(project(":feature:history"))
    implementation(project(":feature:settings"))
```

- [ ] **Step 7: Verify project syncs**

```bash
cd android && ./gradlew projects
```

Expected: lists all modules including `:feature:medlist`, `:feature:addedit`, `:feature:history`, `:feature:settings`

- [ ] **Step 8: Commit**

```bash
git add android/
git commit -m "feat(android): add feature module build files for UI layer"
```

---

### Task 2: Core Common Utilities (TimeFormatting, ColorUtils)

**Files:**
- Edit: `android/core/common/build.gradle.kts` — add compose-ui dependency for Color
- Create: `android/core/common/src/main/kotlin/com/nateb/mymedtimer/common/TimeFormatting.kt`
- Create: `android/core/common/src/main/kotlin/com/nateb/mymedtimer/common/ColorUtils.kt`

- [ ] **Step 1: Update core/common build file**

The core/common module needs Compose UI for `Color`. Change it from pure Kotlin to Android library:

```kotlin
// android/core/common/build.gradle.kts
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

android {
    namespace = "com.nateb.mymedtimer.core.common"
    compileSdk = libs.versions.compileSdk.get().toInt()

    defaultConfig {
        minSdk = libs.versions.minSdk.get().toInt()
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }
}

dependencies {
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
}
```

- [ ] **Step 2: Create TimeFormatting utility**

```kotlin
// android/core/common/src/main/kotlin/com/nateb/mymedtimer/common/TimeFormatting.kt
package com.nateb.mymedtimer.common

import java.time.Instant
import java.time.LocalTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.Duration

object TimeFormatting {

    /**
     * Format a countdown interval in seconds.
     * Negative = "overdue", 0 = "now", <60 = "<1m", else "Xh Ym" or "Ym".
     */
    fun countdown(intervalSeconds: Long): String {
        if (intervalSeconds < 0) return "overdue"
        if (intervalSeconds == 0L) return "now"
        if (intervalSeconds < 60) return "<1m"

        val totalMinutes = intervalSeconds / 60
        val hours = totalMinutes / 60
        val minutes = totalMinutes % 60

        return if (hours > 0) "${hours}h ${minutes}m" else "${minutes}m"
    }

    /**
     * Format a countdown from the difference between two instants.
     * Positive result = time remaining, negative = overdue.
     */
    fun countdown(from: Instant, to: Instant): String {
        val seconds = Duration.between(from, to).seconds
        return countdown(seconds)
    }

    /**
     * Format hour:minute as localized time string (e.g. "8:00 AM").
     */
    fun timeOfDay(hour: Int, minute: Int): String {
        val time = LocalTime.of(hour, minute)
        val formatter = DateTimeFormatter.ofPattern("h:mm a")
        return time.format(formatter)
    }

    /**
     * Format an Instant as a short time string (e.g. "2:30 PM").
     */
    fun shortTime(instant: Instant): String {
        val time = instant.atZone(ZoneId.systemDefault()).toLocalTime()
        val formatter = DateTimeFormatter.ofPattern("h:mm a")
        return time.format(formatter)
    }

    /**
     * Format an Instant as a medium date string (e.g. "Apr 15, 2026").
     */
    fun mediumDate(instant: Instant): String {
        val date = instant.atZone(ZoneId.systemDefault()).toLocalDate()
        val formatter = DateTimeFormatter.ofPattern("MMM d, yyyy")
        return date.format(formatter)
    }
}
```

- [ ] **Step 3: Create ColorUtils**

```kotlin
// android/core/common/src/main/kotlin/com/nateb/mymedtimer/common/ColorUtils.kt
package com.nateb.mymedtimer.common

import androidx.compose.ui.graphics.Color

/**
 * Parse a hex color string (with or without '#') to a Compose Color.
 */
fun String.toComposeColor(): Color {
    val hex = this.trimStart('#')
    if (hex.length != 6) return Color.Gray
    val colorInt = hex.toLongOrNull(16) ?: return Color.Gray
    return Color(
        red = ((colorInt shr 16) and 0xFF) / 255f,
        green = ((colorInt shr 8) and 0xFF) / 255f,
        blue = (colorInt and 0xFF) / 255f
    )
}
```

- [ ] **Step 4: Commit**

```bash
git add android/core/common/
git commit -m "feat(android): add TimeFormatting and ColorUtils to core/common"
```

---

### Task 3: Theme + Navigation in App Module

**Files:**
- Create: `android/app/src/main/kotlin/com/nateb/mymedtimer/ui/theme/Theme.kt`
- Create: `android/app/src/main/kotlin/com/nateb/mymedtimer/ui/navigation/Screen.kt`
- Create: `android/app/src/main/kotlin/com/nateb/mymedtimer/ui/navigation/Navigation.kt`
- Edit: `android/app/src/main/kotlin/com/nateb/mymedtimer/MainActivity.kt` (new file, replacing stub)
- Edit: `android/app/src/main/kotlin/com/nateb/mymedtimer/MyMedTimerApp.kt` — add @HiltAndroidApp

- [ ] **Step 1: Create Theme.kt**

Dark Material 3 theme with monospace typography. No light theme — force dark always.

```kotlin
// android/app/src/main/kotlin/com/nateb/mymedtimer/ui/theme/Theme.kt
package com.nateb.mymedtimer.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.Typography
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

private val DarkColors = darkColorScheme(
    primary = Color(0xFF90CAF9),
    onPrimary = Color(0xFF003258),
    primaryContainer = Color(0xFF00497D),
    onPrimaryContainer = Color(0xFFD1E4FF),
    secondary = Color(0xFFBBC7DB),
    onSecondary = Color(0xFF253140),
    secondaryContainer = Color(0xFF3B4858),
    onSecondaryContainer = Color(0xFFD7E3F8),
    tertiary = Color(0xFFD6BEE4),
    onTertiary = Color(0xFF3B2948),
    tertiaryContainer = Color(0xFF523F5F),
    onTertiaryContainer = Color(0xFFF2DAFF),
    error = Color(0xFFFFB4AB),
    onError = Color(0xFF690005),
    background = Color(0xFF0E0E0E),
    onBackground = Color(0xFFE2E2E5),
    surface = Color(0xFF0E0E0E),
    onSurface = Color(0xFFE2E2E5),
    surfaceVariant = Color(0xFF43474E),
    onSurfaceVariant = Color(0xFFC3C6CF),
    outline = Color(0xFF8D9199),
)

private val MonospaceTypography = Typography(
    displayLarge = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Normal, fontSize = 57.sp),
    displayMedium = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Normal, fontSize = 45.sp),
    displaySmall = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Normal, fontSize = 36.sp),
    headlineLarge = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Normal, fontSize = 32.sp),
    headlineMedium = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Normal, fontSize = 28.sp),
    headlineSmall = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Normal, fontSize = 24.sp),
    titleLarge = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Normal, fontSize = 22.sp),
    titleMedium = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Medium, fontSize = 16.sp),
    titleSmall = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Medium, fontSize = 14.sp),
    bodyLarge = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Normal, fontSize = 16.sp),
    bodyMedium = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Normal, fontSize = 14.sp),
    bodySmall = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Normal, fontSize = 12.sp),
    labelLarge = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Medium, fontSize = 14.sp),
    labelMedium = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Medium, fontSize = 12.sp),
    labelSmall = TextStyle(fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Medium, fontSize = 11.sp),
)

@Composable
fun MyMedTimerTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColors,
        typography = MonospaceTypography,
        content = content,
    )
}
```

- [ ] **Step 2: Create Screen.kt navigation routes**

```kotlin
// android/app/src/main/kotlin/com/nateb/mymedtimer/ui/navigation/Screen.kt
package com.nateb.mymedtimer.ui.navigation

sealed class Screen(val route: String) {
    data object MedList : Screen("med_list")
    data object History : Screen("history")
    data object Settings : Screen("settings")
    data object AddMed : Screen("add_med")
    data object EditMed : Screen("edit_med/{medId}") {
        fun createRoute(medId: String) = "edit_med/$medId"
    }
}
```

- [ ] **Step 3: Create Navigation.kt**

```kotlin
// android/app/src/main/kotlin/com/nateb/mymedtimer/ui/navigation/Navigation.kt
package com.nateb.mymedtimer.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.nateb.mymedtimer.feature.addedit.AddEditScreen
import com.nateb.mymedtimer.feature.history.HistoryScreen
import com.nateb.mymedtimer.feature.medlist.MedListScreen
import com.nateb.mymedtimer.feature.settings.SettingsScreen

private data class BottomNavItem(
    val label: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
    val route: String,
)

private val bottomNavItems = listOf(
    BottomNavItem("Meds", Icons.Default.Home, Screen.MedList.route),
    BottomNavItem("History", Icons.Default.DateRange, Screen.History.route),
    BottomNavItem("Settings", Icons.Default.Settings, Screen.Settings.route),
)

@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    val showBottomBar = currentDestination?.route in bottomNavItems.map { it.route }

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    bottomNavItems.forEach { item ->
                        NavigationBarItem(
                            icon = { Icon(item.icon, contentDescription = item.label) },
                            label = { Text(item.label) },
                            selected = currentDestination?.hierarchy?.any { it.route == item.route } == true,
                            onClick = {
                                navController.navigate(item.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                        )
                    }
                }
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.MedList.route,
            modifier = Modifier.padding(innerPadding),
        ) {
            composable(Screen.MedList.route) {
                MedListScreen(
                    onAddMed = { navController.navigate(Screen.AddMed.route) },
                    onEditMed = { medId -> navController.navigate(Screen.EditMed.createRoute(medId)) },
                )
            }
            composable(Screen.History.route) {
                HistoryScreen()
            }
            composable(Screen.Settings.route) {
                SettingsScreen()
            }
            composable(Screen.AddMed.route) {
                AddEditScreen(
                    onBack = { navController.popBackStack() },
                )
            }
            composable(
                route = Screen.EditMed.route,
                arguments = listOf(navArgument("medId") { type = NavType.StringType }),
            ) {
                AddEditScreen(
                    onBack = { navController.popBackStack() },
                )
            }
        }
    }
}
```

- [ ] **Step 4: Update MyMedTimerApp.kt with @HiltAndroidApp**

```kotlin
// android/app/src/main/kotlin/com/nateb/mymedtimer/MyMedTimerApp.kt
package com.nateb.mymedtimer

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class MyMedTimerApp : Application()
```

- [ ] **Step 5: Create MainActivity.kt**

```kotlin
// android/app/src/main/kotlin/com/nateb/mymedtimer/MainActivity.kt
package com.nateb.mymedtimer

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.nateb.mymedtimer.ui.navigation.AppNavigation
import com.nateb.mymedtimer.ui.theme.MyMedTimerTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MyMedTimerTheme {
                AppNavigation()
            }
        }
    }
}
```

- [ ] **Step 6: Commit**

```bash
git add android/app/
git commit -m "feat(android): add Material 3 dark theme, navigation, and MainActivity"
```

---

### Task 4: MedListScreen + MedListViewModel

This is the main screen. LazyColumn of medication cards with countdown timers, swipe actions, confirmation dialogs, and snackbar toasts.

**Files:**
- Create: `android/feature/medlist/src/main/kotlin/com/nateb/mymedtimer/feature/medlist/MedListViewModel.kt`
- Create: `android/feature/medlist/src/main/kotlin/com/nateb/mymedtimer/feature/medlist/MedListScreen.kt`
- Create: `android/feature/medlist/src/main/kotlin/com/nateb/mymedtimer/feature/medlist/MedRowCard.kt`

- [ ] **Step 1: Create MedListViewModel**

```kotlin
// android/feature/medlist/src/main/kotlin/com/nateb/mymedtimer/feature/medlist/MedListViewModel.kt
package com.nateb.mymedtimer.feature.medlist

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.nateb.mymedtimer.domain.model.DoseLog
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
import java.time.Instant
import java.time.LocalDate
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

    val uiState: StateFlow<MedListUiState> = combine(
        repository.getAllMedications(),
        _insights,
        _now,
        _toastMessage,
        _loggingMedication,
        _deletingMedication,
    ) { medications, insights, now, toast, logging, deleting ->
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
        // Tick every second
        viewModelScope.launch {
            while (isActive) {
                _now.value = Instant.now()
                delay(1000)
            }
        }
        // Refresh insights every 60 seconds
        viewModelScope.launch {
            repository.getAllMedications().collect { medications ->
                refreshInsights(medications)
            }
        }
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
        val results = AdherenceEngine.analyzeAll(medications, now)
        _insights.value = results.associateBy { it.medicationId }
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
            val elapsed = java.time.Duration.between(last, now).seconds
            return elapsed >= medication.minIntervalMinutes * 60L
        }

        fun minutesUntilCanTake(medication: Medication, now: Instant): Int {
            if (!medication.isPRN || medication.minIntervalMinutes <= 0) return 0
            val last = lastTakenTime(medication) ?: return 0
            val elapsed = java.time.Duration.between(last, now).seconds
            val remaining = medication.minIntervalMinutes * 60L - elapsed
            return if (remaining > 0) ((remaining + 59) / 60).toInt() else 0
        }

        fun sortedByNextDose(medications: List<Medication>, now: Instant): List<Medication> {
            return medications.sortedBy { nextDoseTime(it, now) ?: Instant.MAX }
        }
    }
}
```

- [ ] **Step 2: Create MedRowCard composable**

```kotlin
// android/feature/medlist/src/main/kotlin/com/nateb/mymedtimer/feature/medlist/MedRowCard.kt
package com.nateb.mymedtimer.feature.medlist

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
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
```

- [ ] **Step 3: Create MedListScreen**

```kotlin
// android/feature/medlist/src/main/kotlin/com/nateb/mymedtimer/feature/medlist/MedListScreen.kt
package com.nateb.mymedtimer.feature.medlist

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
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
```

- [ ] **Step 4: Commit**

```bash
git add android/feature/medlist/
git commit -m "feat(android): add MedListScreen with ViewModel, swipe actions, and dose logging"
```

---

### Task 5: AddEditScreen + AddEditViewModel

Full-screen form for creating/editing medications. Color picker, schedule times, PRN toggle, drift suggestion, consistency score.

**Files:**
- Create: `android/feature/addedit/src/main/kotlin/com/nateb/mymedtimer/feature/addedit/AddEditViewModel.kt`
- Create: `android/feature/addedit/src/main/kotlin/com/nateb/mymedtimer/feature/addedit/AddEditScreen.kt`

- [ ] **Step 1: Create AddEditViewModel**

```kotlin
// android/feature/addedit/src/main/kotlin/com/nateb/mymedtimer/feature/addedit/AddEditViewModel.kt
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
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
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
    val scheduleTimes: List<Pair<Int, Int>> = listOf(8 to 0),
    val isEditing: Boolean = false,
    val isSaveEnabled: Boolean = false,
    val insight: MedicationInsight? = null,
    val isLoaded: Boolean = false,
)

@HiltViewModel
class AddEditViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val repository: MedicationRepository,
) : ViewModel() {

    private val medId: String? = savedStateHandle["medId"]
    private var existingMed: Medication? = null

    private val _uiState = MutableStateFlow(AddEditUiState())
    val uiState: StateFlow<AddEditUiState> = _uiState.asStateFlow()

    init {
        if (medId != null) {
            viewModelScope.launch {
                val med = repository.getMedication(medId).first()
                if (med != null) {
                    existingMed = med
                    val times = med.scheduleTimes.map { it.hour to it.minute }
                    val insight = AdherenceEngine.analyze(med, recentEscalationCount = 0, Instant.now())
                    _uiState.value = AddEditUiState(
                        name = med.name,
                        dosage = med.dosage,
                        colorHex = med.colorHex,
                        alertStyle = med.alertStyle,
                        isPRN = med.isPRN,
                        minIntervalMinutes = med.minIntervalMinutes,
                        scheduleTimes = times.ifEmpty { listOf(8 to 0) },
                        isEditing = true,
                        isSaveEnabled = med.name.isNotBlank(),
                        insight = insight,
                        isLoaded = true,
                    )
                }
            }
        } else {
            _uiState.value = _uiState.value.copy(isLoaded = true)
        }
    }

    fun updateName(name: String) {
        _uiState.value = _uiState.value.copy(
            name = name,
            isSaveEnabled = name.isNotBlank(),
        )
    }

    fun updateDosage(dosage: String) {
        _uiState.value = _uiState.value.copy(dosage = dosage)
    }

    fun updateColor(hex: String) {
        _uiState.value = _uiState.value.copy(colorHex = hex)
    }

    fun updateAlertStyle(style: String) {
        _uiState.value = _uiState.value.copy(alertStyle = style)
    }

    fun updateIsPRN(isPRN: Boolean) {
        _uiState.value = _uiState.value.copy(isPRN = isPRN)
    }

    fun updateMinInterval(minutes: Int) {
        _uiState.value = _uiState.value.copy(minIntervalMinutes = minutes)
    }

    fun updateScheduleTime(index: Int, hour: Int, minute: Int) {
        val times = _uiState.value.scheduleTimes.toMutableList()
        if (index in times.indices) {
            times[index] = hour to minute
            _uiState.value = _uiState.value.copy(scheduleTimes = times)
        }
    }

    fun addScheduleTime() {
        val times = _uiState.value.scheduleTimes + (12 to 0)
        _uiState.value = _uiState.value.copy(scheduleTimes = times)
    }

    fun removeScheduleTime(index: Int) {
        val times = _uiState.value.scheduleTimes.toMutableList()
        if (times.size > 1 && index in times.indices) {
            times.removeAt(index)
            _uiState.value = _uiState.value.copy(scheduleTimes = times)
        }
    }

    fun applySuggestedTime(hour: Int, minute: Int) {
        _uiState.value = _uiState.value.copy(scheduleTimes = listOf(hour to minute))
    }

    fun save(onComplete: () -> Unit) {
        val state = _uiState.value
        val trimmedName = state.name.trim()
        if (trimmedName.isEmpty()) return

        viewModelScope.launch {
            val schedules = if (state.isPRN) {
                emptyList()
            } else {
                state.scheduleTimes.map { (h, m) -> ScheduleTime(h, m) }
            }

            val med = Medication(
                id = existingMed?.id ?: UUID.randomUUID().toString(),
                name = trimmedName,
                dosage = state.dosage.trim(),
                colorHex = state.colorHex,
                alertStyle = state.alertStyle,
                isPRN = state.isPRN,
                minIntervalMinutes = state.minIntervalMinutes,
                isActive = true,
                createdAt = existingMed?.createdAt ?: Instant.now(),
                scheduleTimes = schedules,
                doseLogs = existingMed?.doseLogs ?: emptyList(),
            )

            repository.saveMedication(med)
            onComplete()
        }
    }
}
```

- [ ] **Step 2: Create AddEditScreen**

```kotlin
// android/feature/addedit/src/main/kotlin/com/nateb/mymedtimer/feature/addedit/AddEditScreen.kt
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
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nateb.mymedtimer.common.TimeFormatting
import com.nateb.mymedtimer.common.toComposeColor
import kotlin.math.abs

private val colorOptions = listOf(
    "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
    "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F",
)

private val intervalOptions = listOf(0, 30, 60, 120, 180, 240, 360, 480)

private val alertStyles = listOf("gentle", "urgent", "escalating")

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun AddEditScreen(
    onBack: () -> Unit,
    viewModel: AddEditViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    var showTimePickerFor by remember { mutableStateOf<Int?>(null) }

    if (!state.isLoaded) return

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (state.isEditing) "edit med" else "add med") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Cancel")
                    }
                },
                actions = {
                    TextButton(
                        onClick = { viewModel.save(onComplete = onBack) },
                        enabled = state.isSaveEnabled,
                    ) {
                        Text("Save")
                    }
                },
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp),
        ) {
            // --- Medication section ---
            SectionLabel("medication")
            OutlinedTextField(
                value = state.name,
                onValueChange = { viewModel.updateName(it) },
                label = { Text("Name") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            OutlinedTextField(
                value = state.dosage,
                onValueChange = { viewModel.updateDosage(it) },
                label = { Text("Dosage (e.g. 500mg)") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )

            HorizontalDivider()

            // --- Type section ---
            SectionLabel("type")
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("As needed (PRN)", style = MaterialTheme.typography.bodyLarge)
                Switch(
                    checked = state.isPRN,
                    onCheckedChange = { viewModel.updateIsPRN(it) },
                )
            }

            if (state.isPRN) {
                Text("Min interval", style = MaterialTheme.typography.bodyMedium)
                SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                    val options = listOf(0 to "none", 30 to "30m", 60 to "1h", 120 to "2h", 240 to "4h", 480 to "8h")
                    options.forEachIndexed { index, (mins, label) ->
                        SegmentedButton(
                            selected = state.minIntervalMinutes == mins,
                            onClick = { viewModel.updateMinInterval(mins) },
                            shape = SegmentedButtonDefaults.itemShape(index, options.size),
                        ) {
                            Text(label, style = MaterialTheme.typography.labelSmall)
                        }
                    }
                }
            }

            HorizontalDivider()

            // --- Color section ---
            SectionLabel("color")
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                colorOptions.forEach { hex ->
                    val isSelected = state.colorHex == hex
                    Box(
                        modifier = Modifier
                            .size(44.dp)
                            .clip(CircleShape)
                            .background(hex.toComposeColor())
                            .then(
                                if (isSelected) {
                                    Modifier.border(3.dp, Color.White, CircleShape)
                                } else {
                                    Modifier
                                }
                            )
                            .clickable { viewModel.updateColor(hex) },
                    )
                }
            }

            HorizontalDivider()

            // --- Alert style section ---
            SectionLabel("alert style")
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                alertStyles.forEachIndexed { index, style ->
                    SegmentedButton(
                        selected = state.alertStyle == style,
                        onClick = { viewModel.updateAlertStyle(style) },
                        shape = SegmentedButtonDefaults.itemShape(index, alertStyles.size),
                    ) {
                        Text(style)
                    }
                }
            }

            // --- Schedule section (hidden when PRN) ---
            if (!state.isPRN) {
                HorizontalDivider()
                SectionLabel("schedule")

                state.scheduleTimes.forEachIndexed { index, (hour, minute) ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        TextButton(onClick = { showTimePickerFor = index }) {
                            Text(
                                TimeFormatting.timeOfDay(hour, minute),
                                style = MaterialTheme.typography.bodyLarge,
                            )
                        }

                        if (state.scheduleTimes.size > 1) {
                            IconButton(onClick = { viewModel.removeScheduleTime(index) }) {
                                Icon(
                                    Icons.Default.Close,
                                    contentDescription = "Remove time",
                                    tint = MaterialTheme.colorScheme.error,
                                )
                            }
                        }
                    }
                }

                // Schedule suggestion
                val insight = state.insight
                if (state.isEditing && insight != null && insight.suggestedTime != null) {
                    val drift = insight.timeDriftMinutes
                    if (drift != null && abs(drift) > 15) {
                        val (sugH, sugM) = insight.suggestedTime!!
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(
                                "you usually take this at ${String.format("%d:%02d", sugH, sugM)}",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                            TextButton(onClick = { viewModel.applySuggestedTime(sugH, sugM) }) {
                                Text("adjust", style = MaterialTheme.typography.labelSmall)
                            }
                        }
                    }
                    Text(
                        "consistency: ${insight.consistencyScore}%",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }

                TextButton(onClick = { viewModel.addScheduleTime() }) {
                    Text("+ add time")
                }
            }
        }
    }

    // Time picker dialog
    showTimePickerFor?.let { index ->
        val (currentHour, currentMinute) = state.scheduleTimes[index]
        val timePickerState = rememberTimePickerState(
            initialHour = currentHour,
            initialMinute = currentMinute,
        )
        Dialog(onDismissRequest = { showTimePickerFor = null }) {
            Column(
                modifier = Modifier
                    .background(
                        MaterialTheme.colorScheme.surface,
                        MaterialTheme.shapes.extraLarge,
                    )
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                TimePicker(state = timePickerState)
                Spacer(modifier = Modifier.height(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End,
                ) {
                    TextButton(onClick = { showTimePickerFor = null }) {
                        Text("Cancel")
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    TextButton(onClick = {
                        viewModel.updateScheduleTime(index, timePickerState.hour, timePickerState.minute)
                        showTimePickerFor = null
                    }) {
                        Text("OK")
                    }
                }
            }
        }
    }
}

@Composable
private fun SectionLabel(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.labelMedium,
        color = MaterialTheme.colorScheme.primary,
    )
}
```

- [ ] **Step 3: Commit**

```bash
git add android/feature/addedit/
git commit -m "feat(android): add AddEditScreen with color picker, schedules, and drift suggestion"
```

---

### Task 6: HistoryScreen + HistoryViewModel (with Heatmap)

Dose history grouped by day, with an 8-week adherence heatmap at the top using staggered fade-in animation.

**Files:**
- Create: `android/feature/history/src/main/kotlin/com/nateb/mymedtimer/feature/history/HistoryViewModel.kt`
- Create: `android/feature/history/src/main/kotlin/com/nateb/mymedtimer/feature/history/HistoryScreen.kt`
- Create: `android/feature/history/src/main/kotlin/com/nateb/mymedtimer/feature/history/AdherenceHeatmap.kt`

- [ ] **Step 1: Create HistoryViewModel**

```kotlin
// android/feature/history/src/main/kotlin/com/nateb/mymedtimer/feature/history/HistoryViewModel.kt
package com.nateb.mymedtimer.feature.history

import androidx.lifecycle.ViewModel
import com.nateb.mymedtimer.domain.model.DoseLog
import com.nateb.mymedtimer.domain.model.Medication
import com.nateb.mymedtimer.domain.repository.MedicationRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import javax.inject.Inject

data class DoseLogDisplay(
    val id: String,
    val medName: String,
    val medDosage: String,
    val scheduledTime: Instant,
    val actualTime: Instant?,
    val status: String,
)

data class HistoryUiState(
    val allLogs: List<DoseLogDisplay> = emptyList(),
    val groupedByDay: List<Pair<String, List<DoseLogDisplay>>> = emptyList(),
)

@HiltViewModel
class HistoryViewModel @Inject constructor(
    repository: MedicationRepository,
) : ViewModel() {

    private val dateFormatter = DateTimeFormatter.ofPattern("MMM d, yyyy")

    val uiState: Flow<HistoryUiState> = repository.getAllMedications().map { medications ->
        val allLogs = medications.flatMap { med ->
            med.doseLogs.map { log ->
                DoseLogDisplay(
                    id = log.id,
                    medName = med.name,
                    medDosage = med.dosage,
                    scheduledTime = log.scheduledTime,
                    actualTime = log.actualTime,
                    status = log.status,
                )
            }
        }.sortedByDescending { it.scheduledTime }

        val zone = ZoneId.systemDefault()
        val grouped = allLogs.groupBy { log ->
            log.scheduledTime.atZone(zone).toLocalDate().format(dateFormatter)
        }.toList().sortedByDescending { (_, logs) ->
            logs.first().scheduledTime
        }

        HistoryUiState(allLogs = allLogs, groupedByDay = grouped)
    }
}
```

- [ ] **Step 2: Create AdherenceHeatmap composable**

```kotlin
// android/feature/history/src/main/kotlin/com/nateb/mymedtimer/feature/history/AdherenceHeatmap.kt
package com.nateb.mymedtimer.feature.history

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

private enum class DayStatus(val color: Color) {
    NONE(Color.White.copy(alpha = 0.15f)),
    TAKEN(Color(0xCC4CAF50)),
    MISSED(Color(0xB3F44336)),
    SNOOZED(Color(0x99FFEB3B)),
    MIXED(Color(0xB3FF9800)),
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun AdherenceHeatmap(
    logs: List<DoseLogDisplay>,
    modifier: Modifier = Modifier,
) {
    val columns = 7
    val weeks = 8
    val totalDays = weeks * columns

    val zone = ZoneId.systemDefault()
    val today = LocalDate.now()
    val days = (0 until totalDays).map { offset ->
        today.minusDays((totalDays - 1 - offset).toLong())
    }

    val dayData = remember(logs) {
        val result = mutableMapOf<LocalDate, DayStatus>()
        for (log in logs) {
            val day = log.scheduledTime.atZone(zone).toLocalDate()
            val existing = result[day] ?: DayStatus.NONE
            val newStatus = when (log.status) {
                "taken" -> when (existing) {
                    DayStatus.MISSED -> DayStatus.MIXED
                    DayStatus.MIXED -> DayStatus.MIXED
                    else -> DayStatus.TAKEN
                }
                "skipped" -> when (existing) {
                    DayStatus.TAKEN -> DayStatus.MIXED
                    else -> DayStatus.MISSED
                }
                "snoozed" -> when (existing) {
                    DayStatus.NONE -> DayStatus.SNOOZED
                    else -> existing
                }
                else -> existing
            }
            result[day] = newStatus
        }
        result
    }

    var appeared by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { appeared = true }

    val dateFormatter = DateTimeFormatter.ofPattern("MMM d, yyyy")

    Column(modifier = modifier.padding(vertical = 4.dp)) {
        Text(
            text = "last $weeks weeks",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )

        // Grid of heatmap cells
        // Using a simple Column + Row approach for the fixed 7-column grid
        Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
            for (week in 0 until weeks) {
                Row(horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                    for (dayOfWeek in 0 until columns) {
                        val index = week * columns + dayOfWeek
                        val day = days[index]
                        val status = dayData[day] ?: DayStatus.NONE

                        // Staggered fade-in
                        val targetAlpha = if (appeared) 1f else 0f
                        val alpha by animateFloatAsState(
                            targetValue = targetAlpha,
                            animationSpec = tween(
                                durationMillis = 300,
                                delayMillis = index * 8,
                            ),
                            label = "heatmap_cell_$index",
                        )

                        val cellLabel = "${day.format(dateFormatter)}, ${
                            when (status) {
                                DayStatus.NONE -> "no data"
                                DayStatus.TAKEN -> "taken"
                                DayStatus.MISSED -> "missed"
                                DayStatus.SNOOZED -> "snoozed"
                                DayStatus.MIXED -> "mixed"
                            }
                        }"

                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(14.dp)
                                .clip(RoundedCornerShape(2.dp))
                                .alpha(alpha)
                                .background(status.color)
                                .semantics { contentDescription = cellLabel },
                        )
                    }
                }
            }
        }

        // Legend
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.padding(top = 4.dp),
        ) {
            LegendDot(color = DayStatus.TAKEN.color, label = "taken")
            LegendDot(color = DayStatus.MISSED.color, label = "missed")
            LegendDot(color = DayStatus.SNOOZED.color, label = "snoozed")
            LegendDot(color = DayStatus.MIXED.color, label = "mixed")
            LegendDot(color = DayStatus.NONE.color, label = "none")
        }
    }
}

@Composable
private fun LegendDot(color: Color, label: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(3.dp),
    ) {
        Box(
            modifier = Modifier
                .width(10.dp)
                .height(10.dp)
                .clip(RoundedCornerShape(2.dp))
                .background(color),
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}
```

- [ ] **Step 3: Create HistoryScreen**

```kotlin
// android/feature/history/src/main/kotlin/com/nateb/mymedtimer/feature/history/HistoryScreen.kt
package com.nateb.mymedtimer.feature.history

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nateb.mymedtimer.common.TimeFormatting

@Composable
fun HistoryScreen(
    viewModel: HistoryViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle(initialValue = HistoryUiState())

    if (state.allLogs.isEmpty()) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text(
                text = "no dose history yet",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        return
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
    ) {
        // Heatmap section
        item {
            AdherenceHeatmap(
                logs = state.allLogs,
                modifier = Modifier.padding(16.dp),
            )
        }

        // Day groups
        state.groupedByDay.forEach { (day, logs) ->
            item {
                Text(
                    text = day,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                )
            }

            items(items = logs, key = { it.id }) { log ->
                DoseLogRow(log)
            }
        }
    }
}

@Composable
private fun DoseLogRow(log: DoseLogDisplay) {
    val (iconTint, statusLabel) = when (log.status) {
        "taken" -> Color(0xFF4CAF50) to "taken"
        "skipped" -> Color(0xFFF44336) to "skipped"
        "snoozed" -> Color(0xFFFFEB3B) to "snoozed"
        else -> Color.Gray to log.status
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // Status icon
        StatusDot(color = iconTint)

        Spacer(modifier = Modifier.width(12.dp))

        // Med name + dosage
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = log.medName,
                style = MaterialTheme.typography.bodyMedium,
            )
            if (log.medDosage.isNotEmpty()) {
                Text(
                    text = log.medDosage,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }

        // Time + status
        Column(horizontalAlignment = Alignment.End) {
            Text(
                text = TimeFormatting.shortTime(log.actualTime ?: log.scheduledTime),
                style = MaterialTheme.typography.bodySmall,
            )
            Text(
                text = statusLabel,
                style = MaterialTheme.typography.labelSmall,
                color = iconTint,
            )
        }
    }
}

@Composable
private fun StatusDot(color: Color) {
    androidx.compose.foundation.Canvas(modifier = Modifier.size(12.dp)) {
        drawCircle(color = color)
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add android/feature/history/
git commit -m "feat(android): add HistoryScreen with adherence heatmap and dose log list"
```

---

### Task 7: SettingsScreen + SettingsViewModel

Settings for snooze duration, nag interval, default alert style, notification permission status, and app version.

**Files:**
- Create: `android/feature/settings/src/main/kotlin/com/nateb/mymedtimer/feature/settings/SettingsViewModel.kt`
- Create: `android/feature/settings/src/main/kotlin/com/nateb/mymedtimer/feature/settings/SettingsScreen.kt`

- [ ] **Step 1: Create SettingsViewModel**

The SettingsViewModel needs access to DataStore preferences. For now, we define a simple preferences interface that will be wired in the data layer plan.

```kotlin
// android/feature/settings/src/main/kotlin/com/nateb/mymedtimer/feature/settings/SettingsViewModel.kt
package com.nateb.mymedtimer.feature.settings

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SettingsUiState(
    val defaultSnoozeMinutes: Int = 10,
    val nagIntervalMinutes: Int = 5,
    val defaultAlertStyle: String = "gentle",
    val notificationStatus: NotificationStatus = NotificationStatus.CHECKING,
    val appVersion: String = "",
)

enum class NotificationStatus {
    CHECKING, GRANTED, DENIED, NOT_DETERMINED
}

@HiltViewModel
class SettingsViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    init {
        loadSettings()
        checkNotificationStatus()
    }

    private fun loadSettings() {
        // Load version from BuildConfig
        val packageInfo = try {
            context.packageManager.getPackageInfo(context.packageName, 0)
        } catch (e: Exception) {
            null
        }
        val versionName = packageInfo?.versionName ?: "?"
        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo?.longVersionCode?.toString() ?: "?"
        } else {
            @Suppress("DEPRECATION")
            packageInfo?.versionCode?.toString() ?: "?"
        }
        _uiState.value = _uiState.value.copy(appVersion = "$versionName ($versionCode)")

        // TODO: Load saved preferences from DataStore (Plan 3 - core:data)
        // For now, defaults are used
    }

    fun updateSnoozeMinutes(minutes: Int) {
        _uiState.value = _uiState.value.copy(defaultSnoozeMinutes = minutes)
        // TODO: Persist to DataStore
    }

    fun updateNagInterval(minutes: Int) {
        _uiState.value = _uiState.value.copy(nagIntervalMinutes = minutes)
        // TODO: Persist to DataStore
    }

    fun updateAlertStyle(style: String) {
        _uiState.value = _uiState.value.copy(defaultAlertStyle = style)
        // TODO: Persist to DataStore
    }

    fun checkNotificationStatus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val granted = ContextCompat.checkSelfPermission(
                context, Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
            _uiState.value = _uiState.value.copy(
                notificationStatus = if (granted) NotificationStatus.GRANTED else NotificationStatus.NOT_DETERMINED
            )
        } else {
            // Pre-13, notifications are enabled by default
            _uiState.value = _uiState.value.copy(notificationStatus = NotificationStatus.GRANTED)
        }
    }

    fun onNotificationPermissionResult(granted: Boolean) {
        _uiState.value = _uiState.value.copy(
            notificationStatus = if (granted) NotificationStatus.GRANTED else NotificationStatus.DENIED
        )
    }
}
```

- [ ] **Step 2: Create SettingsScreen**

```kotlin
// android/feature/settings/src/main/kotlin/com/nateb/mymedtimer/feature/settings/SettingsScreen.kt
package com.nateb.mymedtimer.feature.settings

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle

private val snoozeOptions = listOf(5, 10, 15, 30)
private val nagOptions = listOf(3, 5, 10, 15)
private val alertStyles = listOf("gentle", "urgent", "escalating")

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: SettingsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current

    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        viewModel.onNotificationPermissionResult(granted)
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp),
    ) {
        // --- Defaults section ---
        SectionLabel("defaults")

        // Snooze duration
        Text("Snooze Duration", style = MaterialTheme.typography.bodyLarge)
        SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
            snoozeOptions.forEachIndexed { index, mins ->
                SegmentedButton(
                    selected = state.defaultSnoozeMinutes == mins,
                    onClick = { viewModel.updateSnoozeMinutes(mins) },
                    shape = SegmentedButtonDefaults.itemShape(index, snoozeOptions.size),
                ) {
                    Text("${mins}m")
                }
            }
        }

        // Nag interval
        Text("Nag Interval", style = MaterialTheme.typography.bodyLarge)
        SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
            nagOptions.forEachIndexed { index, mins ->
                SegmentedButton(
                    selected = state.nagIntervalMinutes == mins,
                    onClick = { viewModel.updateNagInterval(mins) },
                    shape = SegmentedButtonDefaults.itemShape(index, nagOptions.size),
                ) {
                    Text("${mins}m")
                }
            }
        }

        // Default alert style
        Text("Alert Style", style = MaterialTheme.typography.bodyLarge)
        SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
            alertStyles.forEachIndexed { index, style ->
                SegmentedButton(
                    selected = state.defaultAlertStyle == style,
                    onClick = { viewModel.updateAlertStyle(style) },
                    shape = SegmentedButtonDefaults.itemShape(index, alertStyles.size),
                ) {
                    Text(style)
                }
            }
        }

        HorizontalDivider()

        // --- Notifications section ---
        SectionLabel("notifications")

        when (state.notificationStatus) {
            NotificationStatus.GRANTED -> {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        "Notifications enabled",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Icon(
                        Icons.Default.CheckCircle,
                        contentDescription = "enabled",
                        tint = Color(0xFF4CAF50),
                        modifier = Modifier.size(20.dp),
                    )
                }
            }
            NotificationStatus.DENIED -> {
                TextButton(onClick = {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", context.packageName, null)
                    }
                    context.startActivity(intent)
                }) {
                    Text("Denied \u2014 open Settings")
                }
            }
            NotificationStatus.NOT_DETERMINED -> {
                TextButton(onClick = {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                    }
                }) {
                    Text("Request Notification Permission")
                }
            }
            NotificationStatus.CHECKING -> {
                Text(
                    "checking...",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }

        HorizontalDivider()

        // --- Version ---
        Text(
            text = "MyMedTimer v${state.appVersion}",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun SectionLabel(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.labelMedium,
        color = MaterialTheme.colorScheme.primary,
    )
}
```

- [ ] **Step 3: Commit**

```bash
git add android/feature/settings/
git commit -m "feat(android): add SettingsScreen with snooze, nag, alert, and notification settings"
```

---

## Self-Review Checklist

- [ ] All 4 feature modules registered in `settings.gradle.kts`
- [ ] Each feature module build file includes compose, hilt, lifecycle, navigation deps
- [ ] Each feature module depends on `:core:domain`, `:core:common` (and `:math` where needed)
- [ ] App module depends on all 4 feature modules
- [ ] `core/common` provides `TimeFormatting` and `toComposeColor()` extension
- [ ] Theme forces dark color scheme with monospace typography across all text styles
- [ ] Navigation uses `NavHost` with bottom bar for Meds/History/Settings, full-screen for Add/Edit
- [ ] `MedListScreen`: LazyColumn, SwipeToDismiss (trailing=delete, leading=edit), tap=log dialog, FAB=add, snackbar toast
- [ ] `MedListViewModel`: 1-second timer tick, 60-second insight refresh, sorted by next dose
- [ ] `MedRowCard`: color bar, name, dosage, countdown (red when <5min), PRN status, risk dot
- [ ] `AddEditScreen`: name/dosage fields, PRN toggle+interval, color picker with white ring, alert segmented, schedule times with TimePicker dialog, drift suggestion, consistency score
- [ ] `HistoryScreen`: 8-week heatmap with staggered fade-in, legend, dose logs grouped by day
- [ ] `SettingsScreen`: snooze/nag/alert pickers, notification permission handling, app version
- [ ] No iOS-specific APIs (UIApplication, UNUserNotificationCenter, etc.)
- [ ] All packages match convention: `com.nateb.mymedtimer.feature.<name>`, `com.nateb.mymedtimer.common`, `com.nateb.mymedtimer.ui`
- [ ] `@HiltViewModel` on all ViewModels, `@AndroidEntryPoint` on MainActivity, `@HiltAndroidApp` on Application
- [ ] Verify with `cd android && ./gradlew projects` then `./gradlew assembleDebug`
