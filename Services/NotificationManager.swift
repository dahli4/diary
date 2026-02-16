import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    static let openEditorFromReminder = Notification.Name("openEditorFromReminder")
    
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("알림 권한 허용됨")
            } else if let error = error {
                print("알림 권한 오류: \(error.localizedDescription)")
            }
            completion?(granted)
        }
    }
    
    func scheduleDailyNotification(hour: Int, minute: Int, prompt: String) {
        let content = UNMutableNotificationContent()
        content.title = "오늘의 회고 질문"
        content.body = prompt
        content.sound = .default
        content.userInfo = [
          "action": "open_editor",
          "prompt": prompt
        ]
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // 고유 식별자 사용
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func removeDailyNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
    }

    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        completion(settings.authorizationStatus)
      }
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    if let action = userInfo["action"] as? String, action == "open_editor" {
      let prompt = userInfo["prompt"] as? String
      DispatchQueue.main.async {
        NotificationCenter.default.post(
          name: NotificationManager.openEditorFromReminder,
          object: nil,
          userInfo: ["prompt": prompt ?? ReflectionAnalyzer.prompt()]
        )
      }
    }
    completionHandler()
  }
}
