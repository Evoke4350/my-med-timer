# MyMedTimer — App Spec

**Purpose:** Replace the $90 TabTimer vibrating pill reminder device with a free iOS app.

## What TabTimer Does (features to match or beat)

| TabTimer Feature | MyMedTimer Equivalent |
|---|---|
| Up to 12 daily alarms | Unlimited named medication alarms |
| Vibration-only alerts | Haptic patterns (configurable per med) |
| Countdown timer between doses | Live countdown with lock screen widget |
| Simple 2-button interface | Minimal single-screen UI |
| Pocket-sized, always on | iOS app + background notifications |
| Water resistant | N/A (it's a phone) |

## Core Features

### 1. Medication List (Home Screen)
- List of medications, each with:
  - Name (e.g., "Metformin", "Vitamin D")
  - Dosage text (e.g., "500mg", "2 pills")
  - Schedule: specific times of day (e.g., 8:00 AM, 2:00 PM, 8:00 PM)
  - Color tag (quick visual ID)
  - Next dose countdown (live-updating)
- Sorted by next upcoming dose
- Tap to log "taken" / "skipped" / "snoozed"

### 2. Alarm System
- Local notifications at each scheduled time
- **Critical alerts** (optional, bypasses Do Not Disturb — requires entitlement)
- Haptic feedback patterns:
  - Gentle pulse (default)
  - Urgent buzz (for critical meds)
  - Repeated escalation (buzzes harder if not acknowledged)
- Snooze: 5 / 10 / 15 / 30 min options
- Nag mode: repeats notification every N minutes until acknowledged
- Sound options: subtle chime, loud alarm, silent (vibrate only)

### 3. Countdown Timer
- Per-medication "time until next dose" displayed on home screen
- Lock screen Live Activity showing next upcoming med
- "Take now" button resets countdown and logs dose

### 4. Dose History
- Simple log: medication, time taken/skipped, date
- Calendar view showing adherence (green = taken, red = missed, yellow = late)
- No analytics beyond this — keep it grungy and simple

### 5. Quick Actions
- Long-press app icon: "Log [most frequent med]", "Snooze All"
- Notification actions: "Taken", "Snooze 10min", "Skip"

## Non-Features (Intentionally Excluded)
- No accounts / login / cloud sync
- No doctor sharing / export
- No pharmacy integration
- No drug interaction database
- No social features
- No onboarding tutorial (it's obvious)
- No ads, no IAP, no tracking
- Core Data local storage only

## UI / UX

### Vibe: Grungy Personal Tool
- Dark theme default (OLED-friendly)
- Monospace or condensed font for countdowns
- Minimal chrome — no tab bar, no nav bar title clutter
- Single main screen + sheet for add/edit
- Muted colors, high contrast text
- Feels like a terminal countdown clock, not a wellness app

### Screens
1. **Med List** — home screen, shows all meds with next-dose countdown
2. **Add/Edit Med** — sheet: name, dosage, schedule times, color, alert style
3. **History** — scrollable log, calendar heatmap at top
4. **Settings** — default snooze time, haptic style, nag interval, critical alerts toggle

### Navigation
- Bottom toolbar: [+ Add Med] [History] [Settings]
- Swipe med row to delete
- Tap med row to log dose, long-press to edit

## Technical Architecture

### Platform
- iOS 17+ (no need to support older)
- Swift / SwiftUI
- No external dependencies (zero SPM packages)

### Data
- SwiftData (Core Data successor, built-in)
- Models:
  - `Medication`: id, name, dosage, color, alertStyle, isActive
  - `Schedule`: id, medicationId, times: [Date components], daysOfWeek
  - `DoseLog`: id, medicationId, scheduledTime, actualTime, status (taken/skipped/snoozed)

### Notifications
- `UNUserNotificationCenter` for local notifications
- Schedule all upcoming notifications on app launch + when meds change
- Custom notification actions (taken/snooze/skip)
- Background refresh to reschedule if needed

### Widgets
- Lock screen widget: next med name + countdown
- Home screen widget: today's remaining meds

### Live Activities
- Optional: show active countdown on Dynamic Island / lock screen
- Start when app goes to background, end when dose logged

## Project Setup

### Xcode Project
- Bundle ID: `com.nateb.mymedtimer`
- Team: H82APH3TK5
- Deployment target: iOS 17.0
- Single target (no extensions initially, add widget later)

### App Store Connect (via `altool` / ASC API)
- API Key: `SQNHUVE5KO9T` (file: `ApiKey_SQNHUVE5KO9T.p8`)
- Create app record via ASC CLI
- TestFlight internal testing group
- Category: Medical (or Health & Fitness)

### TestFlight Pipeline
```
xcodebuild archive → xcodebuild -exportArchive → xcrun altool --upload-app
```
Or use ASC API for full automation.

## Build Phases

### Phase 1 — MVP (get to TestFlight)
- [ ] Xcode project setup
- [ ] SwiftData models
- [ ] Med list screen (add/edit/delete)
- [ ] Local notification scheduling
- [ ] Notification actions (taken/snooze/skip)
- [ ] Dose logging
- [ ] Basic history view
- [ ] Settings screen
- [ ] App icon (simple, grungy)
- [ ] TestFlight upload

### Phase 2 — Match TabTimer
- [ ] Haptic patterns
- [ ] Nag mode (repeat notifications)
- [ ] Lock screen widget
- [ ] Critical alerts entitlement
- [ ] Snooze escalation

### Phase 3 — Beat TabTimer
- [ ] Live Activities / Dynamic Island countdown
- [ ] Home screen widget
- [ ] Calendar heatmap in history
- [ ] Quick actions (app icon shortcuts)

## App Store Metadata (for TestFlight)
- **Name:** MyMedTimer
- **Subtitle:** Medication Alarm & Timer
- **Description:** Simple medication reminder. Set times, get buzzed, log doses. No accounts, no cloud, no nonsense. Replaces your $90 pill timer.
- **Keywords:** medication,reminder,pill,timer,alarm,dose,health
- **Primary Language:** English
- **Content Rights:** Does not contain third-party content
- **Age Rating:** 4+
