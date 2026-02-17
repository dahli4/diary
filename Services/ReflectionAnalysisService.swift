import Foundation

final class ReflectionAnalysisService {
  static let shared = ReflectionAnalysisService()
  private let onDeviceMinimumScore = 0.22

  private init() {}

  func analyze(content: String, mood: String?) async -> ReflectionAnalysis {
    // 감정 태그는 무드 이모지 기반으로만 생성한다.
    let moodTags = MoodEmotionMapper.tags(for: mood)

    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      do {
        if let onDevice = try await AppleOnDeviceDiaryAnalyzer.analyze(content: content, mood: mood) {
          let onDeviceScore = AppleOnDeviceDiaryAnalyzer.qualityScore(
            summary: onDevice.summary,
            source: content
          )
          if onDeviceScore >= onDeviceMinimumScore {
            return ReflectionAnalysis(summary: onDevice.summary, emotionTags: moodTags)
          }
        }
      } catch {
        // 인텔리전스 미지원/비활성 기기에서는 요약을 생성하지 않는다.
      }
      return ReflectionAnalysis(summary: "", emotionTags: moodTags)
    }
    #endif

    return ReflectionAnalysis(summary: "", emotionTags: moodTags)
  }
}

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
private enum AppleOnDeviceDiaryAnalyzer {
  private static let summaryStyle = "자연스러운 회고형"
  private static let bannedFragments = [
    "기록이 짧아요",
    "한 줄만 더",
    "남겨보세요",
    "적어보세요",
    "핵심 흐름을 정리",
    "뚜렷한 감정 키워드 없음"
  ]

  static func analyze(content: String, mood: String?) async throws -> ReflectionAnalysis? {
    guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return nil
    }

    let session = LanguageModelSession()
    let prompt = buildPrompt(content: content, mood: mood)
    var candidates: [ReflectionAnalysis] = []

    for _ in 0..<2 {
      let response = try await session.respond(to: prompt)
      let rawText = response.content

      guard let json = extractJSONObject(from: rawText),
            let data = json.data(using: .utf8),
            let payload = try? JSONDecoder().decode(OnDevicePayload.self, from: data)
      else {
        continue
      }

      let refinedSummary = refineSummary(payload.summary)
      guard !refinedSummary.isEmpty else { continue }

      let tags = payload.emotionTags
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

      let normalizedTags = EmotionTagNormalizer.normalizeList(tags, limit: 3)
      candidates.append(ReflectionAnalysis(summary: refinedSummary, emotionTags: normalizedTags))
    }

    guard !candidates.isEmpty else { return nil }
    return chooseBest(from: candidates, source: content)
  }

  private static func buildPrompt(content: String, mood: String?) -> String {
    """
    너는 일기 요약 도우미다.
    스타일은 반드시 \(summaryStyle)로 고정한다.
    입력된 일기를 기반으로 다음 JSON만 출력해라.
    규칙:
    - summary: 반드시 한 줄. 자연스러운 한국어 문장으로 작성.
    - 보고체/브리핑체 문장을 피하고, 일기 맥락에 맞는 부드러운 톤으로 작성.
    - "핵심:", "배경:", "감정:" 같은 라벨을 붙이지 마라.
    - 번호(1.,2.,3.) 형식을 절대 쓰지 마라.
    - 원문 문장을 그대로 길게 복붙하지 말고 핵심만 압축.
    - emotionTags: 감정 태그 0~3개. 없으면 빈 배열.
    - 출력은 JSON 객체 하나만.

    입력:
    mood: \(mood ?? "없음")
    content: \(content)

    JSON 스키마:
    {"summary":"string","emotionTags":["string"]}
    """
  }

  private static func refineSummary(_ summary: String) -> String {
    let singleLine = summary
      .replacingOccurrences(of: "\n", with: " ")
      .components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
      .joined(separator: " ")

    return sanitizeLine(singleLine)
  }

  private static func sanitizeLine(_ line: String) -> String {
    var output = line
    for fragment in bannedFragments {
      output = output.replacingOccurrences(of: fragment, with: "")
    }
    output = output.replacingOccurrences(of: "요약:", with: "")
    output = output.replacingOccurrences(of: "핵심:", with: "")
    output = output.replacingOccurrences(of: "배경:", with: "")
    output = output.replacingOccurrences(of: "감정:", with: "")
    output = output.replacingOccurrences(of: "1.", with: "")
    output = output.replacingOccurrences(of: "2.", with: "")
    output = output.replacingOccurrences(of: "3.", with: "")
    output = output.replacingOccurrences(of: "  ", with: " ")
    let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.hasSuffix(".") || trimmed.hasSuffix("!") || trimmed.hasSuffix("?") {
      return trimmed
    }
    return trimmed + "."
  }

  private static func chooseBest(from candidates: [ReflectionAnalysis], source: String) -> ReflectionAnalysis {
    let ranked = candidates
      .enumerated()
      .map { index, item in
        (index: index, score: qualityScore(summary: item.summary, source: source))
      }
      .sorted { $0.score > $1.score }

    return candidates[ranked.first?.index ?? 0]
  }

  static func qualityScore(summary: String, source: String) -> Double {
    let summaryTokens = tokenize(summary)
    let sourceTokens = Set(tokenize(source))
    if summaryTokens.isEmpty { return -999 }

    let overlap = summaryTokens.filter { sourceTokens.contains($0) }.count
    let overlapRatio = Double(overlap) / Double(summaryTokens.count)

    let uniqueRatio = Double(Set(summaryTokens).count) / Double(summaryTokens.count)
    let repetitionPenalty = max(0.0, 1.0 - uniqueRatio)
    let lengthPenalty = summary.count > 110 ? 0.25 : 0.0

    return overlapRatio * 1.2 + uniqueRatio * 0.4 - repetitionPenalty * 0.4 - lengthPenalty
  }

  private static func tokenize(_ text: String) -> [String] {
    text.lowercased()
      .components(separatedBy: CharacterSet.alphanumerics.inverted)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { $0.count >= 2 }
  }

  private static func extractJSONObject(from text: String) -> String? {
    guard let first = text.firstIndex(of: "{"), let last = text.lastIndex(of: "}") else {
      return nil
    }
    return String(text[first...last])
  }

  private struct OnDevicePayload: Decodable {
    let summary: String
    let emotionTags: [String]
  }
}
#endif
