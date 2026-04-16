# MyMedTimer Backlog

## Done

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

## To Do

### Medium (Phase 2/3)

- [ ] **10. Lock screen widget** — WidgetKit extension showing next med + countdown
- [ ] **11. Home screen widget** — today's remaining meds

### Deferred (Needs Entitlement/Major Work)

- [ ] **13. Critical alerts** — bypass DND, requires Apple entitlement approval
- [ ] **14. Live Activities / Dynamic Island** — active countdown on lock screen
