import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {
  private let notificationDelegate = NotificationDelegate()

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = notificationDelegate
    return true
  }
}
