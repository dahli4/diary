import SwiftUI

// MARK: - SearchViewModel

@MainActor
class SearchViewModel: ObservableObject {

  // MARK: - Published

  /// 검색어
  @Published var searchText: String = ""

  // MARK: - 내부 데이터

  /// View의 @Query에서 주입받는 전체 일기 목록 (SwiftData 제약으로 View에서만 @Query 사용 가능)
  private(set) var allItems: [Item] = []

  // MARK: - 데이터 업데이트

  /// @Query 결과가 변경될 때 View에서 호출하여 내부 데이터를 갱신한다
  func updateItems(_ items: [Item]) {
    allItems = items
  }

  // MARK: - 검색 결과

  /// searchText 기준으로 제목, 내용, 태그, 감정 태그를 필터링한 결과
  var filteredItems: [Item] {
    let query = searchText.trimmingCharacters(in: .whitespaces)
    guard !query.isEmpty else { return [] }
    let lower = query.lowercased()
    return allItems.filter { item in
      (item.title?.lowercased().contains(lower) == true) ||
      (item.content?.lowercased().contains(lower) == true) ||
      item.tags.contains(where: { $0.lowercased().contains(lower) }) ||
      item.emotionTags.contains(where: { $0.lowercased().contains(lower) })
    }
  }

  /// 검색어가 비어있는지 여부 (공백 포함 판단)
  var isSearchEmpty: Bool {
    searchText.trimmingCharacters(in: .whitespaces).isEmpty
  }

  // MARK: - 검색 초기화

  /// 검색어를 초기화한다
  func clearSearch() {
    searchText = ""
  }
}
