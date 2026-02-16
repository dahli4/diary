import Foundation

enum EmotionTagNormalizer {
  static func normalize(_ tag: String) -> String? {
    let value = tag.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else { return nil }

    let key = value.lowercased()

    switch key {
    case "joy", "happy", "happiness", "delight":
      return "기쁨"
    case "sad", "sadness", "depressed", "sorrow":
      return "슬픔"
    case "anger", "angry", "frustration", "frustrated", "rage":
      return "분노"
    case "anxiety", "anxious", "worry", "worried", "fear", "nervous":
      return "불안"
    case "calm", "peace", "peaceful", "stable":
      return "안정"
    case "focus", "focused", "concentration":
      return "집중"
    case "gratitude", "grateful", "thanks", "thankful":
      return "감사"
    case "fatigue", "tired", "exhausted", "burnout":
      return "피로"
    case "neutral":
      return nil
    default:
      return value
    }
  }

  static func normalizeList(_ tags: [String], limit: Int = 3) -> [String] {
    var seen: Set<String> = []
    var result: [String] = []

    for tag in tags {
      guard let normalized = normalize(tag), !seen.contains(normalized) else { continue }
      seen.insert(normalized)
      result.append(normalized)
      if result.count >= limit { break }
    }

    return result
  }

<<<<<<< feat/codex/ui-accent-red-and-lock-flow
  // 감정 빈도 집계에서는 중복 출현을 유지해야 하므로 전체 정규화 배열을 제공한다.
=======
  // 빈도 계산이 필요한 화면에서는 중복을 유지한 채 정규화한다.
>>>>>>> dev
  static func normalizeAll(_ tags: [String]) -> [String] {
    tags.compactMap { normalize($0) }
  }
}
