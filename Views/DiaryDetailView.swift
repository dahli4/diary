import SwiftUI

struct DiaryDetailView: View {
  let item: Item
  @Environment(\.dismiss) private var dismiss
  @State private var showEditor = false
  @State private var showDeleteAlert = false
  @State private var showSummary = false
  
  var body: some View {
    ZStack {
      EmotionalBackgroundView()
      
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          // 1. 제목(상단으로 이동)
          Text(item.title ?? "무제")
            .font(.system(size: 28, weight: .bold, design: .serif))
            .padding(.bottom, 8)
          
          // 2. 날짜/날씨 헤더(제목 아래로 이동)
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text(item.timestamp, formatter: DiaryDateFormatter.detailDate)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            
            // 감정
            if let mood = item.mood {
              Text(mood)
                .font(.title3)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
            }
            
            // 날씨
            if let weather = item.weather {
              Label(weather, systemImage: "cloud.sun")
                .font(.caption)
                .padding(8)
                .background(.ultraThinMaterial, in: Capsule())
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
          }
          
          Divider()
            .background(.secondary.opacity(0.3))
            .padding(.bottom, 24)

          // 회고 질문은 본문을 읽기 전에 보이도록 상단 배치
          if let reflectionPrompt = item.reflectionPrompt, !reflectionPrompt.isEmpty {
            Label(reflectionPrompt, systemImage: "questionmark.circle")
              .font(.footnote)
              .foregroundStyle(.secondary)
              .lineLimit(2)
              .padding(.bottom, 14)
          }
          
          // 내용
          Text(item.content ?? "내용 없음")
            .font(.body)
            .lineSpacing(6)
            .foregroundStyle(.primary.opacity(0.8))

          if hasReflectionData {
            VStack(alignment: .leading, spacing: 10) {
              Text("회고 메모")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 18)

              if !item.tags.isEmpty {
                horizontalChips(item.tags.map { "#\($0)" }, tint: Color.white.opacity(0.5))
              }

              let moodTags = MoodEmotionMapper.tags(for: item.mood)
              if !moodTags.isEmpty {
                horizontalChips(
                  moodTags,
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
          Button(role: .destructive, action: { showDeleteAlert = true }) {
            Label("삭제하기", systemImage: "trash")
          }
        } label: {
          Image(systemName: "ellipsis")
            .foregroundStyle(.primary)
        }
      }
    }
    .fullScreenCover(isPresented: $showEditor) {
      NavigationStack {
        DiaryEditorView(item: item)
      }
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

  private var hasReflectionData: Bool {
    let hasSummary = !(item.autoSummary?.isEmpty ?? true)
    let hasMoodTag = !MoodEmotionMapper.tags(for: item.mood).isEmpty
    return hasSummary || !item.tags.isEmpty || hasMoodTag
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
    }
  }
}
