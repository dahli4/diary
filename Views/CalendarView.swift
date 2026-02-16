import SwiftUI
import SwiftData

struct CalendarView: View {
  @Query(filter: #Predicate<Item> { $0.isTrashed == false }, sort: \Item.timestamp, order: .reverse) private var items: [Item]
  @State private var selectedDate: Date = Date()
  private let selectionAnimation: Animation = .snappy(duration: 0.28, extraBounce: 0.04)
  
  var body: some View {
    ZStack {
      EmotionalBackgroundView()
        .ignoresSafeArea()

      ScrollView(showsIndicators: false) {
        VStack(spacing: 14) {
          CalendarHeader(selectedDate: $selectedDate)
            .padding(.top, 8)

          CalendarGrid(items: activeItems, selectedDate: $selectedDate)

          SelectedDayCard(
            date: selectedDate,
            entries: selectedDayItems,
            primaryEmotion: selectedDayEmotion
          )
          .animation(selectionAnimation, value: selectedDate)

          VStack(spacing: 10) {
            HStack(spacing: 10) {
              CalendarMetricCard(
                title: "연속 기록",
                value: "\(currentStreak)일",
                subtitle: "오늘까지 이어진 기록",
                systemImage: "flame.fill"
              )
              CalendarMetricCard(
                title: "이번 달 기록일",
                value: "\(monthlyActiveDays)일",
                subtitle: "총 \(monthItems.count)개 작성",
                systemImage: "calendar.badge.clock"
              )
            }
            CalendarMetricCard(
              title: "이번 달 감정 톤",
              value: mostFrequentEmotion,
              subtitle: monthlyToneCopy,
              systemImage: "sparkles"
            )
          }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 110)
      }
    }
  }
  
  private var activeItems: [Item] {
    items.filter { !$0.isTrashed }
  }

  private var monthItems: [Item] {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month], from: selectedDate)
    guard let startOfMonth = calendar.date(from: components),
          let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return [] }
    return activeItems.filter { $0.timestamp >= startOfMonth && $0.timestamp < nextMonth }
  }

  private var selectedDayItems: [Item] {
    let calendar = Calendar.current
    return activeItems
      .filter { calendar.isDate($0.timestamp, inSameDayAs: selectedDate) }
      .sorted { $0.timestamp > $1.timestamp }
  }

  private var selectedDayEmotion: String {
    let tags = EmotionTagNormalizer.normalizeAll(
      selectedDayItems.flatMap(\.emotionTags).filter { $0 != "감정기록" }
    )
    let counts = Dictionary(grouping: tags, by: { $0 }).mapValues(\.count)
    return counts.sorted { $0.value > $1.value }.first?.key ?? "-"
  }

  private var monthlyActiveDays: Int {
    let calendar = Calendar.current
    let days = Set(monthItems.map { calendar.startOfDay(for: $0.timestamp) })
    return days.count
  }

  private var currentStreak: Int {
    let calendar = Calendar.current
    let daySet = Set(activeItems.map { calendar.startOfDay(for: $0.timestamp) })
    var streak = 0
    var cursor = calendar.startOfDay(for: Date())

    while daySet.contains(cursor) {
      streak += 1
      guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
      cursor = previousDay
    }

    return streak
  }
  
  private var mostFrequentEmotion: String {
    let tags = EmotionTagNormalizer.normalizeAll(
      monthItems.flatMap(\.emotionTags).filter { $0 != "감정기록" }
    )
    let counts = Dictionary(grouping: tags, by: { $0 }).mapValues(\.count)
    return counts.sorted { $0.value > $1.value }.first?.key ?? "-"
  }

  private var monthlyToneCopy: String {
    switch mostFrequentEmotion {
    case "-", "감정기록":
      return "감정 태그가 더 쌓이면 흐름을 보여줄게요"
    case let value where value.contains("행복") || value.contains("기쁨") || value.contains("설렘"):
      return "밝은 에너지가 자주 등장한 달이에요"
    case let value where value.contains("불안") || value.contains("걱정"):
      return "긴장감이 높았던 달로 보여요"
    case let value where value.contains("분노") || value.contains("짜증"):
      return "스트레스 신호가 자주 포착됐어요"
    case let value where value.contains("슬픔") || value.contains("우울"):
      return "감정 회복이 필요한 흐름이 보여요"
    default:
      return "감정 패턴이 안정적으로 쌓이고 있어요"
    }
  }
}

private struct CalendarHeader: View {
  @Binding var selectedDate: Date
  private let selectionAnimation: Animation = .snappy(duration: 0.28, extraBounce: 0.04)
  
  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Text("캘린더")
        .font(.system(size: 24, weight: .bold, design: .serif))
        .foregroundStyle(.primary)
      
      Spacer()
      
      HStack(spacing: 8) {
        Button {
          withAnimation(selectionAnimation) {
            selectedDate = Date()
          }
        } label: {
          Text("오늘")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.primary.opacity(0.08), in: Capsule())
        }

        Button {
          withAnimation(selectionAnimation) {
            selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
          }
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.primary.opacity(0.7))
            .padding(8)
            .background(Color.primary.opacity(0.06))
            .clipShape(Circle())
        }
        
        Text(DiaryDateFormatter.yearMonth.string(from: selectedDate))
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.secondary)
        
        Button {
          withAnimation(selectionAnimation) {
            selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
          }
        } label: {
          Image(systemName: "chevron.right")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.primary.opacity(0.7))
            .padding(8)
            .background(Color.primary.opacity(0.06))
            .clipShape(Circle())
        }
      }
    }
  }
}

private struct CalendarGrid: View {
  let items: [Item]
  @Binding var selectedDate: Date
  private let selectionAnimation: Animation = .snappy(duration: 0.28, extraBounce: 0.04)
  
  private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
  private let cellHeight: CGFloat = 46
  
  private var calendar: Calendar {
    var cal = Calendar.current
    cal.firstWeekday = 1
    return cal
  }
  
  private var monthDays: [Date] {
    let comps = calendar.dateComponents([.year, .month], from: selectedDate)
    guard let startOfMonth = calendar.date(from: comps),
          let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return [] }
    return range.compactMap { day in
      calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
    }
  }
  
  private var gridDates: [Date] {
    guard let firstDay = monthDays.first,
          let lastDay = monthDays.last else { return [] }
    let weekdayOffset = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
    let leading = (0..<weekdayOffset).compactMap { i in
      calendar.date(byAdding: .day, value: -(weekdayOffset - i), to: firstDay)
    }
    let trailingCount = (7 - ((weekdayOffset + monthDays.count) % 7)) % 7
    let trailing = (0..<trailingCount).compactMap { i in
      calendar.date(byAdding: .day, value: i + 1, to: lastDay)
    }
    return leading + monthDays + trailing
  }
  
  private func markerColor(for date: Date) -> Color {
    let dayItems = dayEntries(for: date)
    if dayItems.isEmpty { return .clear }
    let tags = EmotionTagNormalizer.normalizeAll(
      dayItems.flatMap(\.emotionTags).filter { $0 != "감정기록" }
    )
    let counts = Dictionary(grouping: tags, by: { $0 }).mapValues(\.count)
    let primary = counts.sorted { $0.value > $1.value }.first?.key ?? ""
    if primary.contains("행복") || primary.contains("기쁨") || primary.contains("설렘") || primary.contains("감사") {
      return Color(red: 0.99, green: 0.78, blue: 0.35)
    }
    if primary.contains("슬픔") || primary.contains("우울") || primary.contains("허무") {
      return Color(red: 0.40, green: 0.62, blue: 0.95)
    }
    if primary.contains("분노") || primary.contains("짜증") || primary.contains("화") {
      return Color(red: 0.96, green: 0.34, blue: 0.32)
    }
    if primary.contains("불안") || primary.contains("걱정") || primary.contains("두려움") {
      return Color(red: 0.30, green: 0.80, blue: 0.78)
    }
    if primary.contains("평온") || primary.contains("차분") || primary.contains("안정") {
      return Color(red: 0.38, green: 0.82, blue: 0.55)
    }
    return Color.accentColor.opacity(0.7)
  }
  
  private func isCurrentMonth(_ date: Date) -> Bool {
    calendar.isDate(date, equalTo: selectedDate, toGranularity: .month)
  }

  private func dayEntries(for date: Date) -> [Item] {
    items.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
  }
  
  var body: some View {
    VStack(spacing: 8) {
      HStack(spacing: 6) {
        ForEach(["일","월","화","수","목","금","토"], id: \.self) { label in
          Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
        }
      }
      
      LazyVGrid(columns: columns, spacing: 6) {
        ForEach(gridDates, id: \.self) { date in
          let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
          let entries = dayEntries(for: date)
          let marker = markerColor(for: date)
          let isInMonth = isCurrentMonth(date)
          let hasEntries = !entries.isEmpty

          VStack(spacing: 7) {
            Text("\(calendar.component(.day, from: date))")
              .font(.system(size: 14, weight: .bold))
              .foregroundStyle(isInMonth ? Color.primary : Color.secondary.opacity(0.4))

            HStack(spacing: 3) {
              Circle()
                .fill(marker)
                .frame(width: 6, height: 6)
                .opacity(hasEntries ? 1 : 0)
              Circle()
                .fill(marker.opacity(0.55))
                .frame(width: 6, height: 6)
                .opacity(entries.count >= 2 ? 1 : 0)
            }
          }
          .frame(maxWidth: .infinity, minHeight: cellHeight)
          .background(
            RoundedRectangle(cornerRadius: 10)
              .fill(isSelected ? Color.primary.opacity(0.09) : Color.clear)
          )
          .overlay(
            RoundedRectangle(cornerRadius: 10)
              .stroke(isSelected ? Color.primary.opacity(0.24) : Color.clear, lineWidth: 1)
          )
          .opacity(isInMonth ? 1 : 0.45)
          .onTapGesture {
            withAnimation(selectionAnimation) {
              selectedDate = date
            }
          }
        }
      }
    }
    .padding(12)
    .liquidGlass(in: RoundedRectangle(cornerRadius: 18))
  }
}

private struct SelectedDayCard: View {
  let date: Date
  let entries: [Item]
  let primaryEmotion: String

  private var dateLabel: String {
    DiaryDateFormatter.fullDate.string(from: date)
  }

  private var topTitles: [String] {
    entries.compactMap { item in
      let title = (item.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      return title.isEmpty ? nil : title
    }
    .prefix(2)
    .map { $0 }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center) {
        Text(dateLabel)
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.secondary)
        Spacer()
        Text("\(entries.count)개 기록")
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(.primary)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(Color.primary.opacity(0.08), in: Capsule())
      }

      if entries.isEmpty {
        Text("선택한 날짜에 작성된 일기가 없어요")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.secondary)
          .contentTransition(.opacity)
      } else {
        HStack(spacing: 8) {
          Text("주요 감정")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
          Text(primaryEmotion)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.primary.opacity(0.08), in: Capsule())
            .contentTransition(.opacity)
        }

        if !topTitles.isEmpty {
          VStack(alignment: .leading, spacing: 4) {
            ForEach(topTitles, id: \.self) { title in
              Text("• \(title)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.9))
                .contentTransition(.opacity)
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .liquidGlass(in: RoundedRectangle(cornerRadius: 14))
  }
}

private struct CalendarMetricCard: View {
  let title: String
  let value: String
  let subtitle: String
  let systemImage: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 7) {
        Image(systemName: systemImage)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.secondary)
        Text(title)
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(.secondary)
      }

      Text(value)
        .font(.system(size: 22, weight: .heavy))
        .foregroundStyle(.primary)

      Text(subtitle)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .liquidGlass(in: RoundedRectangle(cornerRadius: 14))
  }
}

#Preview {
  CalendarView()
}
