import SwiftUI

// 다크/라이트 모드 모두 대응하는 리퀴드 글래스 이펙트
struct GlassEffect<S: InsettableShape>: ViewModifier {
  var shape: S
  @Environment(\.colorScheme) private var colorScheme

  private var isDark: Bool { colorScheme == .dark }

  func body(content: Content) -> some View {
    content
      .background {
        ZStack {
          if isDark {
            // 다크모드: 배경 글로우를 흡수하지 않도록 단색 베이스 사용
            Rectangle()
              .fill(Color(white: 0.16))
            Rectangle()
              .fill(Color.white.opacity(0.04))
          } else {
            // 라이트모드: 기존 머티리얼 + 화이트 틴트
            Rectangle()
              .fill(.thinMaterial)
              .opacity(0.95)
            Rectangle()
              .fill(Color.white.opacity(0.08))
            Rectangle()
              .fill(
                LinearGradient(
                  colors: [.white.opacity(0.35), .white.opacity(0.05), .clear],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
          }
        }
        .clipShape(shape)
      }
      .overlay {
        // 4. 림 라이트
        shape
          .strokeBorder(
            LinearGradient(
              colors: isDark ? [
                .white.opacity(0.20),
                .white.opacity(0.05),
                .white.opacity(0.02)
              ] : [
                .white.opacity(0.60),
                .white.opacity(0.10),
                .white.opacity(0.05)
              ],
              startPoint: .top,
              endPoint: .bottom
            ),
            lineWidth: 0.5
          )
      }
      .shadow(color: .black.opacity(isDark ? 0.30 : 0.08), radius: 16, x: 0, y: 8)
  }
}

extension View {
  func liquidGlass<S: InsettableShape>(in shape: S) -> some View {
    self.modifier(GlassEffect(shape: shape))
  }
}
