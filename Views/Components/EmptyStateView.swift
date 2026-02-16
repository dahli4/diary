import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.stars")
                .font(.system(size: 50))
                .foregroundStyle(.secondary.opacity(0.5))
                .padding(.bottom, 10)
            Text("아직 기록된 하루가 없어요.")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("오늘 하루를 한번 돌아볼까요?")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(height: 300)
    }
}
