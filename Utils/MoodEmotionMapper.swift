import Foundation

enum MoodEmotionMapper {
  // 무드 이모지 기준으로만 감정 배지를 노출한다.
  static func tags(for mood: String?) -> [String] {
    guard let mood else { return [] }
    guard let tag = tag(for: mood) else { return [] }
    return [tag]
  }

  static func tag(for mood: String) -> String? {
    switch mood {
    case "🥰", "😊", "🥳":
      return "기쁨"
    case "😔":
      return "슬픔"
    case "😡":
      return "분노"
    case "😴":
      return "피로"
    case "🤯":
      return "과부하"
    default:
      return nil
    }
  }
}
