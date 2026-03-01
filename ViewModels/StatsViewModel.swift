import SwiftUI
import Combine

// MARK: - StatsViewModel

@MainActor
class StatsViewModel: ObservableObject {

  // MARK: - Published

  /// 현재 선택된 월 (월 이동 버튼으로 변경)
  @Published var selectedMonth: Date = Date()

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
    withAnimation {
      selectedMonth = Calendar.current.date(byAdding: .month, value: offset, to: selectedMonth) ?? selectedMonth
    }
  }

  // MARK: - 이달 필터링

  /// selectedMonth에 해당하는 달의 삭제되지 않은 일기 목록
  var filteredItems: [Item] {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month], from: selectedMonth)
    guard let startOfMonth = calendar.date(from: components),
          let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
      return []
    }

    return allItems.filter { item in
      !item.isTrashed && item.timestamp >= startOfMonth && item.timestamp < nextMonth
    }
  }

  // MARK: - 기분 데이터

  struct MoodData {
    let mood: String
    let count: Int
  }

  /// 이달 기분 빈도 집계 (내림차순 정렬)
  var moodData: [MoodData] {
    let moods = filteredItems.compactMap { $0.mood }
    let counts = Dictionary(grouping: moods, by: { $0 }).mapValues { $0.count }
    return counts.map { MoodData(mood: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
  }

  /// 이달 가장 자주 나온 기분 이모지
  var mostFrequentMood: String {
    moodData.first?.mood ?? "-"
  }

  // MARK: - 스트릭

  /// 현재 연속 작성 일수
  var currentStreak: Int {
    streakInfo.current
  }

  /// 역대 최고 연속 작성 일수
  var bestStreak: Int {
    streakInfo.best
  }

  /// 전체 날짜 집합을 기준으로 현재/최고 연속 일수를 계산한다
  private var streakInfo: (current: Int, best: Int) {
    let calendar = Calendar.current

    // isTrashed 제외 후 날짜(day) 집합 추출
    let uniqueDays = Set(
      allItems
        .filter { !$0.isTrashed }
        .map { calendar.startOfDay(for: $0.timestamp) }
    ).sorted(by: >)

    guard !uniqueDays.isEmpty else { return (0, 0) }

    var bestStreak = 1
    var currentStreak = 0

    let today = calendar.startOfDay(for: Date())
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

    // 현재 스트릭: 오늘 또는 어제부터 역으로 연속 체크
    if uniqueDays.first == today || uniqueDays.first == yesterday {
      currentStreak = 1
      var prev = uniqueDays.first!
      for day in uniqueDays.dropFirst() {
        let diff = calendar.dateComponents([.day], from: day, to: prev).day ?? 0
        if diff == 1 {
          currentStreak += 1
          prev = day
        } else {
          break
        }
      }
    }

    // 최고 스트릭: 전체 날짜 배열에서 최장 연속 구간 계산
    var tempStreak = 1
    var prev = uniqueDays.first!
    for day in uniqueDays.dropFirst() {
      let diff = calendar.dateComponents([.day], from: day, to: prev).day ?? 0
      if diff == 1 {
        tempStreak += 1
        bestStreak = max(bestStreak, tempStreak)
      } else {
        tempStreak = 1
      }
      prev = day
    }

    return (currentStreak, bestStreak)
  }

  // MARK: - 요일별 패턴

  struct DayCount: Identifiable {
    let id = UUID()
    let label: String   // 한국 요일 표기
    let count: Int
    let weekday: Int    // 정렬용 (Calendar.weekday 기준)
  }

  /// Calendar.weekday: 1=일, 2=월, ..., 7=토
  /// 한국 표시 순서: 월(2)→일(1) 으로 재매핑 후 정렬
  private let koreanDayLabels: [Int: String] = [
    1: "일", 2: "월", 3: "화", 4: "수", 5: "목", 6: "금", 7: "토"
  ]

  /// 월요일을 1번으로 재매핑 (일요일은 7)
  private func daySortOrder(for weekday: Int) -> Int {
    weekday == 1 ? 7 : weekday - 1
  }

  /// 전체 데이터 기준 요일별 작성 횟수 (기록 없는 요일도 0으로 포함, 항상 7개)
  var dayCounts: [DayCount] {
    let calendar = Calendar.current
    let validItems = allItems.filter { !$0.isTrashed }

    var counts = [Int: Int]()
    for item in validItems {
      let weekday = calendar.component(.weekday, from: item.timestamp)
      counts[weekday, default: 0] += 1
    }

    return (1...7).map { weekday in
      DayCount(
        label: koreanDayLabels[weekday] ?? "",
        count: counts[weekday] ?? 0,
        weekday: weekday
      )
    }
    .sorted { daySortOrder(for: $0.weekday) < daySortOrder(for: $1.weekday) }
  }

  /// 요일 중 최대 작성 횟수 (차트 스케일 기준)
  var maxDayCount: Int {
    dayCounts.map(\.count).max() ?? 1
  }

  // MARK: - 시간대 분포

  struct TimeSlot: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let color: Color
    let order: Int
  }

  /// 시간대 분류: 아침(6-11), 낮(12-17), 저녁(18-22), 밤(그 외)
  private func timeSlotLabel(for hour: Int) -> String {
    switch hour {
    case 6...11:  return "아침"
    case 12...17: return "낮"
    case 18...22: return "저녁"
    default:      return "밤"
    }
  }

  private let timeSlotColors: [String: Color] = [
    "아침": Color(red: 1.0,  green: 0.78, blue: 0.3),  // 따뜻한 노랑
    "낮":   Color(red: 0.3,  green: 0.78, blue: 0.5),  // 초록
    "저녁": Color(red: 0.95, green: 0.5,  blue: 0.3),  // 주황
    "밤":   Color(red: 0.4,  green: 0.4,  blue: 0.8)   // 보라
  ]

  private let timeSlotOrder: [String: Int] = ["아침": 1, "낮": 2, "저녁": 3, "밤": 4]

  /// 전체 데이터 기준 시간대별 작성 횟수 (순서 정렬)
  var timeSlots: [TimeSlot] {
    let calendar = Calendar.current
    let validItems = allItems.filter { !$0.isTrashed }

    var counts = ["아침": 0, "낮": 0, "저녁": 0, "밤": 0]
    for item in validItems {
      let hour = calendar.component(.hour, from: item.timestamp)
      let label = timeSlotLabel(for: hour)
      counts[label, default: 0] += 1
    }

    return counts.map { label, count in
      TimeSlot(
        label: label,
        count: count,
        color: timeSlotColors[label] ?? .gray,
        order: timeSlotOrder[label] ?? 99
      )
    }
    .sorted { $0.order < $1.order }
  }

  // MARK: - 감정 태그 Top 5

  struct TagEntry: Identifiable {
    let id = UUID()
    let tag: String
    let count: Int
  }

  /// 이달 일기 기준 감정 태그 빈도 Top 5 ("감정기록" 제외, 정규화 적용)
  var topEmotionTags: [TagEntry] {
    let allTags = filteredItems
      .flatMap { $0.emotionTags }
      .filter { $0 != "감정기록" }

    let normalized = EmotionTagNormalizer.normalizeAll(allTags)
    let counts = Dictionary(grouping: normalized, by: { $0 }).mapValues(\.count)

    return counts
      .map { TagEntry(tag: $0.key, count: $0.value) }
      .sorted { $0.count > $1.count }
      .prefix(5)
      .map { $0 }
  }

  /// 감정 태그 최대 출현 횟수 (프로그레스 바 기준)
  var maxTagCount: Int {
    topEmotionTags.map(\.count).max() ?? 1
  }

  // MARK: - 월별 추이

  struct MonthCount: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let sortKey: Date
  }

  /// selectedMonth 기준 최근 6개월 월별 기록 횟수
  var monthCounts: [MonthCount] {
    let calendar = Calendar.current
    let comps = calendar.dateComponents([.year, .month], from: selectedMonth)
    guard let baseMonth = calendar.date(from: comps) else { return [] }

    return (0..<6).compactMap { offset -> MonthCount? in
      guard let month = calendar.date(byAdding: .month, value: offset - 5, to: baseMonth),
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: month) else { return nil }

      let count = allItems.filter {
        !$0.isTrashed && $0.timestamp >= month && $0.timestamp < nextMonth
      }.count

      let monthNum = calendar.component(.month, from: month)
      let label = "\(monthNum)월"
      return MonthCount(label: label, count: count, sortKey: month)
    }
  }

  // MARK: - 상세 수치

  /// 이달 일기 본문 평균 글자 수
  var averageCharCount: Int {
    let counts = filteredItems.compactMap { $0.content?.count }.filter { $0 > 0 }
    guard !counts.isEmpty else { return 0 }
    return counts.reduce(0, +) / counts.count
  }

  /// 삭제되지 않은 전체 누적 기록 수
  var totalItemCount: Int {
    allItems.filter { !$0.isTrashed }.count
  }

  /// 최근 7일 감정 태그 Top 3를 쉼표로 연결한 문자열
  var weeklyEmotionPattern: String {
    let calendar = Calendar.current
    guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return "-" }

    let recentTags = allItems
      .filter { !$0.isTrashed && $0.timestamp >= weekAgo }
      .flatMap(\.emotionTags)
      .filter { $0 != "감정기록" }
    let normalizedTags = EmotionTagNormalizer.normalizeAll(recentTags)

    let counts = Dictionary(grouping: normalizedTags, by: { $0 }).mapValues(\.count)
    let topTags = counts.sorted { $0.value > $1.value }.prefix(3).map(\.key)
    return topTags.isEmpty ? "-" : topTags.joined(separator: ", ")
  }
}
