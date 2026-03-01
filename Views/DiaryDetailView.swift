import SwiftUI

struct DiaryDetailView: View {
  let item: Item
  @Environment(\.dismiss) private var dismiss
  @State private var showEditor = false
  @State private var showDeleteAlert = false
  @State private var showSummary = false
  @State private var showShareSheet = false

  var body: some View {
    ZStack {
      EmotionalBackgroundView()

      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          // 1. 제목
          Text(item.title ?? "무제")
            .font(.system(size: 28, weight: .bold, design: .serif))
            .padding(.bottom, 8)
            .accessibilityAddTraits(.isHeader)

          // 2. 날짜/날씨 헤더
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text(item.timestamp, formatter: DiaryDateFormatter.detailDate)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityLabel("작성일: \(DiaryDateFormatter.detailDate.string(from: item.timestamp))")
            }
            Spacer()

            // 감정
            if let mood = item.mood {
              Text(mood)
                .font(.title3)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
                .accessibilityLabel("기분: \(mood)")
            }

            // 날씨
            if let weather = item.weather {
              Label(weather, systemImage: "cloud.sun")
                .font(.caption)
                .padding(8)
                .background(.ultraThinMaterial, in: Capsule())
                .accessibilityLabel("날씨: \(weather)")
            }
          }
          .padding(.bottom, 20)

          // 사진
          if let photoData = item.photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
              .resizable()
              .scaledToFill()
              .frame(maxHeight: 400)
              .clipShape(RoundedRectangle(cornerRadius: 16))
              .shadow(radius: 5)
              .padding(.bottom, 24)
              .accessibilityLabel("첨부 사진")
          }

          Divider()
            .background(.secondary.opacity(0.3))
            .padding(.bottom, 24)

          // 회고 질문
          if let reflectionPrompt = item.reflectionPrompt, !reflectionPrompt.isEmpty {
            Label(reflectionPrompt, systemImage: "questionmark.circle")
              .font(.footnote)
              .foregroundStyle(.secondary)
              .lineLimit(2)
              .padding(.bottom, 14)
              .accessibilityLabel("오늘의 회고 질문: \(reflectionPrompt)")
          }

          // 내용
          Text(item.content ?? "내용 없음")
            .font(.body)
            .lineSpacing(6)
            .foregroundStyle(.primary.opacity(0.8))
            .accessibilityLabel(item.content ?? "내용 없음")

          if hasReflectionData {
            VStack(alignment: .leading, spacing: 10) {
              Text("회고 메모")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 18)

              if !item.tags.isEmpty {
                horizontalChips(item.tags.map { "#\($0)" }, tint: Color.white.opacity(0.5))
              }

              if !item.emotionTags.isEmpty {
                horizontalChips(
                  EmotionTagNormalizer.normalizeList(item.emotionTags.filter { $0 != "감정기록" }, limit: 10),
                  tint: Color.accentColor.opacity(0.14)
                )
              }

              if let autoSummary = item.autoSummary, !autoSummary.isEmpty {
                DisclosureGroup("요약 보기", isExpanded: $showSummary) {
                  Text(autoSummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .padding(.top, 6)
                }
                .font(.callout.weight(.semibold))
              }
            }
          }

        }
        .padding(24)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
          Button(action: { showEditor = true }) {
            Label("수정하기", systemImage: "pencil")
          }
          // 공유 버튼 추가
          Button(action: { showShareSheet = true }) {
            Label("공유하기", systemImage: "square.and.arrow.up")
          }
          Divider()
          Button(role: .destructive, action: { showDeleteAlert = true }) {
            Label("삭제하기", systemImage: "trash")
          }
        } label: {
          Image(systemName: "ellipsis")
            .foregroundStyle(.primary)
            .accessibilityLabel("더보기 메뉴")
        }
      }
    }
    .fullScreenCover(isPresented: $showEditor) {
      NavigationStack {
        DiaryEditorView(item: item)
      }
    }
    .sheet(isPresented: $showShareSheet) {
      ShareSheet(items: shareItems)
    }
    .alert("일기를 삭제하시겠습니까?", isPresented: $showDeleteAlert) {
      Button("삭제(휴지통으로 이동)", role: .destructive) {
        withAnimation {
          item.isTrashed = true
        }
        dismiss()
      }
      Button("취소", role: .cancel) { }
    } message: {
      Text("삭제된 일기는 휴지통에서 복구할 수 있습니다.")
    }
  }

  // MARK: - 공유 콘텐츠 구성

  private var shareItems: [Any] {
    var items: [Any] = []

    let dateString = DiaryDateFormatter.detailDate.string(from: item.timestamp)
    var text = "[\(dateString)]\n"
    if let title = item.title, !title.isEmpty {
      text += "\(title)\n\n"
    }
    if let content = item.content, !content.isEmpty {
      text += content
    }
    if let mood = item.mood {
      text += "\n\n기분: \(mood)"
    }
    if let weather = item.weather {
      text += "  날씨: \(weather)"
    }
    items.append(text)

    // 사진이 있으면 함께 공유
    if let photoData = item.photoData, let uiImage = UIImage(data: photoData) {
      items.append(uiImage)
    }

    return items
  }

  private var hasReflectionData: Bool {
    let hasSummary = !(item.autoSummary?.isEmpty ?? true)
    return hasSummary || !item.tags.isEmpty || !item.emotionTags.isEmpty
  }

  @ViewBuilder
  private func horizontalChips(_ values: [String], tint: Color) -> some View {
    if !values.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
          ForEach(values, id: \.self) { value in
            Text(value)
              .font(.caption)
              .padding(.horizontal, 9)
              .padding(.vertical, 5)
              .background(tint, in: Capsule())
          }
        }
      }
      .accessibilityLabel("태그: \(values.joined(separator: ", "))")
    }
  }
}

// MARK: - UIActivityViewController 래퍼

private struct ShareSheet: UIViewControllerRepresentable {
  let items: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: items, applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
