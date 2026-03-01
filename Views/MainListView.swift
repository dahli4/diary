import SwiftUI
import SwiftData

struct MainListView: View {
  @Environment(\.modelContext) private var modelContext

  // MARK: - ViewModel

  /// 월 이동 및 오늘의 문구 상태를 관리하는 ViewModel
  @StateObject private var viewModel = MainListViewModel()

  // MARK: - View 전용 상태

  @State private var showEditor = false
  @State private var editingItem: Item?
  @State private var showEdit = false
  @State private var initialPromptForNewEntry: String?
  @State private var showSearch = false

  // MARK: - 바인딩

  @Binding var openComposerToken: Int
  @Binding var reminderPrompt: String?

  // MARK: - 스와이프 상태

  /// 스와이프 진행 중 여부 — 일기 카드 NavigationLink 충돌 방지
  @GestureState private var isSwiping = false

  // MARK: - 제스처

  /// 월 전환 스와이프 — 전체 화면 어디서든 수평으로 밀면 월 이동
  private var monthSwipeGesture: some Gesture {
    DragGesture(minimumDistance: 60)
      .updating($isSwiping) { _, state, _ in state = true }
      .onEnded { value in
        let h = value.translation.width
        let v = abs(value.translation.height)
        guard abs(h) > v * 1.8 else { return }
        viewModel.moveMonth(by: h < 0 ? 1 : -1)
      }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        // 배경: 감정 그라디언트
        EmotionalBackgroundView()

        ScrollView {
          VStack(spacing: 24) {
            HStack(alignment: .center) {
              Text(DiaryDateFormatter.yearMonth.string(from: viewModel.currentMonth))
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(.primary)

              Spacer()

              HStack(spacing: 8) {
                Button {
                  viewModel.moveMonth(by: -1)
                } label: {
                  Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
                }
                .accessibilityLabel("이전 달")

                Button {
                  viewModel.moveMonth(by: 1)
                } label: {
                  Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
                }
                .accessibilityLabel("다음 달")

                Divider()
                  .frame(height: 20)
                  .padding(.horizontal, 4)

                Button(action: { showSearch = true }) {
                  Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Circle())
                }
                .accessibilityLabel("검색")

                Button(action: {
                  initialPromptForNewEntry = nil
                  showEditor = true
                }) {
                  Image(systemName: "square.and.pencil")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Circle())
                }
                .accessibilityLabel("새 일기 작성")
              }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            VStack(spacing: 8) {
              Text(viewModel.dailyQuote)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(height: 32)
                .padding(.horizontal)
                .id(viewModel.dailyQuote)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .accessibilityHint("탭하면 새 문구로 바꿉니다")
            }
            .padding(.top, 2)
            .onTapGesture {
              viewModel.refreshQuote()
            }

            // 스와이프 중에는 목록 비활성화 → NavigationLink 충돌 방지
            DiaryFilteredList(month: viewModel.currentMonth, editingItem: $editingItem, showEdit: $showEdit)
              .padding(.horizontal, 16)
              .padding(.bottom, 40)
              .disabled(isSwiping)
          }
        }
      }
      .simultaneousGesture(monthSwipeGesture)
      .navigationBarHidden(true)
      .fullScreenCover(isPresented: $showSearch) {
        SearchView()
      }
      .fullScreenCover(isPresented: $showEditor) {
        NavigationStack {
          DiaryEditorView(item: nil, initialPrompt: initialPromptForNewEntry)
        }
      }
      .fullScreenCover(isPresented: $showEdit) {
        if let editingItem {
          NavigationStack {
            DiaryEditorView(item: editingItem)
          }
        }
      }
      .onChange(of: openComposerToken) { _, _ in
        initialPromptForNewEntry = reminderPrompt
        showEditor = true
        reminderPrompt = nil
      }
      .onAppear {
        if let prompt = reminderPrompt {
          initialPromptForNewEntry = prompt
          showEditor = true
          reminderPrompt = nil
        }
      }
    }
  }
}

struct DiaryFilteredList: View {
  @Query private var items: [Item]
  @Binding var editingItem: Item?
  @Binding var showEdit: Bool

  init(month: Date, editingItem: Binding<Item?>, showEdit: Binding<Bool>) {
    _editingItem = editingItem
    _showEdit = showEdit
    let calendar = Calendar.current
    let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
    let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

    let predicate = #Predicate<Item> { item in
      item.isTrashed == false &&
      item.timestamp >= startOfMonth &&
      item.timestamp < nextMonth
    }
    _items = Query(filter: predicate, sort: \Item.timestamp, order: .reverse)
  }

  var body: some View {
    if items.isEmpty {
      EmptyStateView()
        .padding(.top, 40)
    } else {
      ZStack(alignment: .leading) {
        GeometryReader { proxy in
          Rectangle()
            .fill(AppTheme.pointColor.opacity(0.42))
            .frame(width: 1, height: proxy.size.height)
            .offset(x: 6)
            .allowsHitTesting(false)
        }

        LazyVStack(spacing: 0) {
          ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
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

              if index < items.count - 1 {
                Divider()
                  .opacity(0.35)
                  .padding(.leading, 28)
              }
            }
          }
        }
      }
    }
  }
}
