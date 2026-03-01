import SwiftUI

struct OnboardingView: View {
  @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
  @Environment(\.colorScheme) private var colorScheme
  @State private var currentPage = 0

  private let pages: [OnboardingPage] = [
    OnboardingPage(
      icon: "heart.text.square.fill",
      title: "나만의 감정 일기",
      description: "하루의 감정을 기록하고\n나를 더 깊이 이해해 보세요."
    ),
    OnboardingPage(
      icon: "chart.line.uptrend.xyaxis",
      title: "감정 흐름 한눈에",
      description: "캘린더와 통계로 내 감정의\n변화를 시각적으로 확인해요."
    ),
    OnboardingPage(
      icon: "lock.shield.fill",
      title: "완전한 프라이버시",
      description: "데이터는 기기에 저장되고\nFace ID로 안전하게 보호돼요."
    )
  ]

  var body: some View {
    ZStack {
      EmotionalBackgroundView()
        .ignoresSafeArea()

      VStack(spacing: 0) {
        TabView(selection: $currentPage) {
          ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
            pageView(page)
              .tag(index)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentPage)

        VStack(spacing: 20) {
          // 페이지 인디케이터
          HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
              Capsule()
                .fill(index == currentPage ? AppTheme.pointColor : AppTheme.pointColor.opacity(0.25))
                .frame(width: index == currentPage ? 20 : 6, height: 6)
                .animation(.spring(response: 0.3), value: currentPage)
            }
          }

          // 버튼
          Button(action: handleButton) {
            Text(currentPage < pages.count - 1 ? "다음" : "시작하기")
              .font(.system(size: 17, weight: .semibold))
              .foregroundStyle(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
              .background(AppTheme.pointColor, in: RoundedRectangle(cornerRadius: 16))
          }
          .buttonStyle(ScaleButtonStyle())
          .padding(.horizontal, 32)
        }
        .padding(.bottom, 48)
      }
    }
  }

  private func pageView(_ page: OnboardingPage) -> some View {
    VStack(spacing: 32) {
      Spacer()

      ZStack {
        Circle()
          .fill(AppTheme.pointColor.opacity(0.12))
          .frame(width: 140, height: 140)

        Image(systemName: page.icon)
          .font(.system(size: 60))
          .foregroundStyle(AppTheme.pointColor)
      }

      VStack(spacing: 14) {
        Text(page.title)
          .font(.system(size: 28, weight: .bold, design: .serif))
          .foregroundStyle(.primary)

        Text(page.description)
          .font(.system(size: 16))
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .lineSpacing(4)
      }
      .padding(.horizontal, 40)

      Spacer()
      Spacer()
    }
  }

  private func handleButton() {
    if currentPage < pages.count - 1 {
      withAnimation {
        currentPage += 1
      }
    } else {
      hasSeenOnboarding = true
    }
  }
}

private struct OnboardingPage {
  let icon: String
  let title: String
  let description: String
}

#Preview {
  OnboardingView()
}
