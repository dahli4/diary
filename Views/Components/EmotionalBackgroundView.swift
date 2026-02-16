import SwiftUI

struct EmotionalBackgroundView: View {
  
  var body: some View {
    ZStack {
      // 1. 누런끼를 줄인 중성 톤 그라디언트
      LinearGradient(
        colors: [
          Color(red: 0.99, green: 0.97, blue: 0.97), // 소프트 아이보리
          Color(red: 0.97, green: 0.95, blue: 0.96), // 라이트 블러시 그레이
          Color(red: 0.95, green: 0.93, blue: 0.95)  // 뮤트 로즈 베이지
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      
      // 2. 채도를 낮춘 분위기 레이어
      GeometryReader { proxy in
        Circle()
          .fill(Color(red: 0.96, green: 0.83, blue: 0.82).opacity(0.18))
          .frame(width: proxy.size.width * 0.95)
          .blur(radius: 95)
          .offset(x: proxy.size.width * 0.28, y: -proxy.size.height * 0.22)
        
        Circle()
          .fill(Color(red: 0.91, green: 0.88, blue: 0.94).opacity(0.16))
          .frame(width: proxy.size.width * 0.92)
          .blur(radius: 92)
          .offset(x: -proxy.size.width * 0.32, y: proxy.size.height * 0.58)
        
        Circle()
          .fill(Color(red: 0.95, green: 0.90, blue: 0.88).opacity(0.14))
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
