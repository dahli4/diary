import SwiftUI

// MARK: - MainListViewModel

@MainActor
class MainListViewModel: ObservableObject {

  // MARK: - Published

  /// 현재 표시 중인 월
  @Published var currentMonth: Date = Date()

  /// 오늘의 문구
  @Published var dailyQuote: String

  // MARK: - 초기화

  init() {
    self.dailyQuote = QuoteGenerator.randomQuote
  }

  // MARK: - 월 이동

  /// offset만큼 월을 이동한다 (음수: 이전, 양수: 다음)
  func moveMonth(by offset: Int) {
    withAnimation {
      currentMonth = Calendar.current.date(byAdding: .month, value: offset, to: currentMonth) ?? currentMonth
    }
  }

  // MARK: - 문구 갱신

  /// 현재 문구를 제외한 새로운 문구로 교체한다
  func refreshQuote() {
    withAnimation {
      dailyQuote = QuoteGenerator.getNewQuote(current: dailyQuote)
    }
  }
}
