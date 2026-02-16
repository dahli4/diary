import SwiftUI

struct EmotionalBackgroundView: View {
  
  var body: some View {
    ZStack {
      // 1. 기본 그라디언트(깊은 톤)
      LinearGradient(
        colors: [
          Color(red: 0.9, green: 0.94, blue: 1.0), // 차가운 블루
          Color(red: 0.95, green: 0.92, blue: 0.98), // 부드러운 라벤더
          Color(red: 1.0, green: 0.95, blue: 0.92)  // 따뜻한 피치
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()
      
      // 2. 깊이감을 위한 메쉬형 포인트
      GeometryReader { proxy in
        // 오른쪽 위의 따뜻함
        Circle()
          .fill(Color(red: 1.0, green: 0.8, blue: 0.8).opacity(0.4))
          .frame(width: proxy.size.width * 0.8)
          .blur(radius: 80)
          .offset(x: proxy.size.width * 0.3, y: -proxy.size.height * 0.2)
        
        // 왼쪽 아래의 차가움
        Circle()
          .fill(Color(red: 0.7, green: 0.8, blue: 1.0).opacity(0.4))
          .frame(width: proxy.size.width * 0.8)
          .blur(radius: 80)
          .offset(x: -proxy.size.width * 0.3, y: proxy.size.height * 0.6)
        
        // 중앙 포인트
        Circle()
          .fill(Color(red: 0.9, green: 0.8, blue: 1.0).opacity(0.3))
          .frame(width: proxy.size.width * 0.6)
          .blur(radius: 60)
          .offset(x: proxy.size.width * 0.2, y: proxy.size.height * 0.2)
      }
      .ignoresSafeArea()
    }
  }
}
