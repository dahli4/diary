import SwiftUI

struct EmotionalBackgroundView: View {
  
  var body: some View {
    ZStack {
      // 1. 기본 그라디언트(노란기를 줄인 웜 뉴트럴)
      LinearGradient(
        colors: [
          Color(red: 0.98, green: 0.97, blue: 0.96), // 웜 화이트
          Color(red: 0.96, green: 0.94, blue: 0.93), // 샌드 베이지
          Color(red: 0.95, green: 0.92, blue: 0.91)  // 로즈 베이지
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      
      // 2. 분위기 레이어(부드러운 색점)
      GeometryReader { proxy in
        Circle()
          .fill(Color(red: 0.97, green: 0.80, blue: 0.75).opacity(0.18))
          .frame(width: proxy.size.width * 0.88)
          .blur(radius: 102)
          .offset(x: proxy.size.width * 0.28, y: -proxy.size.height * 0.22)
        
        Circle()
          .fill(Color(red: 0.92, green: 0.84, blue: 0.78).opacity(0.14))
          .frame(width: proxy.size.width * 0.86)
          .blur(radius: 98)
          .offset(x: -proxy.size.width * 0.32, y: proxy.size.height * 0.58)
        
        Circle()
          .fill(Color(red: 0.94, green: 0.86, blue: 0.84).opacity(0.12))
          .frame(width: proxy.size.width * 0.64)
          .blur(radius: 84)
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
    }
  }
}
