import SwiftUI
import SwiftData
import Combine

// MARK: - TrashListViewModel

@MainActor
class TrashListViewModel: ObservableObject {

  // MARK: - 내부 데이터

  /// View의 @Query에서 주입받는 휴지통 항목 목록 (SwiftData 제약으로 View에서만 @Query 사용 가능)
  private(set) var trashedItems: [Item] = []

  /// SwiftData 작업을 위한 ModelContext (View의 @Environment에서 주입)
  private var modelContext: ModelContext?

  // MARK: - 데이터 업데이트

  /// @Query 결과가 변경될 때 View에서 호출하여 내부 데이터를 갱신한다
  func updateItems(_ items: [Item]) {
    trashedItems = items
  }

  /// ModelContext를 주입한다 (View의 @Environment(\.modelContext)에서 전달)
  func setModelContext(_ context: ModelContext) {
    self.modelContext = context
  }

  // MARK: - 상태

  /// 휴지통이 비어있는지 여부
  var isEmpty: Bool {
    trashedItems.isEmpty
  }

  // MARK: - 액션

  /// 휴지통의 모든 항목을 영구 삭제한다
  func deleteAll() {
    guard let modelContext else { return }
    withAnimation {
      for item in trashedItems {
        modelContext.delete(item)
      }
    }
  }
}
