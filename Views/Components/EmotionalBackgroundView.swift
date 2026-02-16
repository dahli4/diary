import SwiftUI

struct EmotionalBackgroundView: View {
  
  var body: some View {
    ZStack {
      // 1. 노란끼를 더 덜어낸 중성 베이스 톤
      LinearGradient(
        colors: [
          Color(red: 0.98, green: 0.98, blue: 0.99), // 쿨 라이트
          Color(red: 0.96, green: 0.95, blue: 0.97), // 소프트 라일락 그레이
          Color(red: 0.94, green: 0.93, blue: 0.96)  // 뮤트 로즈 그레이
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      
      // 2. 채도를 낮춘 컬러 글로우 레이어
      GeometryReader { proxy in
        Circle()
          .fill(Color(red: 0.94, green: 0.80, blue: 0.80).opacity(0.16))
          .frame(width: proxy.size.width * 0.95)
          .blur(radius: 95)
          .offset(x: proxy.size.width * 0.28, y: -proxy.size.height * 0.22)
        
        Circle()
          .fill(Color(red: 0.88, green: 0.87, blue: 0.95).opacity(0.14))
          .frame(width: proxy.size.width * 0.92)
          .blur(radius: 92)
          .offset(x: -proxy.size.width * 0.32, y: proxy.size.height * 0.58)
        
        Circle()
          .fill(Color(red: 0.92, green: 0.89, blue: 0.92).opacity(0.12))
          .frame(width: proxy.size.width * 0.70)
          .blur(radius: 72)
          .offset(x: proxy.size.width * 0.06, y: proxy.size.height * 0.18)

        Rectangle()
          .fill(
            LinearGradient(
              colors: [
                Color.white.opacity(0.20),
                Color.white.opacity(0.04)
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .blendMode(.softLight)
      }
      .ignoresSafeArea()

      // 3. 미세한 질감 오버레이
      PaperTextureOverlay()
        .ignoresSafeArea()
    }
  }
}

private struct PaperTextureOverlay: View {
  var body: some View {
    Canvas { context, size in
      let step: CGFloat = 12
      var y: CGFloat = 0
      while y < size.height {
        var x: CGFloat = 0
        while x < size.width {
          let wave = sin((x * 0.12) + (y * 0.08))
          let alpha = 0.014 + (wave * 0.004)
          let rect = CGRect(x: x, y: y, width: 1, height: 1)
          context.fill(Path(rect), with: .color(Color.black.opacity(alpha)))
          x += step
        }
        y += step
      }
    }
    .blendMode(.softLight)
    .opacity(0.55)
  }
}
