import Foundation

final class ReflectionAnalysisService {
  static let shared = ReflectionAnalysisService()
  private let adoptionThreshold = 0.2

  private init() {}

  func analyze(content: String, mood: String?) async -> ReflectionAnalysis {
    let fallback = ReflectionAnalyzer.analyze(content: content, mood: mood)

    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      do {
        if let onDevice = try await AppleOnDeviceDiaryAnalyzer.analyze(content: content, mood: mood) {
          let onDeviceScore = AppleOnDeviceDiaryAnalyzer.qualityScore(summary: onDevice.summary, source: content)
          let fallbackScore = AppleOnDeviceDiaryAnalyzer.qualityScore(summary: fallback.summary, source: content)

          if onDeviceScore >= fallbackScore + adoptionThreshold {
            return onDevice
          }
        }
      } catch {
        // 온디바이스 모델이 없을 때 로컬 규칙으로 폴백
      }
    }
    #endif

    return fallback
  }
}

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
private enum AppleOnDeviceDiaryAnalyzer {
  private static let summaryStyle = "사실 요약형"
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
        .filter { !$0.isEmpty }
        .prefix(3)

      candidates.append(ReflectionAnalysis(summary: refinedSummary, emotionTags: Array(tags)))
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
    output = output.replacingOccurrences(of: "  ", with: " ")
    return output.trimmingCharacters(in: .whitespacesAndNewlines)
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
