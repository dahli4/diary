import Foundation
import WidgetKit

/// 메인 앱 → 위젯으로 데이터를 공유하는 서비스
/// App Group UserDefaults를 통해 위젯에 필요한 최소 데이터를 저장한다.
enum WidgetDataService {
  // TODO: Xcode에서 App Group 설정 후 실제 bundle ID로 교체하세요.
  private static let suiteName = "group.com.myapp.diary"

  static func update(lastMood: String?, lastTitle: String?, wroteToday: Bool, streakCount: Int) {
    guard let defaults = UserDefaults(suiteName: suiteName) else { return }
    defaults.set(lastMood, forKey: "widget_lastMood")
    defaults.set(lastTitle, forKey: "widget_lastTitle")
    defaults.set(wroteToday, forKey: "widget_wroteToday")
    defaults.set(streakCount, forKey: "widget_streakCount")
    // 위젯 타임라인 즉시 갱신
    WidgetCenter.shared.reloadAllTimelines()
  }
}
