import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct DiaryEditorView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  
  @StateObject private var viewModel: DiaryEditorViewModel
  @State private var showMoodSelector = false // 이모지 선택기 표시 여부
  
  init(item: Item?, initialPrompt: String? = nil) {
    _viewModel = StateObject(wrappedValue: DiaryEditorViewModel(item: item, initialPrompt: initialPrompt))
  }
  
  var body: some View {
    ZStack {
      // 일관된 배경 적용
      EmotionalBackgroundView()
      
      VStack(spacing: 0) {
        // 상단 바
        HStack {
          Button("취소") {
            if viewModel.isDirty {
              viewModel.showDiscardAlert = true
            } else {
              dismiss()
            }
          }
          .foregroundStyle(.secondary)
          
          Spacer()
          
          DatePicker("", selection: $viewModel.selectedDate, displayedComponents: [.date])
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "ko_KR")) // 한국어 로케일 강제 적용
            .colorInvert()
            .colorMultiply(.primary)
          
          // 날씨 버튼
          Button(action: {
            viewModel.fetchWeather()
          }) {
            if let weather = viewModel.weather {
              Label(weather, systemImage: "cloud.sun")
                .font(.caption)
                .padding(8)
                .background(.ultraThinMaterial, in: Capsule())
            } else {
              Image(systemName: "cloud.sun")
                .foregroundStyle(.secondary)
            }
          }
          
          Spacer()
          
          Button(viewModel.isSaving ? "저장중..." : "저장") {
            Task {
              await viewModel.saveItem(modelContext: modelContext)
              dismiss()
            }
          }
          .font(.headline)
          .foregroundStyle(.primary)
          .disabled((viewModel.title.isEmpty && viewModel.content.isEmpty) || viewModel.isSaving)
        }
        .padding()

        // 날씨 에러 배너
        if let weatherError = viewModel.weatherError {
          HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(.orange)
            Text(weatherError)
              .font(.caption)
              .foregroundStyle(.primary)
            Spacer()
            Button {
              viewModel.weatherError = nil
            } label: {
              Image(systemName: "xmark")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .background(.ultraThinMaterial)
          .transition(.move(edge: .top).combined(with: .opacity))
        }

        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            
            // 이미지 영역
            if let data = viewModel.selectedPhotoData, let uiImage = UIImage(data: data) {
              ZStack(alignment: .topTrailing) {
                Image(uiImage: uiImage)
                  .resizable()
                  .scaledToFill()
                  .frame(minHeight: 200, maxHeight: 300)
                  .frame(maxWidth: .infinity)
                  .clipShape(RoundedRectangle(cornerRadius: 16))
                  .shadow(radius: 5)
                
                Button {
                  withAnimation {
                    viewModel.selectedPhotoData = nil
                    viewModel.photoItem = nil
                  }
                } label: {
                  Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding()
                }
              }
            }
            
            // 제목 영역
            TextField("제목을 적어주세요", text: $viewModel.title)
              .font(.system(size: 28, weight: .bold, design: .serif))
              .padding(.horizontal, 4)
            
            // 내용 영역
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Label("오늘의 회고 질문", systemImage: "sparkles.rectangle.stack")
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.secondary)
                Spacer()
                Button("바꾸기") {
                  viewModel.regeneratePrompt()
                }
                .font(.caption)
              }

              Text(viewModel.reflectionPrompt)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }

            ZStack(alignment: .topLeading) {
              if viewModel.content.isEmpty {
                Text("오늘 하루, 어떤 감정을 느끼셨나요?")
                  .font(.body)
                  .foregroundStyle(.secondary.opacity(0.6))
                  .padding(.top, 8)
                  .padding(.leading, 4)
              }
              TextEditor(text: $viewModel.content)
                .font(.body)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 300)
            }
          }
          .padding()
        }
        
        // 감정 선택 영역(조건부 표시)
        if showMoodSelector {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
              let moods = ["🥰", "😊", "😐", "😔", "😡", "🥳", "😴", "🤯"]
              ForEach(moods, id: \.self) { mood in
                Button {
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    viewModel.mood = mood
                    showMoodSelector = false
                  }
                } label: {
                  ZStack {
                    if viewModel.mood == mood {
                      Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .transition(.scale)
                    }
                    
                    Text(mood)
                      .font(.system(size: 28))
                      .scaleEffect(viewModel.mood == mood ? 1.2 : 1.0)
                  }
                  .frame(width: 44, height: 44)
                }
              }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
          }
          .background(.ultraThinMaterial)
          .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        
        // 도구 영역(하단 고정)
        HStack(spacing: 12) {
          // 감정 버튼
          Button(action: {
            withAnimation {
              showMoodSelector.toggle()
            }
          }) {
            if let mood = viewModel.mood {
              Text(mood)
                .font(.title2)
            } else {
              Image(systemName: "face.smiling") // 기본 아이콘
                .font(.title3)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Color.white.opacity(0.4), in: Capsule())
          
          // 사진 버튼
          PhotosPicker(selection: $viewModel.photoItem, matching: .images) {
            Label("사진", systemImage: "photo")
              .font(.caption)
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(Color.white.opacity(0.4), in: Capsule())
          }
          
          // 태그 입력
          HStack {
            Image(systemName: "tag")
              .font(.caption)
              .foregroundStyle(.secondary)
            TextField("직접 태그 (예: #휴식)", text: $viewModel.tagsString)
              .font(.caption)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Color.white.opacity(0.4), in: Capsule())
        }
        .padding(.top, 8)
        .padding(.bottom, 8) // 터치 영역 확보를 위한 여백
        .padding(.horizontal)
        .background(.ultraThinMaterial) // 본문과 분리되는 배경
      }
    }
    .navigationTitle("")
    .navigationBarHidden(true)
    .alert("작성 중인 내용이 있습니다", isPresented: $viewModel.showDiscardAlert) {
      Button("계속 작성", role: .cancel) { }
      Button("나가기", role: .destructive) { dismiss() }
    }
  }
}
