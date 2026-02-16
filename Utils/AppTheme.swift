import SwiftUI

enum AppTheme {
  // 앱 전반에서 사용하는 공통 포인트 색상
  static let pointColor = Color(red: 0.90, green: 0.27, blue: 0.30)

  // 화면 기본 배경 그라디언트
  static func backgroundGradient(for scheme: ColorScheme) -> [Color] {
    if scheme == .dark {
      return [
        Color(red: 0.10, green: 0.10, blue: 0.13),
        Color(red: 0.12, green: 0.11, blue: 0.15),
        Color(red: 0.14, green: 0.12, blue: 0.17)
      ]
    }
    return [
      Color(red: 0.98, green: 0.98, blue: 0.99),
      Color(red: 0.96, green: 0.95, blue: 0.97),
      Color(red: 0.94, green: 0.93, blue: 0.96)
    ]
  }

  // 배경 글로우 색상 세트
  static func glowColors(for scheme: ColorScheme) -> [Color] {
    if scheme == .dark {
      return [
        Color(red: 0.60, green: 0.25, blue: 0.28),
        Color(red: 0.32, green: 0.28, blue: 0.52),
        Color(red: 0.34, green: 0.34, blue: 0.40)
      ]
    }
    return [
      Color(red: 0.94, green: 0.80, blue: 0.80),
      Color(red: 0.88, green: 0.87, blue: 0.95),
      Color(red: 0.92, green: 0.89, blue: 0.92)
    ]
  }

  // 설정 Form 행의 공통 배경 톤
  static func formRowBackground(for scheme: ColorScheme) -> Color {
    scheme == .dark ? Color.white.opacity(0.07) : Color.white.opacity(0.38)
  }
}
