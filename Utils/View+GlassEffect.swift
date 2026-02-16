import SwiftUI

// 아이오에스 기본 소재만으로는 회색빛이 돌거나 밋밋할 수 있습니다.
// 이 모디파이어는 화이트 틴트와 엣지 라이트를 추가하여
// 더 맑고 투명하며 입체적인 '리퀴드 글래스' 느낌을 구현합니다.
struct GlassEffect<S: InsettableShape>: ViewModifier {
  var shape: S
  
  func body(content: Content) -> some View {
    content
      .background {
        ZStack {
          // 1. 더 맑고 투명한 베이스(얼음 같은 느낌)
          Rectangle()
            .fill(.thinMaterial)
            .opacity(0.95)
          
          // 2. 미세한 화이트 틴트로 톤 정리
          Rectangle()
            .fill(Color.white.opacity(0.08))
          
          // 3. 은은한 빛 반사(과하지 않게)
          Rectangle()
            .fill(
              LinearGradient(
                colors: [
                  .white.opacity(0.35),
                  .white.opacity(0.05),
                  .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
        }
        .clipShape(shape)
      }
      .environment(\.colorScheme, .light)
      .overlay {
        // 4. 아주 얇고 섬세한 림 라이트(0.5포인트)
        shape
          .strokeBorder(
            LinearGradient(
              colors: [
                .white.opacity(0.6),
                .white.opacity(0.1),
                .white.opacity(0.05)
              ],
              startPoint: .top,
              endPoint: .bottom
            ),
            lineWidth: 0.5
          )
      }
    // 5. 부드럽고 깊이감 있는 그림자
      .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
  }
}

extension View {
  func liquidGlass<S: InsettableShape>(in shape: S) -> some View {
    self.modifier(GlassEffect(shape: shape))
  }
}
