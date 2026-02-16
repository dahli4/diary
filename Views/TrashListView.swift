import SwiftUI
import SwiftData

struct TrashListView: View {
  @Query(filter: #Predicate<Item> { $0.isTrashed == true }, sort: \Item.timestamp, order: .reverse) private var trashedItems: [Item]
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    ZStack {
      // 1. 배경
      EmotionalBackgroundView()
      
      // 2. 내용
      if trashedItems.isEmpty {
        emptyView
      } else {
        trashList
      }
    }
    .navigationTitle("휴지통")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        if !trashedItems.isEmpty {
          Button("모두 비우기", role: .destructive) {
            deleteAll()
          }
          .tint(.red)
        }
      }
    }
  }
  
  private var emptyView: some View {
    VStack(spacing: 16) {
      Image(systemName: "trash")
        .font(.system(size: 48))
        .foregroundStyle(.secondary.opacity(0.5))
      Text("휴지통이 비어있습니다")
        .font(.title3)
        .foregroundStyle(.secondary)
    }
  }
  
  private var trashList: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        ForEach(trashedItems) { item in
          TrashItemRow(item: item) {
            withAnimation {
              item.isTrashed = false
            }
          } deleteAction: {
            withAnimation {
              modelContext.delete(item)
            }
          }
        }
      }
      .padding(.vertical)
      .padding(.bottom, 60)
    }
  }
  
  private func deleteAll() {
    withAnimation {
      for item in trashedItems {
        modelContext.delete(item)
      }
    }
  }
}

struct TrashItemRow: View {
  let item: Item
  let restoreAction: () -> Void
  let deleteAction: () -> Void
  
  var body: some View {
    HStack(spacing: 0) {
      // 왼쪽: 정보
      VStack(alignment: .leading, spacing: 6) {
        Text(item.title ?? "무제")
          .font(.headline)
          .foregroundStyle(.primary)
          .lineLimit(1)
        
        Text(item.timestamp, format: .dateTime.year().month().day())
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(.leading, 16)
      .padding(.vertical, 16)
      
      Spacer()
      
      // 오른쪽: 액션
      HStack(spacing: 0) {
        // 복구
        Button(action: restoreAction) {
          Image(systemName: "arrow.uturn.backward")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.blue)
            .frame(width: 44, height: 60)
            .contentShape(Rectangle())
        }
        
        Divider()
          .frame(height: 30)
        
        // 영구 삭제
        Button(role: .destructive, action: deleteAction) {
          Image(systemName: "xmark")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.red)
            .frame(width: 44, height: 60)
            .contentShape(Rectangle())
        }
      }
      .frame(height: 60)
      .padding(.trailing, 8)
    }
    .liquidGlass(in: RoundedRectangle(cornerRadius: 16))
    .padding(.horizontal)
  }
}
