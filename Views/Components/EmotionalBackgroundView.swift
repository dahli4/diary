import SwiftUI

struct EmotionalBackgroundView: View {
  
  var body: some View {
    ZStack {
      // 1. 기본 그라디언트(밝고 따뜻한 톤)
      LinearGradient(
        colors: [
          Color(red: 1.00, green: 0.98, blue: 0.96), // 크림
          Color(red: 0.97, green: 0.96, blue: 1.00), // 연보라
          Color(red: 0.94, green: 0.98, blue: 0.98)  // 민트 화이트
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      
      // 2. 분위기 레이어(부드러운 색점)
      GeometryReader { proxy in
        Circle()
          .fill(Color(red: 1.00, green: 0.82, blue: 0.73).opacity(0.26))
          .frame(width: proxy.size.width * 0.95)
          .blur(radius: 95)
          .offset(x: proxy.size.width * 0.28, y: -proxy.size.height * 0.22)
        
        Circle()
          .fill(Color(red: 0.64, green: 0.87, blue: 0.84).opacity(0.24))
          .frame(width: proxy.size.width * 0.92)
          .blur(radius: 92)
          .offset(x: -proxy.size.width * 0.32, y: proxy.size.height * 0.58)
        
        Circle()
          .fill(Color(red: 0.92, green: 0.80, blue: 1.00).opacity(0.20))
          .frame(width: proxy.size.width * 0.70)
          .blur(radius: 72)
          .offset(x: proxy.size.width * 0.06, y: proxy.size.height * 0.18)

        Rectangle()
          .fill(
            LinearGradient(
              colors: [
                Color.white.opacity(0.28),
                Color.white.opacity(0.04)
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .blendMode(.softLight)
      }
      .ignoresSafeArea()
    }
  }
}
