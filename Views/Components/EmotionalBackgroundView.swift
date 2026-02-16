import SwiftUI

struct EmotionalBackgroundView: View {
  @Environment(\.colorScheme) private var colorScheme

  private var isDark: Bool { colorScheme == .dark }
  private var baseGradient: [Color] {
    if isDark {
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
  
  var body: some View {
    ZStack {
      // 1. 라이트/다크 모드 각각에 맞춘 중성 배경 톤
      LinearGradient(
        colors: baseGradient,
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      
      // 2. 채도를 낮춘 글로우 레이어
      GeometryReader { proxy in
        Circle()
          .fill((isDark ? Color(red: 0.60, green: 0.25, blue: 0.28) : Color(red: 0.94, green: 0.80, blue: 0.80)).opacity(isDark ? 0.18 : 0.15))
          .frame(width: proxy.size.width * 0.95)
          .blur(radius: 95)
          .offset(x: proxy.size.width * 0.28, y: -proxy.size.height * 0.22)
        
        Circle()
          .fill((isDark ? Color(red: 0.32, green: 0.28, blue: 0.52) : Color(red: 0.88, green: 0.87, blue: 0.95)).opacity(isDark ? 0.16 : 0.13))
          .frame(width: proxy.size.width * 0.92)
          .blur(radius: 92)
          .offset(x: -proxy.size.width * 0.32, y: proxy.size.height * 0.58)
        
        Circle()
          .fill((isDark ? Color(red: 0.34, green: 0.34, blue: 0.40) : Color(red: 0.92, green: 0.89, blue: 0.92)).opacity(isDark ? 0.12 : 0.10))
          .frame(width: proxy.size.width * 0.70)
          .blur(radius: 72)
          .offset(x: proxy.size.width * 0.06, y: proxy.size.height * 0.18)

        Rectangle()
          .fill(
            LinearGradient(
              colors: [
                (isDark ? Color.white.opacity(0.05) : Color.white.opacity(0.18)),
                (isDark ? Color.white.opacity(0.01) : Color.white.opacity(0.04))
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .blendMode(isDark ? .overlay : .softLight)
      }
      .ignoresSafeArea()

      // 3. 미세 질감을 더해 단조로움을 줄인다.
      PaperTextureOverlay(isDark: isDark)
        .ignoresSafeArea()
    }
  }
}

private struct PaperTextureOverlay: View {
  let isDark: Bool

  var body: some View {
    Canvas { context, size in
      let step: CGFloat = 12
      var y: CGFloat = 0
      while y < size.height {
        var x: CGFloat = 0
        while x < size.width {
          let wave = sin((x * 0.12) + (y * 0.08))
          let alpha = (isDark ? 0.020 : 0.013) + (wave * (isDark ? 0.003 : 0.004))
          context.fill(Path(CGRect(x: x, y: y, width: 1, height: 1)), with: .color(Color.black.opacity(alpha)))
          x += step
        }
        y += step
      }
    }
    .blendMode(isDark ? .overlay : .softLight)
    .opacity(isDark ? 0.60 : 0.50)
  }
}
