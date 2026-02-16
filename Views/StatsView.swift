import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
  @Environment(\.dismiss) private var dismiss
  @Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]
  @State private var selectedMonth = Date()
  @State private var selectedMode: FlowMode = .monthly
  
  private enum FlowMode: String, CaseIterable, Identifiable {
    case monthly = "월간"
    case yearly = "연간"
    case calendar = "달력"
    
    var id: String { rawValue }
  }
  
  var body: some View {
    NavigationStack {
      ZStack {
        EmotionalBackgroundView()
          .opacity(0.35)
        
        ScrollView {
          VStack(spacing: 24) {
            header

            if filteredItems.isEmpty {
              ContentUnavailableView("이 달의 기록이 없어요", systemImage: "waveform.path.ecg")
                .padding(.top, 50)
            } else {
              VStack(alignment: .leading, spacing: 12) {
                Text("이번 달 감정 흐름")
                  .font(.system(size: 14, weight: .semibold))
                  .foregroundStyle(.primary)
                
                Picker("감정 흐름 모드", selection: $selectedMode) {
                  ForEach(FlowMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                  }
                }
                .pickerStyle(.segmented)
                
                Group {
                  switch selectedMode {
                  case .monthly:
                    MonthlyHeatmapView(items: filteredItems, month: selectedMonth)
                  case .yearly:
                    YearlyHeatmapView(items: items, year: selectedMonth)
                  case .calendar:
                    CalendarHeatmapView(items: filteredItems, month: selectedMonth)
                  }
                }
                .liquidGlass(in: RoundedRectangle(cornerRadius: 18))
              }
              
              VStack(spacing: 12) {
                HStack(spacing: 12) {
                  StatCard(title: "기록 횟수", value: "\(filteredItems.count)회", systemImage: "square.and.pencil")
                  StatCard(title: "가장 자주 나온 감정", value: mostFrequentMood, systemImage: "face.smiling")
                }
                StatCard(title: "최근 7일 키워드", value: weeklyEmotionPattern, systemImage: "sparkle.magnifyingglass")
              }
            }
          }
          .padding(.horizontal, 20)
          .padding(.top, 18)
          .padding(.bottom, 40)
        }
      }
      .navigationTitle("감정 흐름")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("닫기") { dismiss() }
        }
      }
    }
  }

  private var header: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Text("감정 흐름")
        .font(.system(size: 26, weight: .bold, design: .serif))
        .foregroundStyle(.primary)

      Spacer()

      HStack(spacing: 8) {
        Button {
          withAnimation {
            selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
          }
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.primary.opacity(0.7))
            .frame(width: 32, height: 32)
            .background(Color.primary.opacity(0.06))
            .clipShape(Circle())
        }

        Text(DiaryDateFormatter.yearMonth.string(from: selectedMonth))
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.secondary)

        Button {
          withAnimation {
            selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
          }
        } label: {
          Image(systemName: "chevron.right")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.primary.opacity(0.7))
            .frame(width: 32, height: 32)
            .background(Color.primary.opacity(0.06))
            .clipShape(Circle())
        }
      }
    }
  }
  
  private var filteredItems: [Item] {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month], from: selectedMonth)
    let startOfMonth = calendar.date(from: components)!
    let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
    
    return items.filter { item in
      !item.isTrashed && item.timestamp >= startOfMonth && item.timestamp < nextMonth
    }
  }
  
  struct MoodData {
    let mood: String
    let count: Int
  }
  
  private var moodData: [MoodData] {
    let moods = filteredItems.compactMap { $0.mood }
    let counts = Dictionary(grouping: moods, by: { $0 }).mapValues { $0.count }
    return counts.map { MoodData(mood: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
  }
  
  private var mostFrequentMood: String {
    return moodData.first?.mood ?? "-"
  }

  private var weeklyEmotionPattern: String {
    let calendar = Calendar.current
    guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return "-" }

    let recentTags = items
      .filter { !$0.isTrashed && $0.timestamp >= weekAgo }
      .flatMap(\.emotionTags)
      .filter { $0 != "감정기록" }

    let counts = Dictionary(grouping: recentTags, by: { $0 }).mapValues(\.count)
    let topTags = counts.sorted { $0.value > $1.value }.prefix(3).map(\.key)
    return topTags.isEmpty ? "-" : topTags.joined(separator: ", ")
  }
}

private struct MonthlyHeatmapView: View {
  let items: [Item]
  let month: Date
  
  private let cellSpacing: CGFloat = 4
  private let labelWidth: CGFloat = 20
  private let cellHeight: CGFloat = 14
  private let columnCount: Int = 5
  
  private var calendar: Calendar {
    var cal = Calendar.current
    cal.firstWeekday = 1
    return cal
  }
  
  private var monthDays: [Date] {
    let comps = calendar.dateComponents([.year, .month], from: month)
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
    let maxCells = columnCount * 7
    let trailingCount = max(0, maxCells - (weekdayOffset + monthDays.count))
    let trailing = (0..<trailingCount).compactMap { i in
      calendar.date(byAdding: .day, value: i + 1, to: lastDay)
    }
    let combined = leading + monthDays + trailing
    return Array(combined.prefix(maxCells))
  }
  
  private func color(for date: Date) -> Color {
    let dayItems = items.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    if dayItems.isEmpty { return Color.primary.opacity(0.06) }
    let tags = dayItems.flatMap(\.emotionTags).filter { $0 != "감정기록" }
    let primary = tags.first ?? ""
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
    return Color.accentColor.opacity(0.55)
  }
  
  private func labelForRow(_ row: Int) -> String {
    switch row {
    case 0: return "일"
    case 1: return "월"
    case 2: return "화"
    case 3: return "수"
    case 4: return "목"
    case 5: return "금"
    case 6: return "토"
    default: return ""
    }
  }
  
  var body: some View {
    HStack(alignment: .top, spacing: cellSpacing) {
      VStack(spacing: cellSpacing) {
        ForEach(0..<7, id: \.self) { row in
          Text(labelForRow(row))
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(width: labelWidth, height: cellHeight)
        }
      }
      
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: cellSpacing), count: columnCount), spacing: cellSpacing) {
        ForEach(0..<gridDates.count, id: \.self) { index in
          let date = gridDates[index]
          RoundedRectangle(cornerRadius: 2)
            .fill(color(for: date))
            .frame(height: cellHeight)
        }
      }
    }
    .padding(8)
  }
}

private struct YearlyHeatmapView: View {
  let items: [Item]
  let year: Date
  
  private let cellSpacing: CGFloat = 3
  private let labelWidth: CGFloat = 20
  
  private var calendar: Calendar {
    var cal = Calendar.current
    cal.firstWeekday = 2
    return cal
  }
  
  private var rangeDays: [Date] {
    let monthComponents = calendar.dateComponents([.year, .month], from: year)
    guard let centerMonth = calendar.date(from: monthComponents),
          let start = calendar.date(byAdding: .month, value: -1, to: centerMonth),
          let endBase = calendar.date(byAdding: .month, value: 2, to: centerMonth),
          let end = calendar.date(byAdding: .day, value: -1, to: endBase) else { return [] }
    let dayCount = calendar.dateComponents([.day], from: start, to: end).day ?? 0
    return stride(from: 0, through: dayCount, by: 1).compactMap {
      calendar.date(byAdding: .day, value: $0, to: start)
    }
  }
  
  private var gridDates: [Date] {
    guard let firstDay = rangeDays.first,
          let lastDay = rangeDays.last else { return [] }
    let weekdayOffset = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
    let leading = (0..<weekdayOffset).compactMap { i in
      calendar.date(byAdding: .day, value: -(weekdayOffset - i), to: firstDay)
    }
    let trailingCount = (7 - ((weekdayOffset + rangeDays.count) % 7)) % 7
    let trailing = (0..<trailingCount).compactMap { i in
      calendar.date(byAdding: .day, value: i + 1, to: lastDay)
    }
    return leading + rangeDays + trailing
  }
  
  private var columnCount: Int {
    max(gridDates.count / 7, 1)
  }
  
  private func color(for date: Date) -> Color {
    let dayItems = items.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    if dayItems.isEmpty { return Color.primary.opacity(0.06) }
    return Color.accentColor.opacity(0.6)
  }
  
  private func labelForRow(_ row: Int) -> String {
    switch row {
    case 0: return "월"
    case 2: return "수"
    case 4: return "금"
    default: return ""
    }
  }
  
  var body: some View {
    HStack(alignment: .top, spacing: cellSpacing) {
      VStack(spacing: cellSpacing) {
        ForEach(0..<7, id: \.self) { row in
          Text(labelForRow(row))
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(width: labelWidth, height: 10)
        }
      }
      
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: cellSpacing), count: columnCount), spacing: cellSpacing) {
        ForEach(0..<gridDates.count, id: \.self) { index in
          let date = gridDates[index]
          RoundedRectangle(cornerRadius: 2)
            .fill(color(for: date))
            .frame(height: 10)
        }
      }
    }
    .padding(10)
    .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
  }
}

private struct CalendarHeatmapView: View {
  let items: [Item]
  let month: Date
  
  private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
  
  private var monthDays: [Date] {
    let calendar = Calendar.current
    let comps = calendar.dateComponents([.year, .month], from: month)
    guard let startOfMonth = calendar.date(from: comps),
          let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return [] }
    return range.compactMap { day in
      calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
    }
  }
  
  private func color(for date: Date) -> Color {
    let calendar = Calendar.current
    let dayItems = items.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    if dayItems.isEmpty { return Color.primary.opacity(0.06) }
    return Color.accentColor.opacity(0.6)
  }
  
  var body: some View {
    LazyVGrid(columns: columns, spacing: 6) {
      ForEach(monthDays, id: \.self) { date in
        RoundedRectangle(cornerRadius: 4)
          .fill(color(for: date))
          .frame(height: 18)
      }
    }
    .padding(12)
  }
}

struct StatCard: View {
  let title: String
  let value: String
  let systemImage: String
  
  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 10) {
      Image(systemName: systemImage)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.secondary)
        .frame(width: 18)
      
      VStack(alignment: .leading, spacing: 6) {
        Text(title)
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(.secondary)
        Text(value)
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(.primary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .liquidGlass(in: RoundedRectangle(cornerRadius: 14))
  }
}
