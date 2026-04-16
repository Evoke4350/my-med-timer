import UIKit

enum HapticService {
    enum Pattern {
        case notification  // gentle pulse
        case warning       // urgent double-tap
        case success       // confirmed action
        case escalating    // repeated heavy buzz
    }

    static func play(_ pattern: Pattern) {
        switch pattern {
        case .notification:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)

        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        case .escalating:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                generator.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                generator.impactOccurred()
            }
        }
    }

    static func playForAlertStyle(_ style: String) {
        switch style {
        case "urgent": play(.warning)
        case "escalating": play(.escalating)
        default: play(.notification)
        }
    }
}
