import Foundation
import SwiftData

@Model
final class Item {
  // CloudKit 동기화 호환을 위해 기본값 명시
  var timestamp: Date = Date()
  var photoData: Data?
  var tags: [String] = []
  var emotionTags: [String] = []
  var title: String?
  var content: String?
  var reflectionPrompt: String?
  var autoSummary: String?
  var weather: String?
  var mood: String?
  var isTrashed: Bool = false
  
  init(timestamp: Date, photoData: Data? = nil, tags: [String] = [], emotionTags: [String] = [], title: String? = nil, content: String? = nil, reflectionPrompt: String? = nil, autoSummary: String? = nil, weather: String? = nil, mood: String? = nil, isTrashed: Bool = false) {
    self.timestamp = timestamp
    self.photoData = photoData
    self.tags = tags
    self.emotionTags = emotionTags
    self.title = title
    self.content = content
    self.reflectionPrompt = reflectionPrompt
    self.autoSummary = autoSummary
    self.weather = weather
    self.mood = mood
    self.isTrashed = isTrashed
  }
}
