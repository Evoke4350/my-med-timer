# Android Port Plan 1: Project Scaffold + Math Module + Core Domain

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the Android project structure, port all math services (Hawkes, circular stats, adherence engine) as pure Kotlin, and define domain models and repository interface.

**Architecture:** Multi-module clean architecture. Math module is pure Kotlin with zero Android dependencies. Core/domain defines models and interfaces. Core/data, feature modules, and app module come in later plans.

**Tech Stack:** Kotlin 2.0, Gradle with Kotlin DSL, version catalog (libs.versions.toml), JUnit 5 for math tests.

---

## File Map

### Project Scaffold
- `android/build.gradle.kts` — root build file
- `android/settings.gradle.kts` — module registration
- `android/gradle.properties` — Gradle/Kotlin config
- `android/gradle/libs.versions.toml` — dependency versions
- `android/app/build.gradle.kts` — app module (stub for now)
- `android/app/src/main/AndroidManifest.xml` — app manifest stub
- `android/app/src/main/kotlin/com/nateb/mymedtimer/MyMedTimerApp.kt` — Application class stub
- `android/math/build.gradle.kts` — pure Kotlin module
- `android/core/domain/build.gradle.kts` — pure Kotlin module
- `android/core/data/build.gradle.kts` — Android library (stub)
- `android/core/common/build.gradle.kts` — pure Kotlin module (stub)

### Math Module
- `android/math/src/main/kotlin/com/nateb/mymedtimer/math/RiskLevel.kt`
- `android/math/src/main/kotlin/com/nateb/mymedtimer/math/HawkesParameters.kt`
- `android/math/src/main/kotlin/com/nateb/mymedtimer/math/HawkesProcess.kt`
- `android/math/src/main/kotlin/com/nateb/mymedtimer/math/CircularStatistics.kt`
- `android/math/src/main/kotlin/com/nateb/mymedtimer/math/MedicationInsight.kt`
- `android/math/src/main/kotlin/com/nateb/mymedtimer/math/AdherenceEngine.kt`
- `android/math/src/test/kotlin/com/nateb/mymedtimer/math/HawkesProcessTest.kt`
- `android/math/src/test/kotlin/com/nateb/mymedtimer/math/CircularStatisticsTest.kt`
- `android/math/src/test/kotlin/com/nateb/mymedtimer/math/AdherenceEngineTest.kt`

### Core Domain
- `android/core/domain/src/main/kotlin/com/nateb/mymedtimer/domain/model/Medication.kt`
- `android/core/domain/src/main/kotlin/com/nateb/mymedtimer/domain/model/ScheduleTime.kt`
- `android/core/domain/src/main/kotlin/com/nateb/mymedtimer/domain/model/DoseLog.kt`
- `android/core/domain/src/main/kotlin/com/nateb/mymedtimer/domain/repository/MedicationRepository.kt`

---

### Task 1: Project Scaffold

**Files:**
- Create: `android/build.gradle.kts`
- Create: `android/settings.gradle.kts`
- Create: `android/gradle.properties`
- Create: `android/gradle/libs.versions.toml`
- Create: `android/app/build.gradle.kts`
- Create: `android/app/src/main/AndroidManifest.xml`
- Create: `android/app/src/main/kotlin/com/nateb/mymedtimer/MyMedTimerApp.kt`
- Create: `android/math/build.gradle.kts`
- Create: `android/core/domain/build.gradle.kts`
- Create: `android/core/data/build.gradle.kts`
- Create: `android/core/common/build.gradle.kts`

- [ ] **Step 1: Create version catalog**

```toml
# android/gradle/libs.versions.toml
[versions]
kotlin = "2.0.21"
agp = "8.7.3"
compose-bom = "2024.12.01"
compose-compiler = "1.5.15"
room = "2.6.1"
hilt = "2.53.1"
hilt-navigation-compose = "1.2.0"
lifecycle = "2.8.7"
navigation = "2.8.5"
datastore = "1.1.1"
coroutines = "1.9.0"
junit5 = "5.11.4"
turbine = "1.2.0"
compileSdk = "35"
minSdk = "33"
targetSdk = "35"

[libraries]
compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "compose-bom" }
compose-material3 = { group = "androidx.compose.material3", name = "material3" }
compose-ui = { group = "androidx.compose.ui", name = "ui" }
compose-ui-tooling = { group = "androidx.compose.ui", name = "ui-tooling" }
compose-ui-tooling-preview = { group = "androidx.compose.ui", name = "ui-tooling-preview" }
compose-ui-test = { group = "androidx.compose.ui", name = "ui-test-junit4" }
compose-ui-test-manifest = { group = "androidx.compose.ui", name = "ui-test-manifest" }
activity-compose = { group = "androidx.activity", name = "activity-compose", version = "1.9.3" }
navigation-compose = { group = "androidx.navigation", name = "navigation-compose", version.ref = "navigation" }
lifecycle-runtime-compose = { group = "androidx.lifecycle", name = "lifecycle-runtime-compose", version.ref = "lifecycle" }
lifecycle-viewmodel-compose = { group = "androidx.lifecycle", name = "lifecycle-viewmodel-compose", version.ref = "lifecycle" }
room-runtime = { group = "androidx.room", name = "room-runtime", version.ref = "room" }
room-compiler = { group = "androidx.room", name = "room-compiler", version.ref = "room" }
room-ktx = { group = "androidx.room", name = "room-ktx", version.ref = "room" }
room-testing = { group = "androidx.room", name = "room-testing", version.ref = "room" }
hilt-android = { group = "com.google.dagger", name = "hilt-android", version.ref = "hilt" }
hilt-compiler = { group = "com.google.dagger", name = "hilt-android-compiler", version.ref = "hilt" }
hilt-navigation-compose = { group = "androidx.hilt", name = "hilt-navigation-compose", version.ref = "hilt-navigation-compose" }
datastore-preferences = { group = "androidx.datastore", name = "datastore-preferences", version.ref = "datastore" }
coroutines-core = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-core", version.ref = "coroutines" }
coroutines-android = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-android", version.ref = "coroutines" }
coroutines-test = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-test", version.ref = "coroutines" }
junit5-api = { group = "org.junit.jupiter", name = "junit-jupiter-api", version.ref = "junit5" }
junit5-engine = { group = "org.junit.jupiter", name = "junit-jupiter-engine", version.ref = "junit5" }
turbine = { group = "app.cash.turbine", name = "turbine", version.ref = "turbine" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
android-library = { id = "com.android.library", version.ref = "agp" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
kotlin-jvm = { id = "org.jetbrains.kotlin.jvm", version.ref = "kotlin" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
ksp = { id = "com.google.devtools.ksp", version = "2.0.21-1.0.28" }
```

- [ ] **Step 2: Create gradle.properties**

```properties
# android/gradle.properties
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
android.nonTransitiveRClass=true
```

- [ ] **Step 3: Create root build.gradle.kts**

```kotlin
// android/build.gradle.kts
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.jvm) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.hilt) apply false
    alias(libs.plugins.ksp) apply false
}
```

- [ ] **Step 4: Create settings.gradle.kts**

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
```

- [ ] **Step 5: Create math module build file**

```kotlin
// android/math/build.gradle.kts
plugins {
    alias(libs.plugins.kotlin.jvm)
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

tasks.withType<Test> {
    useJUnitPlatform()
}

dependencies {
    testImplementation(libs.junit5.api)
    testRuntimeOnly(libs.junit5.engine)
}
```

- [ ] **Step 6: Create core/domain build file**

```kotlin
// android/core/domain/build.gradle.kts
plugins {
    alias(libs.plugins.kotlin.jvm)
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    api(project(":math"))
    implementation(libs.coroutines.core)
}
```

- [ ] **Step 7: Create core/data build file (stub)**

```kotlin
// android/core/data/build.gradle.kts
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
}

android {
    namespace = "com.nateb.mymedtimer.core.data"
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
}

dependencies {
    implementation(project(":core:domain"))
    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)
    implementation(libs.datastore.preferences)
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.coroutines.android)
    testImplementation(libs.junit5.api)
    testRuntimeOnly(libs.junit5.engine)
    androidTestImplementation(libs.room.testing)
}
```

- [ ] **Step 8: Create core/common build file (stub)**

```kotlin
// android/core/common/build.gradle.kts
plugins {
    alias(libs.plugins.kotlin.jvm)
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}
```

- [ ] **Step 9: Create app module build file**

```kotlin
// android/app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
}

android {
    namespace = "com.nateb.mymedtimer"
    compileSdk = libs.versions.compileSdk.get().toInt()

    defaultConfig {
        applicationId = "com.nateb.mymedtimer"
        minSdk = libs.versions.minSdk.get().toInt()
        targetSdk = libs.versions.targetSdk.get().toInt()
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
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
        buildConfig = true
    }
}

dependencies {
    implementation(project(":core:domain"))
    implementation(project(":core:data"))
    implementation(project(":core:common"))
    implementation(project(":math"))

    implementation(platform(libs.compose.bom))
    implementation(libs.compose.material3)
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)
    implementation(libs.activity.compose)
    implementation(libs.navigation.compose)
    implementation(libs.lifecycle.runtime.compose)
    implementation(libs.lifecycle.viewmodel.compose)
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)
    implementation(libs.coroutines.android)
}
```

- [ ] **Step 10: Create app manifest and Application class stub**

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <application
        android:name=".MyMedTimerApp"
        android:allowBackup="true"
        android:label="MyMedTimer"
        android:supportsRtl="true"
        android:theme="@style/Theme.Material3.DynamicColors.DayNight">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.Material3.DynamicColors.DayNight">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

```kotlin
// android/app/src/main/kotlin/com/nateb/mymedtimer/MyMedTimerApp.kt
package com.nateb.mymedtimer

import android.app.Application

class MyMedTimerApp : Application()
```

- [ ] **Step 11: Create Gradle wrapper**

Run from the `android/` directory:

```bash
cd android && gradle wrapper --gradle-version 8.11.1
```

- [ ] **Step 12: Verify project syncs**

```bash
cd android && ./gradlew projects
```

Expected: lists all modules (`:app`, `:math`, `:core:domain`, `:core:data`, `:core:common`)

- [ ] **Step 13: Commit**

```bash
git add android/
git commit -m "feat(android): scaffold multi-module project structure"
```

---

### Task 2: HawkesProcess + RiskLevel

**Files:**
- Create: `android/math/src/main/kotlin/com/nateb/mymedtimer/math/RiskLevel.kt`
- Create: `android/math/src/main/kotlin/com/nateb/mymedtimer/math/HawkesParameters.kt`
- Create: `android/math/src/main/kotlin/com/nateb/mymedtimer/math/HawkesProcess.kt`
- Test: `android/math/src/test/kotlin/com/nateb/mymedtimer/math/HawkesProcessTest.kt`

- [ ] **Step 1: Write HawkesProcess tests**

```kotlin
// android/math/src/test/kotlin/com/nateb/mymedtimer/math/HawkesProcessTest.kt
package com.nateb.mymedtimer.math

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import java.time.Instant
import java.time.Duration

class HawkesProcessTest {

    private val defaultParams = HawkesParameters(mu = 0.1, alpha = 0.3, beta = 1.0)

    @Test
    fun `intensity with no misses equals baseline mu`() {
        val now = Instant.now()
        val lambda = HawkesProcess.intensity(now, defaultParams, emptyList())
        assertEquals(defaultParams.mu, lambda, 0.001)
    }

    @Test
    fun `intensity increases after miss`() {
        val now = Instant.now()
        val justMissed = now.minus(Duration.ofHours(1))
        val lambda = HawkesProcess.intensity(now, defaultParams, listOf(justMissed))
        assertTrue(lambda > defaultParams.mu, "Intensity should increase after a recent miss")
    }

    @Test
    fun `intensity decays over time`() {
        val now = Instant.now()
        val recentMiss = now.minus(Duration.ofHours(1))
        val olderMiss = now.minus(Duration.ofDays(7))

        val lambdaRecent = HawkesProcess.intensity(now, defaultParams, listOf(recentMiss))
        val lambdaOlder = HawkesProcess.intensity(now, defaultParams, listOf(olderMiss))

        assertTrue(lambdaRecent > lambdaOlder, "Recent miss intensity should exceed older miss")
    }

    @Test
    fun `multiple misses stack intensity`() {
        val now = Instant.now()
        val miss1 = now.minus(Duration.ofHours(1))
        val miss2 = now.minus(Duration.ofHours(2))

        val lambdaSingle = HawkesProcess.intensity(now, defaultParams, listOf(miss1))
        val lambdaDouble = HawkesProcess.intensity(now, defaultParams, listOf(miss1, miss2))

        assertTrue(lambdaDouble > lambdaSingle, "Multiple misses should stack")
    }

    @Test
    fun `miss probability in valid range`() {
        val now = Instant.now()
        val prob = HawkesProcess.missProbability(now, defaultParams, emptyList())
        assertTrue(prob in 0.0..1.0)
    }

    @Test
    fun `miss probability higher after miss`() {
        val now = Instant.now()
        val recentMiss = now.minus(Duration.ofHours(1))
        val probNoMiss = HawkesProcess.missProbability(now, defaultParams, emptyList())
        val probAfterMiss = HawkesProcess.missProbability(now, defaultParams, listOf(recentMiss))
        assertTrue(probAfterMiss > probNoMiss)
    }

    @Test
    fun `risk level low`() {
        assertEquals(RiskLevel.LOW, HawkesProcess.riskLevel(0.1))
    }

    @Test
    fun `risk level medium`() {
        assertEquals(RiskLevel.MEDIUM, HawkesProcess.riskLevel(0.3))
    }

    @Test
    fun `risk level high`() {
        assertEquals(RiskLevel.HIGH, HawkesProcess.riskLevel(0.7))
    }

    @Test
    fun `risk level boundaries`() {
        assertEquals(RiskLevel.LOW, HawkesProcess.riskLevel(0.19))
        assertEquals(RiskLevel.MEDIUM, HawkesProcess.riskLevel(0.2))
        assertEquals(RiskLevel.MEDIUM, HawkesProcess.riskLevel(0.5))
        assertEquals(RiskLevel.HIGH, HawkesProcess.riskLevel(0.51))
    }

    @Test
    fun `fit with too few events returns defaults`() {
        val now = Instant.now()
        val timestamps = listOf(now, now.minus(Duration.ofDays(1)))
        val params = HawkesProcess.fit(
            timestamps,
            windowStart = now.minus(Duration.ofDays(30)),
            windowEnd = now
        )
        assertEquals(0.1, params.mu, 0.001)
        assertEquals(0.3, params.alpha, 0.001)
        assertEquals(1.0, params.beta, 0.001)
    }

    @Test
    fun `fit enforces stationarity constraint`() {
        val now = Instant.now()
        val timestamps = (0 until 20).map { i ->
            now.minus(Duration.ofHours(i.toLong()))
        }
        val params = HawkesProcess.fit(
            timestamps,
            windowStart = now.minus(Duration.ofDays(30)),
            windowEnd = now
        )
        assertTrue(params.alpha < params.beta, "Stationarity: alpha must be < beta")
    }

    @Test
    fun `fit returns positive parameters`() {
        val now = Instant.now()
        val timestamps = (0 until 10).map { i ->
            now.minus(Duration.ofDays(i.toLong() * 2))
        }
        val params = HawkesProcess.fit(
            timestamps,
            windowStart = now.minus(Duration.ofDays(30)),
            windowEnd = now
        )
        assertTrue(params.mu > 0)
        assertTrue(params.alpha > 0)
        assertTrue(params.beta > 0)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd android && ./gradlew :math:test
```

Expected: compilation failure, `HawkesProcess` and `RiskLevel` not found.

- [ ] **Step 3: Implement RiskLevel**

```kotlin
// android/math/src/main/kotlin/com/nateb/mymedtimer/math/RiskLevel.kt
package com.nateb.mymedtimer.math

enum class RiskLevel {
    LOW, MEDIUM, HIGH
}
```

- [ ] **Step 4: Implement HawkesParameters**

```kotlin
// android/math/src/main/kotlin/com/nateb/mymedtimer/math/HawkesParameters.kt
package com.nateb.mymedtimer.math

data class HawkesParameters(
    val mu: Double,     // baseline intensity (misses per day)
    val alpha: Double,  // excitation magnitude
    val beta: Double    // decay rate
)
```

- [ ] **Step 5: Implement HawkesProcess**

```kotlin
// android/math/src/main/kotlin/com/nateb/mymedtimer/math/HawkesProcess.kt
package com.nateb.mymedtimer.math

import java.time.Instant
import kotlin.math.exp
import kotlin.math.max
import kotlin.math.min

object HawkesProcess {

    private const val SECONDS_PER_DAY = 86400.0

    /**
     * Fit Hawkes parameters from miss timestamps using maximum likelihood estimation.
     * Gradient ascent on the log-likelihood for exponential kernel (Ozaki, 1979).
     */
    fun fit(
        missTimestamps: List<Instant>,
        windowStart: Instant,
        windowEnd: Instant
    ): HawkesParameters {
        val windowDuration = (windowEnd.epochSecond - windowStart.epochSecond) / SECONDS_PER_DAY
        if (windowDuration <= 0) {
            return HawkesParameters(mu = 0.1, alpha = 0.3, beta = 1.0)
        }

        val times = missTimestamps
            .map { (it.epochSecond - windowStart.epochSecond) / SECONDS_PER_DAY }
            .filter { it in 0.0..windowDuration }
            .sorted()

        val n = times.size
        val T = windowDuration

        if (n < 5) {
            return HawkesParameters(mu = 0.1, alpha = 0.3, beta = 1.0)
        }

        var mu = n.toDouble() / T
        var alpha = 0.5
        var beta = 1.0

        val learningRate = 0.01
        val iterations = 30

        repeat(iterations) {
            val R = DoubleArray(n)
            val D = DoubleArray(n)
            val lambdas = DoubleArray(n)

            for (i in 0 until n) {
                var ri = 0.0
                var di = 0.0
                for (j in 0 until i) {
                    val dt = times[i] - times[j]
                    val expVal = exp(-beta * dt)
                    ri += expVal
                    di -= dt * expVal
                }
                R[i] = ri
                D[i] = di
                lambdas[i] = mu + alpha * ri
            }

            var dMu = -T
            var dAlpha = 0.0
            var dBeta = 0.0
            var sumCompensator = 0.0
            var sumCompensatorDt = 0.0

            for (i in 0 until n) {
                val lam = max(lambdas[i], 1e-10)
                val invLam = 1.0 / lam

                dMu += invLam
                dAlpha += R[i] * invLam
                dBeta += alpha * D[i] * invLam

                val remaining = T - times[i]
                val expRemaining = exp(-beta * remaining)
                sumCompensator += (1.0 - expRemaining)
                sumCompensatorDt += remaining * expRemaining
            }

            dAlpha -= sumCompensator / beta
            dBeta -= (alpha / (beta * beta)) * sumCompensator
            dBeta += (alpha / beta) * sumCompensatorDt

            mu += learningRate * dMu
            alpha += learningRate * dAlpha
            beta += learningRate * dBeta

            mu = max(mu, 0.001)
            alpha = max(alpha, 0.001)
            beta = max(beta, 0.01)

            if (alpha >= 0.95 * beta) {
                alpha = 0.95 * beta
            }
        }

        return HawkesParameters(mu = mu, alpha = alpha, beta = beta)
    }

    /**
     * Compute current intensity lambda(t) given parameters and recent miss history.
     */
    fun intensity(
        at: Instant,
        parameters: HawkesParameters,
        recentMisses: List<Instant>
    ): Double {
        var lambda = parameters.mu

        for (missTime in recentMisses) {
            val dt = (at.epochSecond - missTime.epochSecond) / SECONDS_PER_DAY
            if (dt > 0) {
                lambda += parameters.alpha * exp(-parameters.beta * dt)
            }
        }

        return lambda
    }

    /**
     * Miss probability at a scheduled time, mapped via sigmoid.
     * P = 1 / (1 + exp(-k(lambda - lambda0))) where k=5.0, lambda0=mu.
     */
    fun missProbability(
        at: Instant,
        parameters: HawkesParameters,
        recentMisses: List<Instant>
    ): Double {
        val lambda = intensity(at, parameters, recentMisses)

        val k = 5.0
        val lambda0 = parameters.mu
        val exponent = -k * (lambda - lambda0)
        val probability = 1.0 / (1.0 + exp(exponent))

        return min(max(probability, 0.01), 0.99)
    }

    /**
     * Risk level: low (<0.2), medium (0.2-0.5), high (>0.5).
     */
    fun riskLevel(missProbability: Double): RiskLevel {
        return when {
            missProbability < 0.2 -> RiskLevel.LOW
            missProbability <= 0.5 -> RiskLevel.MEDIUM
            else -> RiskLevel.HIGH
        }
    }
}
```

- [ ] **Step 6: Run tests**

```bash
cd android && ./gradlew :math:test
```

Expected: all 13 HawkesProcess tests pass.

- [ ] **Step 7: Commit**

```bash
git add android/math/
git commit -m "feat(android): add HawkesProcess with MLE fitting and risk assessment"
```

---

### Task 3: CircularStatistics

**Files:**
- Create: `android/math/src/main/kotlin/com/nateb/mymedtimer/math/CircularStatistics.kt`
- Test: `android/math/src/test/kotlin/com/nateb/mymedtimer/math/CircularStatisticsTest.kt`

- [ ] **Step 1: Write CircularStatistics tests**

```kotlin
// android/math/src/test/kotlin/com/nateb/mymedtimer/math/CircularStatisticsTest.kt
package com.nateb.mymedtimer.math

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import kotlin.math.PI
import kotlin.math.abs

class CircularStatisticsTest {

    private val accuracy = 0.01

    @Test
    fun `timeToAngle midnight is zero`() {
        assertEquals(0.0, CircularStatistics.timeToAngle(0, 0), accuracy)
    }

    @Test
    fun `timeToAngle 6AM is pi over 2`() {
        assertEquals(PI / 2, CircularStatistics.timeToAngle(6, 0), accuracy)
    }

    @Test
    fun `timeToAngle noon is pi`() {
        assertEquals(PI, CircularStatistics.timeToAngle(12, 0), accuracy)
    }

    @Test
    fun `timeToAngle 6PM is 3pi over 2`() {
        assertEquals(3 * PI / 2, CircularStatistics.timeToAngle(18, 0), accuracy)
    }

    @Test
    fun `angleToTime round trip`() {
        val testCases = listOf(
            0 to 0, 6 to 0, 12 to 0, 18 to 0,
            8 to 30, 23 to 45, 14 to 15
        )
        for ((h, m) in testCases) {
            val angle = CircularStatistics.timeToAngle(h, m)
            val (rh, rm) = CircularStatistics.angleToTime(angle)
            assertEquals(h, rh, "Hour mismatch for $h:$m")
            assertEquals(m, rm, "Minute mismatch for $h:$m")
        }
    }

    @Test
    fun `angleToTime negative angle normalizes`() {
        val (h, m) = CircularStatistics.angleToTime(-PI / 2)
        assertEquals(18, h)
        assertEquals(0, m)
    }

    @Test
    fun `circular mean midnight wrap`() {
        val angle11pm = CircularStatistics.timeToAngle(23, 0)
        val angle1am = CircularStatistics.timeToAngle(1, 0)
        val mean = CircularStatistics.circularMean(listOf(angle11pm, angle1am))
        val (h, m) = CircularStatistics.angleToTime(mean)
        assertEquals(0, h, "Circular mean of 11pm and 1am should be midnight")
        assertTrue(abs(m) <= 1)
    }

    @Test
    fun `circular mean same angles`() {
        val angle = CircularStatistics.timeToAngle(8, 0)
        val mean = CircularStatistics.circularMean(listOf(angle, angle, angle))
        assertEquals(angle, mean, accuracy)
    }

    @Test
    fun `circular mean empty returns zero`() {
        assertEquals(0.0, CircularStatistics.circularMean(emptyList()))
    }

    @Test
    fun `mean resultant length identical angles is 1`() {
        val angle = CircularStatistics.timeToAngle(9, 0)
        val rBar = CircularStatistics.meanResultantLength(listOf(angle, angle, angle))
        assertEquals(1.0, rBar, accuracy)
    }

    @Test
    fun `mean resultant length opposite angles is 0`() {
        val rBar = CircularStatistics.meanResultantLength(listOf(0.0, PI))
        assertEquals(0.0, rBar, accuracy)
    }

    @Test
    fun `mean resultant length empty is 0`() {
        assertEquals(0.0, CircularStatistics.meanResultantLength(emptyList()))
    }

    @Test
    fun `circular variance same angles is 0`() {
        val angle = CircularStatistics.timeToAngle(10, 0)
        val variance = CircularStatistics.circularVariance(listOf(angle, angle, angle))
        assertEquals(0.0, variance, accuracy)
    }

    @Test
    fun `circular variance uniform spread is 1`() {
        val angles = listOf(0.0, PI / 2, PI, 3 * PI / 2)
        val variance = CircularStatistics.circularVariance(angles)
        assertEquals(1.0, variance, accuracy)
    }

    @Test
    fun `vonMises kappa high concentration`() {
        val angle = CircularStatistics.timeToAngle(8, 0)
        val angles = List(5) { angle }
        val kappa = CircularStatistics.vonMisesKappa(angles)
        assertTrue(kappa > 10.0, "Identical angles should produce high kappa")
    }

    @Test
    fun `vonMises kappa low concentration`() {
        val angles = listOf(0.0, PI / 2, PI, 3 * PI / 2)
        val kappa = CircularStatistics.vonMisesKappa(angles)
        assertEquals(0.0, kappa, 0.1)
    }

    @Test
    fun `vonMises kappa empty is 0`() {
        assertEquals(0.0, CircularStatistics.vonMisesKappa(emptyList()))
    }

    @Test
    fun `suggested time around 8am`() {
        val zone = ZoneId.systemDefault()
        val today = LocalDate.now()
        val dates = listOf(
            LocalTime.of(7, 50), LocalTime.of(8, 10),
            LocalTime.of(7, 55), LocalTime.of(8, 5)
        ).map { time ->
            today.atTime(time).atZone(zone).toInstant()
        }
        val result = CircularStatistics.suggestedTime(dates)
        assertNotNull(result)
        assertEquals(8, result!!.first)
        assertTrue(abs(result.second) <= 2)
    }

    @Test
    fun `suggested time empty returns null`() {
        assertNull(CircularStatistics.suggestedTime(emptyList()))
    }

    @Test
    fun `suggested time single date`() {
        val zone = ZoneId.systemDefault()
        val date = LocalDate.now().atTime(14, 30).atZone(zone).toInstant()
        val result = CircularStatistics.suggestedTime(listOf(date))
        assertNotNull(result)
        assertEquals(14, result!!.first)
        assertEquals(30, result.second)
    }

    @Test
    fun `consistency score tight cluster is high`() {
        val zone = ZoneId.systemDefault()
        val today = LocalDate.now()
        val dates = (0 until 10).map { i ->
            today.minusDays(i.toLong())
                .atTime(9, i % 3)
                .atZone(zone)
                .toInstant()
        }
        val score = CircularStatistics.consistencyScore(dates)
        assertTrue(score > 90, "Tight cluster should have high consistency, got $score")
    }

    @Test
    fun `consistency score scattered is low`() {
        val zone = ZoneId.systemDefault()
        val today = LocalDate.now()
        val dates = listOf(0, 6, 12, 18).map { hour ->
            today.atTime(hour, 0).atZone(zone).toInstant()
        }
        val score = CircularStatistics.consistencyScore(dates)
        assertTrue(score < 10, "Scattered times should have low consistency, got $score")
    }

    @Test
    fun `consistency score empty is 0`() {
        assertEquals(0, CircularStatistics.consistencyScore(emptyList()))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd android && ./gradlew :math:test
```

Expected: compilation failure, `CircularStatistics` not found.

- [ ] **Step 3: Implement CircularStatistics**

```kotlin
// android/math/src/main/kotlin/com/nateb/mymedtimer/math/CircularStatistics.kt
package com.nateb.mymedtimer.math

import java.time.Instant
import java.time.ZoneId
import kotlin.math.*

object CircularStatistics {

    /**
     * Convert hour:minute to angle in radians [0, 2*PI).
     */
    fun timeToAngle(hour: Int, minute: Int): Double {
        val totalMinutes = (hour * 60 + minute).toDouble()
        return (totalMinutes / 1440.0) * 2.0 * PI
    }

    /**
     * Convert angle back to (hour, minute).
     */
    fun angleToTime(angle: Double): Pair<Int, Int> {
        var normalized = angle % (2.0 * PI)
        if (normalized < 0) normalized += 2.0 * PI
        val totalMinutes = (normalized / (2.0 * PI)) * 1440.0
        val rounded = totalMinutes.roundToInt() % 1440
        return Pair(rounded / 60, rounded % 60)
    }

    /**
     * Circular mean of angles (mean direction).
     * Uses atan2(mean_sin, mean_cos), normalized to [0, 2*PI).
     */
    fun circularMean(angles: List<Double>): Double {
        if (angles.isEmpty()) return 0.0
        val sumSin = angles.sumOf { sin(it) }
        val sumCos = angles.sumOf { cos(it) }
        var mean = atan2(sumSin, sumCos)
        if (mean < 0) mean += 2.0 * PI
        return mean
    }

    /**
     * Mean resultant length R-bar = sqrt(C^2 + S^2) / n.
     */
    fun meanResultantLength(angles: List<Double>): Double {
        if (angles.isEmpty()) return 0.0
        val n = angles.size.toDouble()
        val sumCos = angles.sumOf { cos(it) }
        val sumSin = angles.sumOf { sin(it) }
        return sqrt(sumCos * sumCos + sumSin * sumSin) / n
    }

    /**
     * Circular variance = 1 - R-bar (range [0,1], 0 = perfectly consistent).
     */
    fun circularVariance(angles: List<Double>): Double {
        return 1.0 - meanResultantLength(angles)
    }

    /**
     * Von Mises concentration parameter kappa (MLE approximation, Mardia & Jupp).
     */
    fun vonMisesKappa(angles: List<Double>): Double {
        val rBar = meanResultantLength(angles)
        if (rBar <= 0) return 0.0

        return when {
            rBar < 0.53 -> 2.0 * rBar + rBar.pow(3) + (5.0 * rBar.pow(5)) / 6.0
            rBar < 0.85 -> -0.4 + 1.39 * rBar + 0.43 / (1.0 - rBar)
            else -> 1.0 / (rBar.pow(3) - 4.0 * rBar.pow(2) + 3.0 * rBar)
        }
    }

    /**
     * Suggest optimal schedule time from actual taken times.
     * Returns circular mean as (hour, minute), or null if empty.
     */
    fun suggestedTime(takenInstants: List<Instant>): Pair<Int, Int>? {
        if (takenInstants.isEmpty()) return null
        val zone = ZoneId.systemDefault()
        if (takenInstants.size == 1) {
            val lt = takenInstants[0].atZone(zone).toLocalTime()
            return Pair(lt.hour, lt.minute)
        }
        val angles = takenInstants.map { instant ->
            val lt = instant.atZone(zone).toLocalTime()
            timeToAngle(lt.hour, lt.minute)
        }
        val mean = circularMean(angles)
        return angleToTime(mean)
    }

    /**
     * Consistency score 0-100 (100 = perfectly consistent timing).
     */
    fun consistencyScore(takenInstants: List<Instant>): Int {
        if (takenInstants.isEmpty()) return 0
        val zone = ZoneId.systemDefault()
        val angles = takenInstants.map { instant ->
            val lt = instant.atZone(zone).toLocalTime()
            timeToAngle(lt.hour, lt.minute)
        }
        val score = (1.0 - circularVariance(angles)) * 100.0
        return min(100.0, max(0.0, score)).roundToInt()
    }
}
```

- [ ] **Step 4: Run tests**

```bash
cd android && ./gradlew :math:test
```

Expected: all CircularStatistics tests pass. All HawkesProcess tests still pass.

- [ ] **Step 5: Commit**

```bash
git add android/math/
git commit -m "feat(android): add CircularStatistics with Von Mises distribution"
```

---

### Task 4: AdherenceEngine + MedicationInsight

**Files:**
- Create: `android/math/src/main/kotlin/com/nateb/mymedtimer/math/MedicationInsight.kt`
- Create: `android/math/src/main/kotlin/com/nateb/mymedtimer/math/AdherenceEngine.kt`
- Test: `android/math/src/test/kotlin/com/nateb/mymedtimer/math/AdherenceEngineTest.kt`

- [ ] **Step 1: Write AdherenceEngine tests**

Note: AdherenceEngine in the math module operates on simple data (lists of Instants, ints). The full `analyze(medication)` method that reads from domain models lives in core/domain as a use case. Here we test the pure math: Whittle index and alert style mapping.

```kotlin
// android/math/src/test/kotlin/com/nateb/mymedtimer/math/AdherenceEngineTest.kt
package com.nateb.mymedtimer.math

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import java.time.Duration
import java.time.Instant

class AdherenceEngineTest {

    @Test
    fun `whittle index increases with miss probability`() {
        val low = AdherenceEngine.whittleIndex(missProbability = 0.1, importance = 1.0, recentEscalationCount = 0)
        val high = AdherenceEngine.whittleIndex(missProbability = 0.8, importance = 1.0, recentEscalationCount = 0)
        assertTrue(high > low)
    }

    @Test
    fun `whittle index decreases with escalations`() {
        val noFatigue = AdherenceEngine.whittleIndex(missProbability = 0.5, importance = 1.0, recentEscalationCount = 0)
        val withFatigue = AdherenceEngine.whittleIndex(missProbability = 0.5, importance = 1.0, recentEscalationCount = 5)
        assertTrue(noFatigue > withFatigue, "More escalations should reduce Whittle index")
    }

    @Test
    fun `whittle index scales with importance`() {
        val low = AdherenceEngine.whittleIndex(missProbability = 0.5, importance = 0.5, recentEscalationCount = 0)
        val high = AdherenceEngine.whittleIndex(missProbability = 0.5, importance = 2.0, recentEscalationCount = 0)
        assertTrue(high > low)
    }

    @Test
    fun `recommended alert style gentle`() {
        assertEquals("gentle", AdherenceEngine.recommendedAlertStyle(whittleIndex = 0.1))
        assertEquals("gentle", AdherenceEngine.recommendedAlertStyle(whittleIndex = 0.29))
    }

    @Test
    fun `recommended alert style urgent`() {
        assertEquals("urgent", AdherenceEngine.recommendedAlertStyle(whittleIndex = 0.3))
        assertEquals("urgent", AdherenceEngine.recommendedAlertStyle(whittleIndex = 0.5))
    }

    @Test
    fun `recommended alert style escalating`() {
        assertEquals("escalating", AdherenceEngine.recommendedAlertStyle(whittleIndex = 0.61))
        assertEquals("escalating", AdherenceEngine.recommendedAlertStyle(whittleIndex = 0.9))
    }

    @Test
    fun `analyze with zero misses returns low risk`() {
        val now = Instant.now()
        val insight = AdherenceEngine.analyze(
            missTimestamps = emptyList(),
            takenTimestamps = (0 until 30).map { i ->
                now.minus(Duration.ofDays(i.toLong()))
            },
            scheduledHour = 8,
            scheduledMinute = 0,
            recentEscalationCount = 0,
            now = now
        )
        assertEquals(RiskLevel.LOW, insight.riskLevel)
        assertEquals("gentle", insight.recommendedAlertStyle)
        assertTrue(insight.missProbability < 0.1)
    }

    @Test
    fun `analyze with recent skips elevates risk`() {
        val now = Instant.now()
        val missTimestamps = (0 until 5).map { i ->
            now.minus(Duration.ofDays(i.toLong()))
        }
        val takenTimestamps = (5 until 30).map { i ->
            now.minus(Duration.ofDays(i.toLong()))
        }
        val insight = AdherenceEngine.analyze(
            missTimestamps = missTimestamps,
            takenTimestamps = takenTimestamps,
            scheduledHour = 8,
            scheduledMinute = 0,
            recentEscalationCount = 0,
            now = now
        )
        assertTrue(insight.missProbability > 0.3, "Recent skips should elevate miss probability")
    }

    @Test
    fun `analyze with empty logs`() {
        val now = Instant.now()
        val insight = AdherenceEngine.analyze(
            missTimestamps = emptyList(),
            takenTimestamps = emptyList(),
            scheduledHour = 8,
            scheduledMinute = 0,
            recentEscalationCount = 0,
            now = now
        )
        assertEquals(0, insight.consistencyScore)
        assertNull(insight.suggestedTime)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd android && ./gradlew :math:test
```

Expected: compilation failure, `AdherenceEngine` and `MedicationInsight` not found.

- [ ] **Step 3: Implement MedicationInsight**

```kotlin
// android/math/src/main/kotlin/com/nateb/mymedtimer/math/MedicationInsight.kt
package com.nateb.mymedtimer.math

data class MedicationInsight(
    val riskLevel: RiskLevel,
    val missProbability: Double,
    val consistencyScore: Int,
    val suggestedTime: Pair<Int, Int>?,        // (hour, minute)
    val currentScheduledTime: Pair<Int, Int>?,  // (hour, minute)
    val timeDriftMinutes: Int?,
    val recommendedAlertStyle: String
)
```

- [ ] **Step 4: Implement AdherenceEngine**

```kotlin
// android/math/src/main/kotlin/com/nateb/mymedtimer/math/AdherenceEngine.kt
package com.nateb.mymedtimer.math

import java.time.Duration
import java.time.Instant

object AdherenceEngine {

    /**
     * Whittle index: W = (importance * missProbability) / fatigueCost
     * where fatigueCost = 1 + 0.3 * recentEscalationCount
     */
    fun whittleIndex(
        missProbability: Double,
        importance: Double,
        recentEscalationCount: Int
    ): Double {
        val fatigueCost = 1.0 + 0.3 * recentEscalationCount
        return (importance * missProbability) / fatigueCost
    }

    /**
     * Map Whittle index to alert style.
     * W < 0.3 -> "gentle", 0.3-0.6 -> "urgent", > 0.6 -> "escalating"
     */
    fun recommendedAlertStyle(whittleIndex: Double): String {
        return when {
            whittleIndex < 0.3 -> "gentle"
            whittleIndex <= 0.6 -> "urgent"
            else -> "escalating"
        }
    }

    /**
     * Generate insights from raw timestamp data.
     * This operates on primitive data so the math module stays free of Android/domain dependencies.
     */
    fun analyze(
        missTimestamps: List<Instant>,
        takenTimestamps: List<Instant>,
        scheduledHour: Int?,
        scheduledMinute: Int?,
        recentEscalationCount: Int = 0,
        now: Instant = Instant.now()
    ): MedicationInsight {
        val windowStart = now.minus(Duration.ofDays(90))

        val params = HawkesProcess.fit(
            missTimestamps = missTimestamps,
            windowStart = windowStart,
            windowEnd = now
        )

        val recentMisses = missTimestamps.filter { !it.isBefore(windowStart) }

        val missProb: Double
        val risk: RiskLevel
        if (recentMisses.isEmpty()) {
            missProb = 0.05
            risk = RiskLevel.LOW
        } else {
            missProb = HawkesProcess.missProbability(now, params, recentMisses)
            risk = HawkesProcess.riskLevel(missProb)
        }

        val consistency = CircularStatistics.consistencyScore(takenTimestamps)
        val suggested = CircularStatistics.suggestedTime(takenTimestamps)

        val currentScheduled = if (scheduledHour != null && scheduledMinute != null) {
            Pair(scheduledHour, scheduledMinute)
        } else {
            null
        }

        val drift: Int? = if (suggested != null && currentScheduled != null) {
            val suggestedMinutes = suggested.first * 60 + suggested.second
            val scheduledMinutes = currentScheduled.first * 60 + currentScheduled.second
            var diff = suggestedMinutes - scheduledMinutes
            if (diff > 720) diff -= 1440
            if (diff < -720) diff += 1440
            diff
        } else {
            null
        }

        val whittle = whittleIndex(
            missProbability = missProb,
            importance = 1.0,
            recentEscalationCount = recentEscalationCount
        )
        val alertStyle = recommendedAlertStyle(whittle)

        return MedicationInsight(
            riskLevel = risk,
            missProbability = missProb,
            consistencyScore = consistency,
            suggestedTime = suggested,
            currentScheduledTime = currentScheduled,
            timeDriftMinutes = drift,
            recommendedAlertStyle = alertStyle
        )
    }
}
```

- [ ] **Step 5: Run tests**

```bash
cd android && ./gradlew :math:test
```

Expected: all tests pass (HawkesProcess + CircularStatistics + AdherenceEngine).

- [ ] **Step 6: Commit**

```bash
git add android/math/
git commit -m "feat(android): add AdherenceEngine with Whittle index and analysis"
```

---

### Task 5: Core Domain Models and Repository Interface

**Files:**
- Create: `android/core/domain/src/main/kotlin/com/nateb/mymedtimer/domain/model/Medication.kt`
- Create: `android/core/domain/src/main/kotlin/com/nateb/mymedtimer/domain/model/ScheduleTime.kt`
- Create: `android/core/domain/src/main/kotlin/com/nateb/mymedtimer/domain/model/DoseLog.kt`
- Create: `android/core/domain/src/main/kotlin/com/nateb/mymedtimer/domain/repository/MedicationRepository.kt`

- [ ] **Step 1: Create domain models**

```kotlin
// android/core/domain/src/main/kotlin/com/nateb/mymedtimer/domain/model/ScheduleTime.kt
package com.nateb.mymedtimer.domain.model

data class ScheduleTime(
    val hour: Int,
    val minute: Int
)
```

```kotlin
// android/core/domain/src/main/kotlin/com/nateb/mymedtimer/domain/model/DoseLog.kt
package com.nateb.mymedtimer.domain.model

import java.time.Instant

data class DoseLog(
    val id: String,
    val scheduledTime: Instant,
    val actualTime: Instant?,
    val status: String  // "taken", "skipped", "snoozed"
)
```

```kotlin
// android/core/domain/src/main/kotlin/com/nateb/mymedtimer/domain/model/Medication.kt
package com.nateb.mymedtimer.domain.model

import java.time.Instant

data class Medication(
    val id: String,
    val name: String,
    val dosage: String,
    val colorHex: String = "#FF6B6B",
    val alertStyle: String = "gentle",
    val isPRN: Boolean = false,
    val minIntervalMinutes: Int = 0,
    val isActive: Boolean = true,
    val createdAt: Instant = Instant.now(),
    val scheduleTimes: List<ScheduleTime> = emptyList(),
    val doseLogs: List<DoseLog> = emptyList()
)
```

- [ ] **Step 2: Create repository interface**

```kotlin
// android/core/domain/src/main/kotlin/com/nateb/mymedtimer/domain/repository/MedicationRepository.kt
package com.nateb.mymedtimer.domain.repository

import com.nateb.mymedtimer.domain.model.DoseLog
import com.nateb.mymedtimer.domain.model.Medication
import kotlinx.coroutines.flow.Flow
import java.time.Instant

interface MedicationRepository {
    fun getAllMedications(): Flow<List<Medication>>
    fun getMedication(id: String): Flow<Medication?>
    suspend fun saveMedication(medication: Medication)
    suspend fun deleteMedication(id: String)
    suspend fun logDose(medicationId: String, scheduledTime: Instant, status: String)
    fun getDoseLogs(medicationId: String): Flow<List<DoseLog>>
}
```

- [ ] **Step 3: Verify domain module compiles**

```bash
cd android && ./gradlew :core:domain:build
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Run all tests to confirm nothing broke**

```bash
cd android && ./gradlew :math:test
```

Expected: all math tests still pass.

- [ ] **Step 5: Commit**

```bash
git add android/core/domain/
git commit -m "feat(android): add domain models and repository interface"
```

---

## Self-Review

**Spec coverage:**
- Module structure: Task 1 (scaffold) ✓
- Room entities: deferred to Plan 2 (core/data) ✓ correct
- Domain models: Task 5 ✓
- Repository interface: Task 5 ✓
- HawkesProcess: Task 2 ✓
- CircularStatistics: Task 3 ✓
- AdherenceEngine: Task 4 ✓
- MedicationInsight: Task 4 ✓
- RiskLevel: Task 2 ✓

**Placeholder scan:** No TBD, TODO, or vague steps found.

**Type consistency:**
- `RiskLevel` enum used in HawkesProcess (Task 2), AdherenceEngine (Task 4), MedicationInsight (Task 4) — consistent `RiskLevel.LOW/MEDIUM/HIGH`
- `HawkesParameters` data class used in HawkesProcess and AdherenceEngine — consistent
- `MedicationInsight` uses `Pair<Int, Int>` for times — consistent across all references
- `Instant` used for all timestamps — consistent
- `CircularStatistics.suggestedTime` returns `Pair<Int, Int>?` — matches usage in AdherenceEngine

All types, method signatures, and property names are consistent across tasks.
