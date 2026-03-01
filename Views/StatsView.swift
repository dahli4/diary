import SwiftUI
import SwiftData
import Charts

// MARK: - StatsView

struct StatsView: View {
  @Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]
  @StateObject private var viewModel = StatsViewModel()

  var body: some View {
    ZStack {
      EmotionalBackgroundView()

      ScrollView {
        VStack(spacing: 24) {
          header

          // MARK: 섹션: 요약
          sectionGroup {
            sectionHeader("요약")
            StreakCardView(
              currentStreak: viewModel.currentStreak,
              bestStreak: viewModel.bestStreak
            )
          }

          // MARK: 섹션: 이달 감정
          sectionGroup {
            sectionHeader("이달 감정")

            if viewModel.filteredItems.isEmpty {
              emptyStateView
            } else {
              MoodDonutChartView(moodData: viewModel.moodData)
              TopEmotionTagsView(
                topTags: viewModel.topEmotionTags,
                maxCount: viewModel.maxTagCount
              )
            }
          }

          // MARK: 섹션: 작성 습관
          sectionGroup {
            sectionHeader("작성 습관")
            MonthlyBarChartView(monthCounts: viewModel.monthCounts)
            DayOfWeekChartView(dayCounts: viewModel.dayCounts, maxCount: viewModel.maxDayCount)
            TimeOfDayChartView(timeSlots: viewModel.timeSlots)
          }

          // MARK: 섹션: 상세 수치
          if !viewModel.filteredItems.isEmpty {
            sectionGroup {
              sectionHeader("상세 수치")

              VStack(spacing: 12) {
                HStack(spacing: 12) {
                  StatCard(
                    title: "기록 횟수",
                    value: "\(viewModel.filteredItems.count)회",
                    systemImage: "square.and.pencil"
                  )
                  StatCard(
                    title: "가장 자주 나온 감정",
                    value: viewModel.mostFrequentMood,
                    systemImage: "face.smiling"
                  )
                }

                HStack(spacing: 12) {
                  StatCard(
                    title: "평균 글자 수",
                    value: viewModel.averageCharCount > 0 ? "\(viewModel.averageCharCount)자" : "-",
                    systemImage: "character.cursor.ibeam"
                  )
                  StatCard(
                    title: "총 누적 기록",
                    value: "\(viewModel.totalItemCount)개",
                    systemImage: "archivebox"
                  )
                }

                StatCard(
                  title: "최근 7일 키워드",
                  value: viewModel.weeklyEmotionPattern,
                  systemImage: "sparkle.magnifyingglass"
                )
              }
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 40)
      }
    }
    .navigationBarHidden(true)
    .onAppear {
      viewModel.updateItems(items)
    }
    .onChange(of: items) { _, newItems in
      viewModel.updateItems(newItems)
    }
  }

  // MARK: - 헤더 (월 이동)

  private var header: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Text("감정 흐름")
        .font(.system(size: 26, weight: .bold, design: .serif))
        .foregroundStyle(.primary)

      Spacer()

      HStack(spacing: 8) {
        Button {
          viewModel.moveMonth(by: -1)
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.primary.opacity(0.7))
            .frame(width: 32, height: 32)
            .background(Color.primary.opacity(0.06))
            .clipShape(Circle())
        }

        Text(DiaryDateFormatter.yearMonth.string(from: viewModel.selectedMonth))
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.secondary)

        Button {
          viewModel.moveMonth(by: 1)
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

  // MARK: - 섹션 헤더

  private func sectionHeader(_ title: String) -> some View {
    Text(title)
      .font(.system(size: 13, weight: .semibold))
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - 섹션 그룹 컨테이너

  @ViewBuilder
  private func sectionGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      content()
    }
  }

  // MARK: - 이달 기록 없을 때 빈 상태

  private var emptyStateView: some View {
    ContentUnavailableView("이 달의 기록이 없어요", systemImage: "waveform.path.ecg")
      .padding(.vertical, 20)
  }
}

// MARK: - StatCard

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

// MARK: - mood 이모지별 색상 반환

private func moodColor(for mood: String) -> Color {
  switch mood {
  case "🥰", "😊", "🥳":
    return Color(red: 0.99, green: 0.78, blue: 0.35) // 기쁨
  case "😔":
    return Color(red: 0.40, green: 0.62, blue: 0.95) // 슬픔
  case "😡":
    return Color(red: 0.96, green: 0.34, blue: 0.32) // 분노
  case "😴":
    return Color(red: 0.30, green: 0.80, blue: 0.78) // 피로
  case "🤯":
    return Color.orange.opacity(0.85) // 과부하
  default:
    return Color.secondary.opacity(0.5)
  }
}

// MARK: - StreakCardView (연속 스트릭 카드)

private struct StreakCardView: View {
  let currentStreak: Int
  let bestStreak: Int

  var body: some View {
    HStack(spacing: 12) {
      StatCard(
        title: "현재 연속 🔥",
        value: "\(currentStreak)일",
        systemImage: "flame"
      )
      StatCard(
        title: "최고 기록",
        value: "\(bestStreak)일",
        systemImage: "trophy"
      )
    }
  }
}

// MARK: - DayOfWeekChartView (요일별 작성 패턴 차트)

private struct DayOfWeekChartView: View {
  let dayCounts: [StatsViewModel.DayCount]
  let maxCount: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("요일별 작성 패턴")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.primary)

      Chart(dayCounts) { entry in
        BarMark(
          x: .value("요일", entry.label),
          y: .value("기록 수", entry.count)
        )
        // 가장 많이 기록한 요일은 포인트 컬러로 강조
        .foregroundStyle(
          entry.count == maxCount && maxCount > 0
            ? AppTheme.pointColor
            : AppTheme.pointColor.opacity(0.45)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
      }
      .frame(height: 140)
      .chartXAxis {
        AxisMarks { _ in
          AxisValueLabel()
            .font(.system(size: 11))
            .foregroundStyle(Color.secondary)
        }
      }
      .chartYAxis {
        AxisMarks { _ in
          AxisGridLine()
            .foregroundStyle(Color.primary.opacity(0.08))
          AxisValueLabel()
            .font(.system(size: 11))
            .foregroundStyle(Color.secondary)
        }
      }
    }
    .padding(16)
    .liquidGlass(in: RoundedRectangle(cornerRadius: 18))
  }
}

// MARK: - TimeOfDayChartView (작성 시간대 분포)

struct TimeOfDayChartView: View {
  let timeSlots: [StatsViewModel.TimeSlot]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("작성 시간대 분포")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.primary)

      Chart(timeSlots) { slot in
        BarMark(
          x: .value("시간대", slot.label),
          y: .value("기록 수", slot.count)
        )
        .foregroundStyle(slot.color)
        .clipShape(RoundedRectangle(cornerRadius: 4))
      }
      .frame(height: 140)
      .chartXAxis {
        AxisMarks { _ in
          AxisValueLabel()
            .font(.system(size: 11))
            .foregroundStyle(Color.secondary)
        }
      }
      .chartYAxis {
        AxisMarks { _ in
          AxisGridLine()
            .foregroundStyle(Color.primary.opacity(0.08))
          AxisValueLabel()
            .font(.system(size: 11))
            .foregroundStyle(Color.secondary)
        }
      }
    }
    .padding(16)
    .liquidGlass(in: RoundedRectangle(cornerRadius: 18))
  }
}

// MARK: - TopEmotionTagsView (이달 감정 태그 Top 5)

private struct TopEmotionTagsView: View {
  let topTags: [StatsViewModel.TagEntry]
  let maxCount: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("이달 감정 태그 Top 5")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.primary)

      if topTags.isEmpty {
        Text("이달 감정 태그 기록이 없어요")
          .font(.system(size: 14))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 12)
      } else {
        VStack(spacing: 10) {
          ForEach(topTags) { entry in
            HStack(spacing: 8) {
              // 태그 이름 (고정 너비로 정렬)
              Text(entry.tag)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 52, alignment: .leading)
                .lineLimit(1)

              // 진행률 바
              ProgressView(value: Double(entry.count), total: Double(maxCount))
                .tint(AppTheme.pointColor)

              // 카운트
              Text("\(entry.count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .trailing)
            }
          }
        }
      }
    }
    .padding(16)
    .liquidGlass(in: RoundedRectangle(cornerRadius: 18))
  }
}

// MARK: - MoodDonutChartView (이달 기분 도넛 차트 카드)

private struct MoodDonutChartView: View {
  let moodData: [StatsViewModel.MoodData]

  private var total: Int {
    moodData.reduce(0) { $0 + $1.count }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("이달 기분 분포")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.primary)

      if moodData.isEmpty {
        Text("이달 기분 기록이 없어요")
          .font(.system(size: 14))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 20)
      } else {
        HStack(spacing: 16) {
          Chart(moodData, id: \.mood) { entry in
            SectorMark(
              angle: .value("count", entry.count),
              innerRadius: .ratio(0.55),
              angularInset: 1.5
            )
            .foregroundStyle(moodColor(for: entry.mood))
          }
          .frame(height: 200)

          // 이모지 + 퍼센트 범례
          VStack(alignment: .leading, spacing: 8) {
            ForEach(moodData, id: \.mood) { entry in
              HStack(spacing: 6) {
                Circle()
                  .fill(moodColor(for: entry.mood))
                  .frame(width: 8, height: 8)
                Text(entry.mood)
                  .font(.system(size: 14))
                  .foregroundStyle(Color.primary)
                Spacer()
                Text(total > 0 ? "\(Int(Double(entry.count) / Double(total) * 100))%" : "0%")
                  .font(.system(size: 12, weight: .semibold))
                  .foregroundStyle(.secondary)
              }
            }
          }
          .frame(minWidth: 80)
        }
      }
    }
    .padding(16)
    .liquidGlass(in: RoundedRectangle(cornerRadius: 18))
  }
}

// MARK: - MonthlyBarChartView (최근 6개월 월별 기록 추이 바 차트 카드)

private struct MonthlyBarChartView: View {
  let monthCounts: [StatsViewModel.MonthCount]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("월별 기록 추이")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.primary)

      Chart(monthCounts) { entry in
        BarMark(
          x: .value("월", entry.label),
          y: .value("기록 수", entry.count)
        )
        .foregroundStyle(AppTheme.pointColor.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 4))
      }
      .frame(height: 160)
      .chartXAxis {
        AxisMarks { _ in
          AxisValueLabel()
            .font(.system(size: 11))
            .foregroundStyle(Color.secondary)
        }
      }
      .chartYAxis {
        AxisMarks { _ in
          AxisGridLine()
            .foregroundStyle(Color.primary.opacity(0.08))
          AxisValueLabel()
            .font(.system(size: 11))
            .foregroundStyle(Color.secondary)
        }
      }
    }
    .padding(16)
    .liquidGlass(in: RoundedRectangle(cornerRadius: 18))
  }
}
