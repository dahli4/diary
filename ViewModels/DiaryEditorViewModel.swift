import SwiftUI
import SwiftData
import PhotosUI
import Combine

@MainActor
class DiaryEditorViewModel: ObservableObject {
  @Published var title: String = ""
  @Published var content: String = ""
  @Published var tagsString: String = ""
  @Published var selectedDate: Date = Date()
  @Published var selectedPhotoData: Data?
  @Published var weather: String? // 날씨 상태 추가
  @Published var mood: String? // 감정 상태 추가
  @Published var reflectionPrompt: String = ""
  @Published var isSaving = false
  @Published var weatherError: String?
  @Published var photoItem: PhotosPickerItem? {
    didSet {
      loadPhotoData()
    }
  }
  
  @Published var showDiscardAlert = false
  
  private var item: Item?
  
  init(item: Item?, initialPrompt: String? = nil) {
    self.item = item
    
    if let item = item {
      self.title = item.title ?? ""
      self.content = item.content ?? ""
      self.tagsString = item.tags.joined(separator: " ")
      self.selectedDate = item.timestamp
      self.selectedPhotoData = item.photoData
      self.weather = item.weather
      self.mood = item.mood
      self.reflectionPrompt = item.reflectionPrompt ?? ReflectionAnalyzer.prompt()
    } else {
      self.reflectionPrompt = initialPrompt ?? ReflectionAnalyzer.prompt()
    }
  }
  
  var isDirty: Bool {
    if let item = item {
      return title != (item.title ?? "") ||
      content != (item.content ?? "") ||
      tagsString != item.tags.joined(separator: " ") ||
      selectedPhotoData != item.photoData ||
      mood != item.mood
    } else {
      return !title.isEmpty || !content.isEmpty || selectedPhotoData != nil
    }
  }
  
  func fetchWeather() {
    weatherError = nil
    Task {
      let fetchedWeather = await WeatherService.shared.fetchCurrentWeather()
      await MainActor.run {
        if fetchedWeather == .unknown {
          // 사용자 친화적 메시지만 노출 (API 키 이슈 등 기술적 에러는 표시 안 함)
          self.weatherError = WeatherService.shared.userFacingError
        } else {
          self.weather = fetchedWeather.description
          self.weatherError = nil
        }
      }
    }
  }
  
  func saveItem(modelContext: ModelContext) async {
    isSaving = true
    defer { isSaving = false }

    let tags = tagsString
      .replacingOccurrences(of: "#", with: "")
      .split(separator: " ")
      .map(String.init)
    
    let analysis = await ReflectionAnalysisService.shared.analyze(content: content, mood: mood)

    if let item = item {
      item.title = title
      item.content = content
      item.tags = tags
      item.timestamp = selectedDate
      item.photoData = selectedPhotoData
      item.weather = weather
      item.mood = mood
      item.reflectionPrompt = reflectionPrompt
      item.autoSummary = analysis.summary
      item.emotionTags = analysis.emotionTags
    } else {
      let newItem = Item(
        timestamp: selectedDate,
        photoData: selectedPhotoData,
        tags: tags,
        emotionTags: analysis.emotionTags,
        title: title,
        content: content,
        reflectionPrompt: reflectionPrompt,
        autoSummary: analysis.summary,
        weather: weather,
        mood: mood
      )
      modelContext.insert(newItem)
    }

    // 위젯 데이터 갱신: 저장 직후 오늘의 기록 상태를 반영한다.
    let savedTitle = title.isEmpty ? nil : title
    WidgetDataService.update(
      lastMood: mood,
      lastTitle: savedTitle,
      wroteToday: Calendar.current.isDateInToday(selectedDate),
      streakCount: 0 // TODO: 연속 기록 계산 추가
    )
  }

  func regeneratePrompt() {
    reflectionPrompt = ReflectionAnalyzer.prompt(excluding: reflectionPrompt)
  }
  
  private func loadPhotoData() {
    guard let photoItem = photoItem else { return }
    Task {
      if let data = try? await photoItem.loadTransferable(type: Data.self) {
        await MainActor.run {
          self.selectedPhotoData = data
        }
      }
    }
  }
}
