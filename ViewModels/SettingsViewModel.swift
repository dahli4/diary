import SwiftUI
import Combine

// MARK: - SettingsViewModel
// @AppStorage는 View에서만 사용 가능하므로 메서드는 값을 매개변수로 받는 방식으로 설계

@MainActor
class SettingsViewModel: ObservableObject {

  // MARK: - 의존성

  private let notificationManager: NotificationManager

  // MARK: - 초기화

  init(notificationManager: NotificationManager = .shared) {
    self.notificationManager = notificationManager
  }

  // MARK: - 외관 레이블

  /// 모드 정수값(0: 시스템 / 1: 라이트 / 2: 다크)을 한국어 레이블로 변환
  func appearanceModeLabel(for mode: Int) -> String {
    switch mode {
    case 1: return "라이트"
    case 2: return "다크"
    default: return "시스템"
    }
  }

  // MARK: - 알림 날짜 생성

  /// 저장된 시/분 값으로 오늘 날짜의 Date 객체를 생성한다
  func makeNotificationDate(hour: Int, minute: Int) -> Date {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    components.hour = hour
    components.minute = minute
    return Calendar.current.date(from: components) ?? Date()
  }

  // MARK: - 알림 재등록

  /// 기존 알림을 제거하고 새로운 시간으로 재등록한다
  func rescheduleNotification(hour: Int, minute: Int) {
    notificationManager.removeDailyNotification()
    let prompt = ReflectionAnalyzer.prompt()
    notificationManager.scheduleDailyNotification(hour: hour, minute: minute, prompt: prompt)
  }

  // MARK: - 알림 토글 처리

  /// 알림 활성화/비활성화 처리 (권한 요청 포함)
  /// - Parameters:
  ///   - isEnabled: 활성화 여부
  ///   - hour: 알림 시간 (시)
  ///   - minute: 알림 시간 (분)
  ///   - onDenied: 권한 거부 시 호출될 콜백 (notificationsEnabled 원복용)
  func handleNotificationToggle(isEnabled: Bool, hour: Int, minute: Int, onDenied: @escaping () -> Void) {
    if isEnabled {
      notificationManager.requestAuthorization { granted in
        DispatchQueue.main.async {
          if granted {
            let prompt = ReflectionAnalyzer.prompt()
            self.notificationManager.scheduleDailyNotification(hour: hour, minute: minute, prompt: prompt)
          } else {
            onDenied()
          }
        }
      }
    } else {
      notificationManager.removeDailyNotification()
    }
  }

  // MARK: - 알림 권한 상태 확인

  /// 현재 알림 권한 상태를 확인하고 콜백으로 결과를 전달한다
  func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
    notificationManager.getAuthorizationStatus { status in
      DispatchQueue.main.async {
        completion(status == .authorized || status == .provisional)
      }
    }
  }
}
