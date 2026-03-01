import SwiftUI
import SwiftData

struct SearchView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Query(filter: #Predicate<Item> { !$0.isTrashed },
         sort: \Item.timestamp, order: .reverse)
  private var allItems: [Item]

  // MARK: - ViewModel

  @StateObject private var viewModel = SearchViewModel()

  // MARK: - View 전용 상태

  @State private var editingItem: Item?
  @State private var showEdit = false
  @FocusState private var isSearchFocused: Bool

  var body: some View {
    NavigationStack {
      ZStack {
        EmotionalBackgroundView()
          .ignoresSafeArea()

        VStack(spacing: 0) {
          // 검색창
          HStack(spacing: 12) {
            HStack(spacing: 8) {
              Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 15))
              TextField("제목, 내용, 태그로 검색", text: $viewModel.searchText)
                .focused($isSearchFocused)
                .submitLabel(.search)
              if !viewModel.searchText.isEmpty {
                Button {
                  viewModel.clearSearch()
                } label: {
                  Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 15))
                }
              }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button("취소") {
              dismiss()
            }
            .foregroundStyle(AppTheme.pointColor)
          }
          .padding(.horizontal, 16)
          .padding(.top, 16)
          .padding(.bottom, 12)

          // 결과 목록
          if viewModel.isSearchEmpty {
            emptyPrompt(
              icon: "magnifyingglass",
              message: "검색어를 입력하세요"
            )
          } else if viewModel.filteredItems.isEmpty {
            emptyPrompt(
              icon: "doc.text.magnifyingglass",
              message: "'\(viewModel.searchText)'에 대한 결과가 없어요"
            )
          } else {
            ScrollView {
              LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.filteredItems.enumerated()), id: \.element.id) { index, item in
                  VStack(spacing: 0) {
                    NavigationLink(destination: DiaryDetailView(item: item)) {
                      DiaryCardView(item: item)
                        .contextMenu {
                          Button {
                            editingItem = item
                            showEdit = true
                          } label: {
                            Label("수정", systemImage: "pencil")
                          }
                          Button(role: .destructive) {
                            withAnimation {
                              item.isTrashed = true
                            }
                          } label: {
                            Label("삭제", systemImage: "trash")
                          }
                        }
                    }
                    .frame(height: DiaryCardView.rowHeight)
                    .clipped()
                    .buttonStyle(ScaleButtonStyle())

                    if index < viewModel.filteredItems.count - 1 {
                      Divider()
                        .opacity(0.35)
                        .padding(.leading, 28)
                    }
                  }
                }
              }
              .padding(.horizontal, 16)
              .padding(.bottom, 40)
            }
          }
        }
      }
      .navigationBarHidden(true)
      .fullScreenCover(isPresented: $showEdit) {
        if let editingItem {
          NavigationStack {
            DiaryEditorView(item: editingItem)
          }
        }
      }
    }
    .onAppear {
      isSearchFocused = true
      viewModel.updateItems(allItems)
    }
    .onChange(of: allItems) { _, newItems in
      // @Query 결과 변경 시 ViewModel 데이터 동기화
      viewModel.updateItems(newItems)
    }
  }

  private func emptyPrompt(icon: String, message: String) -> some View {
    VStack(spacing: 16) {
      Spacer()
      Image(systemName: icon)
        .font(.system(size: 44))
        .foregroundStyle(.secondary.opacity(0.5))
      Text(message)
        .font(.subheadline)
        .foregroundStyle(.secondary)
      Spacer()
    }
  }
}

#Preview {
  SearchView()
    .modelContainer(for: Item.self, inMemory: true)
}
