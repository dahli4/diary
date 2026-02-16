import SwiftUI

struct SettingsView: View {
  @AppStorage("isNotificationEnabled") private var notificationsEnabled = false
  @AppStorage("isBiometricLockEnabled") private var biometricLockEnabled = false
  @EnvironmentObject private var authenticationService: AuthenticationService
  @Environment(\.colorScheme) private var colorScheme
  
  var body: some View {
    ZStack {
      EmotionalBackgroundView()
        .ignoresSafeArea()

      Form {
        Section(header: Text("알림")) {
          Toggle("매일 알림 받기", isOn: $notificationsEnabled)
            .tint(AppTheme.pointColor)
            .onChange(of: notificationsEnabled) { _, newValue in
              handleNotificationToggle(isEnabled: newValue)
            }
          Text("오후 9시에 알림이 전송됩니다.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Section(header: Text("보안")) {
          Toggle("Face ID / Touch ID 잠금", isOn: $biometricLockEnabled)
            .tint(AppTheme.pointColor)
            .disabled(!authenticationService.isBiometricAvailable)
          if !authenticationService.isBiometricAvailable {
            Text("이 기기에서는 생체 인증을 사용할 수 없습니다.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        
        Section(header: Text("데이터")) {
          NavigationLink(destination: TrashListView()) {
            Label("휴지통", systemImage: "trash")
          }
          
          Text("데이터는 iCloud에 자동으로 동기화됩니다.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        
        Section(header: Text("앱 정보")) {
          HStack {
            Text("버전")
            Spacer()
            Text("1.0.0")
              .foregroundStyle(.secondary)
          }
        }
      }
      .scrollContentBackground(.hidden)
      .background(Color.clear)
      .listRowBackground(AppTheme.formRowBackground(for: colorScheme))
    }
    .navigationTitle("설정")
    .onAppear {
      NotificationManager.shared.getAuthorizationStatus { status in
        DispatchQueue.main.async {
          notificationsEnabled = (status == .authorized || status == .provisional)
        }
      }
      authenticationService.checkBiometryAvailability()
    }
  }
  
  private func handleNotificationToggle(isEnabled: Bool) {
    if isEnabled {
      NotificationManager.shared.requestAuthorization { granted in
        DispatchQueue.main.async {
          if granted {
            let prompt = ReflectionAnalyzer.prompt()
            NotificationManager.shared.scheduleDailyNotification(hour: 21, minute: 0, prompt: prompt)
          } else {
            notificationsEnabled = false
          }
        }
      }
    } else {
      NotificationManager.shared.removeDailyNotification()
    }
  }
}
