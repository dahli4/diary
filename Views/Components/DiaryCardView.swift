import SwiftUI
import SwiftData

struct DiaryCardView: View {
  static let rowHeight: CGFloat = 120
  let item: Item
  
  var body: some View {
    HStack(alignment: .center, spacing: 18) {
      timelineColumn

      VStack(alignment: .leading, spacing: 7) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(item.title ?? "무제")
            .font(.system(size: 16, weight: .semibold))
            .lineLimit(1)

          Spacer(minLength: 4)

          if let mood = item.mood {
            Text(mood)
              .font(.system(size: 14))
          }
        }

        HStack(spacing: 8) {
          Text(Calendar.current.isDateInToday(item.timestamp) ? "오늘" : DiaryDateFormatter.monthDay.string(from: item.timestamp))
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)

          if item.weather != nil {
            Image(systemName: "cloud.sun")
              .font(.system(size: 11, weight: .medium))
              .foregroundStyle(.secondary)
          }
        }

        if let reflectionPrompt = item.reflectionPrompt, !reflectionPrompt.isEmpty {
          Text("Q. \(reflectionPrompt)")
            .font(.system(size: 11))
            .foregroundStyle(.secondary.opacity(0.75))
            .lineLimit(1)
        }

        let emotionChips = MoodEmotionMapper.tags(for: item.mood)
        if !emotionChips.isEmpty {
          HStack(spacing: 6) {
            Image(systemName: "waveform.path.ecg")
              .font(.system(size: 10))
              .foregroundStyle(.secondary.opacity(0.8))
            ForEach(emotionChips, id: \.self) { tag in
              Text(tag)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.18), in: Capsule())
            }
          }
        }

        if let firstTag = item.tags.first {
          HStack(spacing: 6) {
            Image(systemName: "tag")
              .font(.system(size: 10))
              .foregroundStyle(.secondary.opacity(0.8))
            Text("#\(firstTag)")
              .font(.system(size: 10, weight: .medium))
              .padding(.horizontal, 7)
              .padding(.vertical, 3)
              .background(Color.primary.opacity(0.08), in: Capsule())
          }
        }
      }
      .padding(.vertical, 8)

      Spacer(minLength: 0)
    }
    .frame(height: DiaryCardView.rowHeight)
    .contentShape(Rectangle())
  }

  private var timelineColumn: some View {
    ZStack {
      Circle()
        .fill(Calendar.current.isDateInToday(item.timestamp) ? AppTheme.pointColor : AppTheme.pointColor.opacity(0.78))
        .frame(width: 8, height: 8)
    }
    .frame(width: 12)
  }
}


#Preview {
  // 프리뷰용 더미 아이템
  let item = Item(timestamp: Date(), isTrashed: false)
  item.title = "Liquid Glass Test"
  item.content = "Looking at the glass effect."
  item.tags = ["Glass", "UI", "Design"]
  item.mood = "😊"
  return DiaryCardView(item: item)
}
