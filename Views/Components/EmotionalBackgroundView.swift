import SwiftUI

struct EmotionalBackgroundView: View {
  
  var body: some View {
    ZStack {
      // 1. 기본 그라디언트(코랄, 크림, 베이지 중심)
      LinearGradient(
        colors: [
          Color(red: 1.00, green: 0.96, blue: 0.92), // 웜 크림
          Color(red: 0.99, green: 0.93, blue: 0.88), // 라이트 베이지
          Color(red: 0.98, green: 0.89, blue: 0.84)  // 소프트 코랄 베이지
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
          .fill(Color(red: 0.98, green: 0.86, blue: 0.76).opacity(0.22))
          .frame(width: proxy.size.width * 0.92)
          .blur(radius: 92)
          .offset(x: -proxy.size.width * 0.32, y: proxy.size.height * 0.58)
        
        Circle()
          .fill(Color(red: 0.97, green: 0.90, blue: 0.84).opacity(0.18))
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
