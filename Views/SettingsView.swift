import SwiftUI

// 설정 항목 아이콘 (iOS 설정 앱 HIG 스타일)
private struct SettingIconView: View {
  let systemName: String
  let color: Color
  var body: some View {
    Image(systemName: systemName)
      .font(.system(size: 14, weight: .semibold))
      .foregroundColor(.white)
      .frame(width: 30, height: 30)
      .background(color)
      .clipShape(RoundedRectangle(cornerRadius: 7))
  }
}

struct SettingsView: View {
  @AppStorage("isNotificationEnabled") private var notificationsEnabled = false
  @AppStorage("isBiometricLockEnabled") private var biometricLockEnabled = false
  @AppStorage("appearanceMode") private var appearanceMode = 0 // 0: 시스템, 1: 라이트, 2: 다크
  @AppStorage("notificationHour") private var notificationHour = 21
  @AppStorage("notificationMinute") private var notificationMinute = 0
  @EnvironmentObject private var authenticationService: AuthenticationService
  @Environment(\.colorScheme) private var colorScheme

  // MARK: - ViewModel

  @StateObject private var viewModel = SettingsViewModel()

  var body: some View {
    ZStack {
      EmotionalBackgroundView()
        .ignoresSafeArea()

      Form {
        // 디스플레이 섹션
        Section(header: Text("디스플레이")) {
          HStack(spacing: 12) {
            SettingIconView(systemName: "paintpalette.fill", color: .blue)
            NavigationLink(destination: ThemeSelectionView(appearanceMode: $appearanceMode)) {
              HStack {
                Text("화면 모드")
                Spacer()
                Text(viewModel.appearanceModeLabel(for: appearanceMode))
                  .foregroundStyle(.secondary)
              }
            }
          }
          .listRowBackground(AppTheme.formRowBackground(for: colorScheme))
        }

        // 알림 섹션
        Section(header: Text("알림")) {
          HStack(spacing: 12) {
            SettingIconView(systemName: "bell.fill", color: .red)
            Toggle("매일 알림 받기", isOn: $notificationsEnabled)
              .tint(AppTheme.pointColor)
              .onChange(of: notificationsEnabled) { _, newValue in
                viewModel.handleNotificationToggle(
                  isEnabled: newValue,
                  hour: notificationHour,
                  minute: notificationMinute,
                  onDenied: { notificationsEnabled = false }
                )
              }
          }
          .listRowBackground(AppTheme.formRowBackground(for: colorScheme))

          if notificationsEnabled {
            DatePicker(
              "알림 시간",
              selection: Binding(
                get: { viewModel.makeNotificationDate(hour: notificationHour, minute: notificationMinute) },
                set: { date in
                  let cal = Calendar.current
                  notificationHour = cal.component(.hour, from: date)
                  notificationMinute = cal.component(.minute, from: date)
                  viewModel.rescheduleNotification(hour: notificationHour, minute: notificationMinute)
                }
              ),
              displayedComponents: .hourAndMinute
            )
            .tint(AppTheme.pointColor)
            .listRowBackground(AppTheme.formRowBackground(for: colorScheme))
          }
        }

        // 보안 섹션
        Section(header: Text("보안")) {
          HStack(spacing: 12) {
            SettingIconView(systemName: "faceid", color: .green)
            Toggle("Face ID / Touch ID 잠금", isOn: $biometricLockEnabled)
              .tint(AppTheme.pointColor)
              .disabled(!authenticationService.isBiometricAvailable)
          }
          .listRowBackground(AppTheme.formRowBackground(for: colorScheme))

          if !authenticationService.isBiometricAvailable {
            Text("이 기기에서는 생체 인증을 사용할 수 없습니다.")
              .font(.caption)
              .foregroundStyle(.secondary)
              .listRowBackground(AppTheme.formRowBackground(for: colorScheme))
          }
        }

        // 데이터 섹션
        Section(header: Text("데이터")) {
          HStack(spacing: 12) {
            SettingIconView(systemName: "trash.fill", color: .gray)
            NavigationLink(destination: TrashListView()) {
              Text("휴지통")
            }
          }
          .listRowBackground(AppTheme.formRowBackground(for: colorScheme))

          Text("데이터는 기기에 안전하게 저장됩니다.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .listRowBackground(AppTheme.formRowBackground(for: colorScheme))
        }
      }
      .scrollContentBackground(.hidden)
      .background(Color.clear)
    }
    .navigationTitle("설정")
    .onAppear {
      // 알림 권한 상태를 확인하여 토글 상태를 갱신한다
      viewModel.checkNotificationStatus { isEnabled in
        notificationsEnabled = isEnabled
      }
      authenticationService.checkBiometryAvailability()
    }
  }
}

// 화면 모드 선택 화면 — 앱 공통 배경 적용
private struct ThemeSelectionView: View {
  @Binding var appearanceMode: Int
  @Environment(\.colorScheme) private var colorScheme

  private let options: [(label: String, tag: Int)] = [
    ("시스템", 0),
    ("라이트", 1),
    ("다크",   2)
  ]

  var body: some View {
    ZStack {
      EmotionalBackgroundView()
        .ignoresSafeArea()

      Form {
        Section {
          ForEach(options, id: \.tag) { option in
            Button {
              appearanceMode = option.tag
            } label: {
              HStack {
                Text(option.label)
                  .foregroundStyle(.primary)
                Spacer()
                if appearanceMode == option.tag {
                  Image(systemName: "checkmark")
                    .foregroundStyle(AppTheme.pointColor)
                    .fontWeight(.semibold)
                }
              }
            }
            .listRowBackground(AppTheme.formRowBackground(for: colorScheme))
          }
        }
      }
      .scrollContentBackground(.hidden)
      .background(Color.clear)
    }
    .navigationTitle("화면 모드")
  }
}
