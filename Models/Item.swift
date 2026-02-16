import Foundation
import SwiftData

@Model
final class Item {
  var timestamp: Date
  var photoData: Data?
  var tags: [String]
  var emotionTags: [String]
  var title: String?
  var content: String?
  var reflectionPrompt: String?
  var autoSummary: String?
  var weather: String?
  var mood: String? // 감정 프로퍼티 추가
  var isTrashed: Bool
  
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
