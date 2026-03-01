import SwiftUI
import SwiftData

struct CalendarView: View {
  @Query(filter: #Predicate<Item> { $0.isTrashed == false }, sort: \Item.timestamp, order: .reverse) private var items: [Item]
  @StateObject private var viewModel = CalendarViewModel()
  private let selectionAnimation: Animation = .snappy(duration: 0.28, extraBounce: 0.04)

  // 월 전환 스와이프 — 날짜 선택 드래그와 구분하기 위해 최소 이동 거리 및 수평 비율 조건 사용
  private var monthSwipeGesture: some Gesture {
    DragGesture(minimumDistance: 60)
      .onEnded { value in
        let h = value.translation.width
        let v = abs(value.translation.height)
        guard abs(h) > v * 1.8 else { return }
        viewModel.moveMonth(by: h < 0 ? 1 : -1)
      }
  }

  var body: some View {
    ZStack {
      EmotionalBackgroundView()
        .ignoresSafeArea()

      ScrollView(showsIndicators: false) {
        VStack(spacing: 14) {
          CalendarHeader(viewModel: viewModel)
            .padding(.top, 8)

          CalendarGrid(viewModel: viewModel)

          SelectedDayCard(
            date: viewModel.selectedDate,
            entries: viewModel.selectedDayItems,
            primaryEmotion: viewModel.selectedDayEmotion
          )
          .animation(selectionAnimation, value: viewModel.selectedDate)

          VStack(spacing: 10) {
            HStack(spacing: 10) {
              CalendarMetricCard(
                title: "연속 기록",
                value: "\(viewModel.currentStreak)일",
                subtitle: "오늘까지 이어진 기록",
                systemImage: "flame.fill"
              )
              CalendarMetricCard(
                title: "이번 달 기록일",
                value: "\(viewModel.monthlyActiveDays)일",
                subtitle: "총 \(viewModel.monthItems.count)개 작성",
                systemImage: "calendar.badge.clock"
              )
            }
            CalendarMetricCard(
              title: "이번 달 감정 톤",
              value: viewModel.mostFrequentEmotion,
              subtitle: viewModel.monthlyToneCopy,
              systemImage: "sparkles"
            )
          }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 110)
      }
    }
    .simultaneousGesture(monthSwipeGesture)
    .onAppear { viewModel.updateItems(items) }
    .onChange(of: items) { _, newItems in viewModel.updateItems(newItems) }
  }
}

private struct CalendarHeader: View {
  @ObservedObject var viewModel: CalendarViewModel

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Text("캘린더")
        .font(.system(size: 24, weight: .bold, design: .serif))
        .foregroundStyle(.primary)

      Spacer()

      HStack(spacing: 8) {
        Button {
          viewModel.goToToday()
        } label: {
          Text("오늘")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(AppTheme.pointColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppTheme.pointColor.opacity(0.12), in: Capsule())
        }

        Button {
          viewModel.moveMonth(by: -1)
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(AppTheme.pointColor.opacity(0.82))
            .padding(8)
            .background(AppTheme.pointColor.opacity(0.10))
            .clipShape(Circle())
        }

        Text(DiaryDateFormatter.yearMonth.string(from: viewModel.displayedMonth))
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.secondary)

        Button {
          viewModel.moveMonth(by: 1)
        } label: {
          Image(systemName: "chevron.right")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(AppTheme.pointColor.opacity(0.82))
            .padding(8)
            .background(AppTheme.pointColor.opacity(0.10))
            .clipShape(Circle())
        }
      }
    }
  }
}

private struct CalendarGrid: View {
  @ObservedObject var viewModel: CalendarViewModel
  private let selectionAnimation: Animation = .snappy(duration: 0.28, extraBounce: 0.04)
  @State private var gridSize: CGSize = .zero
  @State private var lastDragDate: Date?

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
  private let cellHeight: CGFloat = 46

  private var calendar: Calendar {
    var cal = Calendar.current
    cal.firstWeekday = 1
    return cal
  }

  private var monthDays: [Date] {
    let comps = calendar.dateComponents([.year, .month], from: viewModel.displayedMonth)
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
    // 항상 6주(42칸) 고정 — 5주/6주 여부에 따라 높이가 바뀌지 않도록
    let trailingCount = 42 - leading.count - monthDays.count
    let trailing = (0..<trailingCount).compactMap { i in
      calendar.date(byAdding: .day, value: i + 1, to: lastDay)
    }
    return leading + monthDays + trailing
  }

  private func isCurrentMonth(_ date: Date) -> Bool {
    calendar.isDate(date, equalTo: viewModel.displayedMonth, toGranularity: .month)
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
          let isSelected = calendar.isDate(date, inSameDayAs: viewModel.selectedDate)
          let entries = viewModel.dayEntries(for: date)
          let marker = viewModel.markerColor(for: date)
          let isInMonth = isCurrentMonth(date)
          let hasEntries = !entries.isEmpty

          VStack(spacing: 7) {
            Text("\(calendar.component(.day, from: date))")
              .font(.system(size: 14, weight: .bold))
              .foregroundStyle(isInMonth ? Color.primary : Color.secondary.opacity(0.4))
              .frame(width: 28, height: 28)
              .background(
                Circle()
                  .fill(isSelected ? AppTheme.pointColor.opacity(0.14) : Color.clear)
              )
              .overlay(
                Circle()
                  .stroke(isSelected ? AppTheme.pointColor.opacity(0.42) : Color.clear, lineWidth: 1.2)
              )

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
          .scaleEffect(isSelected ? 1.02 : 1.0)
          .shadow(color: isSelected ? AppTheme.pointColor.opacity(0.18) : .clear, radius: 6, y: 2)
          .opacity(isInMonth ? 1 : 0.45)
          .onTapGesture {
            withAnimation(selectionAnimation) {
              viewModel.selectDate(date)
            }
          }
        }
      }
      .animation(.interactiveSpring(response: 0.22, dampingFraction: 0.86), value: viewModel.selectedDate)
      .background(
        GeometryReader { proxy in
          Color.clear
            .onAppear { gridSize = proxy.size }
            .onChange(of: proxy.size) { _, newSize in
              gridSize = newSize
            }
        }
      )
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            guard let date = dateAt(location: value.location, in: gridSize) else { return }
            if let lastDragDate, calendar.isDate(lastDragDate, inSameDayAs: date) {
              return
            }
            lastDragDate = date
            withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.86)) {
              viewModel.selectDate(date)
            }
          }
          .onEnded { _ in
            lastDragDate = nil
          }
      )
    }
    .padding(12)
    .liquidGlass(in: RoundedRectangle(cornerRadius: 18))
  }

  private func dateAt(location: CGPoint, in size: CGSize) -> Date? {
    guard size.width > 0, size.height > 0 else { return nil }

    let horizontalSpacing: CGFloat = 6
    let verticalSpacing: CGFloat = 6
    let columnCount = 7
    let cellWidth = (size.width - (CGFloat(columnCount - 1) * horizontalSpacing)) / CGFloat(columnCount)
    let stepX = cellWidth + horizontalSpacing
    let stepY = cellHeight + verticalSpacing

    let col = Int((location.x / stepX).rounded(.down))
    let row = Int((location.y / stepY).rounded(.down))

    guard col >= 0, col < columnCount, row >= 0 else { return nil }
    let index = row * columnCount + col
    guard gridDates.indices.contains(index) else { return nil }
    return gridDates[index]
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
          .foregroundStyle(AppTheme.pointColor)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(AppTheme.pointColor.opacity(0.12), in: Capsule())
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
            .foregroundStyle(AppTheme.pointColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppTheme.pointColor.opacity(0.12), in: Capsule())
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
