import SwiftUI

// MARK: - CalendarViewModel

@MainActor
class CalendarViewModel: ObservableObject {

  // MARK: - Published

  /// 현재 선택된 날짜 (날짜 셀 탭/드래그로 변경)
  @Published var selectedDate: Date = Date()

  /// 현재 표시 중인 월 (스와이프/버튼으로만 변경)
  @Published var displayedMonth: Date = Date()

  // MARK: - 내부 데이터

  /// View의 @Query에서 주입받는 전체 일기 목록 (SwiftData 제약으로 View에서만 @Query 사용 가능)
  private(set) var allItems: [Item] = []

  // MARK: - 데이터 업데이트

  /// @Query 결과가 변경될 때 View에서 호출하여 내부 데이터를 갱신한다
  func updateItems(_ items: [Item]) {
    allItems = items
  }

  // MARK: - 월 이동

  /// offset만큼 월을 이동한다 (음수: 이전, 양수: 다음)
  func moveMonth(by offset: Int) {
    withAnimation(.snappy(duration: 0.28, extraBounce: 0.04)) {
      displayedMonth = Calendar.current.date(byAdding: .month, value: offset, to: displayedMonth) ?? displayedMonth
    }
  }

  // MARK: - 오늘로 이동

  /// 선택 날짜와 표시 월을 모두 오늘로 초기화한다
  func goToToday() {
    withAnimation(.snappy(duration: 0.28, extraBounce: 0.04)) {
      selectedDate = Date()
      displayedMonth = Date()
    }
  }

  // MARK: - 날짜 선택

  /// 캘린더 그리드에서 날짜를 선택한다
  func selectDate(_ date: Date) {
    selectedDate = date
  }

  // MARK: - 계산 프로퍼티

  /// isTrashed 제외한 전체 항목
  var activeItems: [Item] {
    allItems.filter { !$0.isTrashed }
  }

  /// displayedMonth에 해당하는 달의 항목
  var monthItems: [Item] {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month], from: displayedMonth)
    guard let startOfMonth = calendar.date(from: components),
          let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return [] }
    return activeItems.filter { $0.timestamp >= startOfMonth && $0.timestamp < nextMonth }
  }

  /// selectedDate에 해당하는 날의 항목 (최신순)
  var selectedDayItems: [Item] {
    let calendar = Calendar.current
    return activeItems
      .filter { calendar.isDate($0.timestamp, inSameDayAs: selectedDate) }
      .sorted { $0.timestamp > $1.timestamp }
  }

  /// selectedDayItems의 주요 감정 (EmotionTagNormalizer 사용, "감정기록" 제외)
  var selectedDayEmotion: String {
    let tags = EmotionTagNormalizer.normalizeAll(
      selectedDayItems.flatMap(\.emotionTags).filter { $0 != "감정기록" }
    )
    let counts = Dictionary(grouping: tags, by: { $0 }).mapValues(\.count)
    return counts.sorted { $0.value > $1.value }.first?.key ?? "-"
  }

  /// monthItems에서 고유 날짜(startOfDay) 수
  var monthlyActiveDays: Int {
    let calendar = Calendar.current
    let days = Set(monthItems.map { calendar.startOfDay(for: $0.timestamp) })
    return days.count
  }

  /// 오늘부터 역방향으로 연속 기록 일수
  var currentStreak: Int {
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

  /// monthItems의 주요 감정 태그
  var mostFrequentEmotion: String {
    let tags = EmotionTagNormalizer.normalizeAll(
      monthItems.flatMap(\.emotionTags).filter { $0 != "감정기록" }
    )
    let counts = Dictionary(grouping: tags, by: { $0 }).mapValues(\.count)
    return counts.sorted { $0.value > $1.value }.first?.key ?? "-"
  }

  /// mostFrequentEmotion에 따른 설명 문구
  var monthlyToneCopy: String {
    switch mostFrequentEmotion {
    case "-", "감정기록":
      return "감정 태그가 더 쌓이면 흐름을 보여줄게요"
    case let v where v.contains("행복") || v.contains("기쁨") || v.contains("설렘"):
      return "밝은 에너지가 자주 등장한 달이에요"
    case let v where v.contains("불안") || v.contains("걱정"):
      return "긴장감이 높았던 달로 보여요"
    case let v where v.contains("분노") || v.contains("짜증"):
      return "스트레스 신호가 자주 포착됐어요"
    case let v where v.contains("슬픔") || v.contains("우울"):
      return "감정 회복이 필요한 흐름이 보여요"
    default:
      return "감정 패턴이 안정적으로 쌓이고 있어요"
    }
  }

  // MARK: - 헬퍼 메서드

  /// date에 해당하는 날의 항목 목록
  func dayEntries(for date: Date) -> [Item] {
    let calendar = Calendar.current
    return activeItems.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
  }

  /// date에 해당하는 날의 감정 색상 (기록 없으면 .clear)
  func markerColor(for date: Date) -> Color {
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
}
