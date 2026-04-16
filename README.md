# MyMedTimer

A medication reminder app for iOS with adherence analytics powered by Hawkes processes, circular statistics, and Whittle index optimization.

## Features

- **Flexible scheduling** with multiple daily dose times and as-needed (PRN) support
- **Persistent reminders** with gentle, urgent, and escalating alert styles
- **Nag mode** that follows up at configurable intervals until you respond
- **Dose logging** as taken, skipped, or snoozed with full history
- **8-week adherence heatmap** for visual pattern recognition
- **Adherence intelligence** using self-exciting point processes (Hawkes/Ozaki MLE) to predict miss risk, Von Mises circular statistics for time-of-day consistency, and Whittle restless bandit index for dynamic alert prioritization
- **Schedule suggestions** based on when you actually take your meds
- **Risk indicators** showing real-time adherence status per medication
- **Full VoiceOver support** with descriptive labels and proper traits
- **Haptic feedback** matched to alert style intensity
- **Privacy first**: all data on-device, no accounts, no tracking

## Tech Stack

- Swift, SwiftUI, SwiftData
- iOS 17+
- [Tuist](https://tuist.io) v4 for project generation
- Zero external dependencies

## Getting Started

```bash
# Install Tuist if needed
curl -Ls https://install.tuist.io | bash

# Generate Xcode project
tuist generate

# Open and run
open MyMedTimer.xcworkspace
```

## Math

The adherence engine combines three techniques:

**Hawkes Self-Exciting Process** fits miss event timestamps via MLE (Ozaki 1979) to estimate baseline miss intensity, excitation magnitude, and decay rate. A sigmoid maps current intensity to miss probability.

**Von Mises Circular Statistics** treats dose times as angles on a 24-hour circle, computing circular mean, concentration parameter (kappa), and consistency scores to detect schedule drift.

**Whittle Index** solves the restless multi-armed bandit problem for alert allocation: `W = (importance * missProbability) / fatigueCost`, balancing reminder effectiveness against notification fatigue.

## License

[MIT](LICENSE)
