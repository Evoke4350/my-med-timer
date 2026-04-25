import SwiftUI
import WidgetKit

@main
struct MyMedTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextMedWidget()
        TodayMedsWidget()
        MedTimerLiveActivity()
    }
}
