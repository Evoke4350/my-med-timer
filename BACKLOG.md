# MyMedTimer Backlog

## Done

### Core Features
- [x] **1. Notification action handling** — UNUserNotificationCenterDelegate wired up; Taken/Snooze/Skip actions log doses, cancel nags
- [x] **2. Snooze rescheduling** — snooze fires a new one-shot notification after configurable snooze duration
- [x] **3. Fix notification ID leak** — old notification IDs captured before schedule deletion, cancelled properly
- [x] **4. Haptic feedback** — HapticService with gentle/warning/escalating/success patterns; fires on dose log and notification present
- [x] **5. Nag mode** — schedules up to 5 follow-up notifications at configured nag interval; cancelled on dose acknowledgment
- [x] **6. Delete confirmation** — alert dialog before deleting medication; also cancels notifications + nags
- [x] **7. Calendar heatmap in history** — 8-week grid at top of history view (green/red/yellow/orange dots)
- [x] **8. Faster countdown** — timers changed from 30s to 1s updates for responsive countdowns
- [x] **9. Fix version display** — reads from bundle instead of hardcoded
- [x] **12. Quick actions** — app icon shortcuts for "+ Add Med" and quick-log top 2 meds

### Adherence Intelligence
- [x] **22. Hawkes self-exciting process** — MLE-fitted λ(t) = μ + Σα·exp(-β(t-tᵢ)) models adherence drift from miss events; sigmoid miss probability mapping
- [x] **23. Circular statistics** — Von Mises distribution for time-of-day consistency; κ via Mardia-Jupp MLE; suggested schedule times
- [x] **24. Whittle index** — restless bandit priority: W = (importance × missProb) / fatigueCost; maps to alert style escalation
- [x] **25. AdherenceEngine** — orchestrates Hawkes + circular + Whittle; produces MedicationInsight per med with risk, consistency, drift, alert style
- [x] **26. Dynamic alert escalation** — NotificationDelegate uses AdherenceEngine to auto-escalate alert style based on adherence patterns
- [x] **27. Schedule suggestions** — AddEditMedView shows actual vs suggested time when drift >15min; consistency score display
- [x] **28. Risk indicators** — MedRowView shows colored dot (green/yellow/red) for miss risk level from Hawkes analysis

### HCI Polish
- [x] **15. VoiceOver accessibility** — all views have accessibility labels, traits, and descriptions; med rows announce name/dosage/countdown
- [x] **16. Edit discoverability** — leading swipe-to-edit, context menu with Edit/Delete, plus existing long-press
- [x] **17. Dose confirmation toast** — brief overlay shows "med — taken/skipped/snoozed" after logging, auto-dismisses 2s
- [x] **18. Animations & transitions** — subtle easeInOut animations on list reorder, dose logging, countdown color, heatmap fade-in, schedule add/remove
- [x] **19. Touch targets & contrast** — color circles 44x44, remove button 44x44, heatmap "none" cells more visible, legend fixed (added "mixed", renamed "late" to "snoozed")
- [x] **20. Timer consolidation** — single 1s timer in MedListView passed to all rows (was N+1 timers)
- [x] **21. Notification status in settings** — shows granted/denied/not determined, opens iOS Settings if denied

### Glanceable Surface (v1.5.0)
- [x] **10. Lock screen widget** — WidgetKit extension; accessoryRectangular/Circular/Inline + systemSmall
- [x] **11. Home screen widget** — TodayMedsWidget systemMedium/Large showing remaining doses
- [x] **14. Live Activities / Dynamic Island** — MedTimerLiveActivity, started when next dose ≤1h, ends on dose log
- [x] **29. App Group + snapshot pipeline** — `group.com.nateb.mymedtimer`, JSON snapshot drives widgets/Live Activity

## To Do

### Deferred (Needs Entitlement)

- [ ] **13. Critical alerts** — bypass DND, requires Apple entitlement approval
