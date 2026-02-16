import Foundation
import NaturalLanguage

struct ReflectionAnalysis {
  let summary: String
  let emotionTags: [String]
}

enum ReflectionAnalyzer {
  private static let prompts = [
    "오늘 가장 에너지가 높았던 순간은 언제였나요?",
    "오늘 나를 가장 지치게 한 순간은 무엇이었나요?",
    "오늘의 나를 한 문장으로 칭찬한다면?",
    "오늘 가장 오래 남을 장면은 무엇인가요?",
    "지금 감정을 만든 사건 하나를 적어보세요."
  ]

  private static let emotionRules: [(tag: String, keywords: [String])] = [
    ("안정", ["평온", "차분", "편안", "안정", "여유"]),
    ("기쁨", ["행복", "기쁨", "웃", "설렘", "즐거", "뿌듯"]),
    ("감사", ["감사", "고마", "든든", "따뜻"]),
    ("피로", ["피곤", "지침", "지쳤", "무기력", "졸림", "버겁"]),
    ("불안", ["불안", "걱정", "초조", "긴장", "압박", "부담", "막막"]),
    ("분노", ["화", "짜증", "분노", "답답", "억울", "빡침"]),
    ("슬픔", ["슬픔", "우울", "눈물", "외롭", "허무"]),
    ("집중", ["몰입", "집중", "성취", "해냈", "완료"])
  ]

  private static let stopwords: Set<String> = [
    "그리고", "그러나", "하지만", "그래서", "그런데", "정말", "진짜", "그냥", "너무", "조금",
    "오늘", "어제", "내일", "지금", "이제", "이거", "저거", "그거", "내용", "부분", "상황",
    "문제", "생각", "기분", "때문", "관련", "대한", "위해", "에서", "으로", "에게", "했다", "하는"
  ]

  static func prompt(excluding current: String? = nil) -> String {
    if prompts.isEmpty { return "오늘 가장 오래 남을 장면은 무엇인가요?" }
    if let current, prompts.count > 1 {
      let candidates = prompts.filter { $0 != current }
      return candidates.randomElement() ?? prompts[0]
    }
    return prompts.randomElement() ?? prompts[0]
  }

  static func analyze(content: String, mood: String?) -> ReflectionAnalysis {
    let cleaned = normalize(content)
    guard !cleaned.isEmpty else {
      return ReflectionAnalysis(
        summary: [
          "1. 핵심: 기록 내용이 짧아 핵심을 판단하기 어려움",
          "2. 맥락: 구체적인 장면이 추가되면 요약 정확도가 올라감",
          "3. 감정: 감정 단서가 충분하지 않음"
        ].joined(separator: "\n"),
        emotionTags: []
      )
    }

    let sentences = extractSentences(from: cleaned)
    let keywordWeights = keywordWeightMap(from: cleaned)
    let rankedIndices = rankedSentenceIndices(sentences: sentences, keywordWeights: keywordWeights)
    let keywords = topKeywords(from: keywordWeights, limit: 3)

    var detected = detectEmotionTags(in: cleaned)
    if let mood, let moodTag = moodTag(from: mood) {
      detected.append(moodTag)
    }

    let uniqueTags = orderedUnique(detected)
    let summary = buildSummary(
      source: cleaned,
      sentences: sentences,
      rankedIndices: rankedIndices,
      keywords: keywords,
      emotionTags: uniqueTags
    )

    return ReflectionAnalysis(summary: summary, emotionTags: uniqueTags)
  }

  private static func moodTag(from mood: String) -> String? {
    switch mood {
    case "🥰", "😊", "🥳":
      return "긍정"
    case "😔":
      return "침잠"
    case "😡":
      return "격양"
    case "😴":
      return "저에너지"
    case "🤯":
      return "과부하"
    default:
      return nil
    }
  }

  private static func buildSummary(
    source: String,
    sentences: [String],
    rankedIndices: [Int],
    keywords: [String],
    emotionTags: [String]
  ) -> String {
    guard !sentences.isEmpty else {
      return [
        "1. 핵심: 핵심 장면을 파악하기 어려움",
        "2. 맥락: 맥락 정보가 부족함",
        "3. 감정: 감정 흐름을 추정하기 어려움"
      ].joined(separator: "\n")
    }

    let primaryIndex = rankedIndices.first ?? 0
    let primarySentence = sentences[primaryIndex]
    let contextSentence = chooseContextSentence(
      sentences: sentences,
      rankedIndices: rankedIndices,
      primaryIndex: primaryIndex
    )

    let issueLine = issueLine(primarySentence: primarySentence, keywords: keywords)
    let contextLine = contextLine(contextSentence: contextSentence, sentenceCount: sentences.count)
    let emotionLine = emotionLine(from: emotionTags, source: source)

    return [
      "1. 핵심: \(issueLine)",
      "2. 맥락: \(contextLine)",
      "3. 감정: \(emotionLine)"
    ].joined(separator: "\n")
  }

  private static func issueLine(primarySentence: String, keywords: [String]) -> String {
    if keywords.count >= 2 {
      return "\(keywords[0])과 \(keywords[1])을 중심으로 핵심 흐름이 전개됨"
    }
    if let keyword = keywords.first {
      return "\(keyword)을 중심으로 오늘의 경험을 정리함"
    }
    return clipped(primarySentence, limit: 44)
  }

  private static func contextLine(contextSentence: String?, sentenceCount: Int) -> String {
    if sentenceCount <= 1 {
      return "한 가지 장면을 중심으로 생각을 정리함"
    }
    guard let contextSentence, !contextSentence.isEmpty else {
      return "여러 장면을 비교하며 원인과 결과를 정리함"
    }
    return clipped(contextSentence, limit: 54)
  }

  private static func emotionLine(from emotionTags: [String], source: String) -> String {
    if !emotionTags.isEmpty {
      let core = emotionTags.prefix(2).joined(separator: "·")
      return "\(core) 감정이 두드러짐"
    }

    if containsAny(source, ["기쁘", "행복", "설렘", "뿌듯"]) {
      return "긍정 정서가 비교적 안정적으로 나타남"
    }
    if containsAny(source, ["불안", "걱정", "초조", "긴장"]) {
      return "걱정과 긴장감이 함께 나타남"
    }
    if containsAny(source, ["답답", "짜증", "화", "억울"]) {
      return "답답함과 예민함이 함께 나타남"
    }
    if containsAny(source, ["피곤", "지침", "지쳤", "무기력"]) {
      return "저에너지 상태가 드러남"
    }
    return "감정 표현이 크지 않지만 상황 인식은 분명함"
  }

  private static func chooseContextSentence(
    sentences: [String],
    rankedIndices: [Int],
    primaryIndex: Int
  ) -> String? {
    guard sentences.count > 1 else { return nil }

    let primaryTokens = Set(wordTokens(from: sentences[primaryIndex]))

    for index in rankedIndices where index != primaryIndex {
      let candidateTokens = Set(wordTokens(from: sentences[index]))
      let similarity = jaccardSimilarity(primaryTokens, candidateTokens)
      if similarity < 0.72 {
        return sentences[index]
      }
    }

    if let fallbackIndex = sentences.indices.first(where: { $0 != primaryIndex }) {
      return sentences[fallbackIndex]
    }
    return nil
  }

  private static func rankedSentenceIndices(sentences: [String], keywordWeights: [String: Double]) -> [Int] {
    sentences.indices
      .map { index in
        (index, sentenceScore(sentences[index], index: index, total: sentences.count, keywordWeights: keywordWeights))
      }
      .sorted { lhs, rhs in
        if lhs.1 == rhs.1 { return lhs.0 < rhs.0 }
        return lhs.1 > rhs.1
      }
      .map(\.0)
  }

  private static func sentenceScore(
    _ sentence: String,
    index: Int,
    total: Int,
    keywordWeights: [String: Double]
  ) -> Double {
    let tokens = wordTokens(from: sentence)
    guard !tokens.isEmpty else { return 0.0 }

    let keywordScore = tokens.reduce(0.0) { partial, token in
      partial + (keywordWeights[token] ?? 0.0)
    }

    let uniqueBonus = Double(Set(tokens).count) / Double(tokens.count)
    let positionBonus = (index == 0 || index == total - 1) ? 0.35 : 0.0
    let lengthBonus = (sentence.count >= 16 && sentence.count <= 80) ? 0.2 : -0.05

    return keywordScore + uniqueBonus + positionBonus + lengthBonus
  }

  private static func keywordWeightMap(from text: String) -> [String: Double] {
    let tokens = wordTokens(from: text)
    var frequencies: [String: Int] = [:]
    for token in tokens {
      frequencies[token, default: 0] += 1
    }

    return frequencies.reduce(into: [:]) { partial, item in
      partial[item.key] = Double(item.value)
    }
  }

  private static func topKeywords(from weights: [String: Double], limit: Int) -> [String] {
    weights
      .sorted {
        if $0.value == $1.value { return $0.key < $1.key }
        return $0.value > $1.value
      }
      .prefix(limit)
      .map(\.key)
  }

  private static func extractSentences(from text: String) -> [String] {
    var sentences: [String] = []
    let tokenizer = NLTokenizer(unit: .sentence)
    tokenizer.string = text

    tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
      let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
      if !sentence.isEmpty {
        sentences.append(stripTrailingPunctuation(from: sentence))
      }
      return true
    }

    if !sentences.isEmpty { return sentences }

    return text
      .components(separatedBy: CharacterSet(charactersIn: ".!?。！？\n"))
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .map { stripTrailingPunctuation(from: $0) }
  }

  private static func wordTokens(from text: String) -> [String] {
    var tokens: [String] = []
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = text

    tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
      let token = String(text[range]).lowercased()
      if isMeaningfulToken(token) {
        tokens.append(token)
      }
      return true
    }

    return tokens
  }

  private static func isMeaningfulToken(_ token: String) -> Bool {
    guard token.count >= 2 else { return false }
    if stopwords.contains(token) { return false }
    if token.allSatisfy({ $0.isNumber }) { return false }
    return token.rangeOfCharacter(from: CharacterSet.letters) != nil
  }

  private static func detectEmotionTags(in text: String) -> [String] {
    var detected: [String] = []
    for rule in emotionRules {
      if rule.keywords.contains(where: { text.localizedCaseInsensitiveContains($0) }) {
        detected.append(rule.tag)
      }
    }
    return detected
  }

  private static func orderedUnique(_ values: [String]) -> [String] {
    var seen: Set<String> = []
    var result: [String] = []
    for value in values where !seen.contains(value) {
      seen.insert(value)
      result.append(value)
    }
    return result
  }

  private static func jaccardSimilarity(_ lhs: Set<String>, _ rhs: Set<String>) -> Double {
    guard !(lhs.isEmpty && rhs.isEmpty) else { return 1.0 }
    let intersection = lhs.intersection(rhs).count
    let union = lhs.union(rhs).count
    guard union > 0 else { return 0.0 }
    return Double(intersection) / Double(union)
  }

  private static func normalize(_ text: String) -> String {
    text
      .replacingOccurrences(of: "\n", with: " ")
      .replacingOccurrences(of: "\t", with: " ")
      .components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
      .joined(separator: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private static func stripTrailingPunctuation(from text: String) -> String {
    text.trimmingCharacters(in: CharacterSet(charactersIn: ".!?。！？ ").union(.whitespacesAndNewlines))
  }

  private static func clipped(_ text: String, limit: Int) -> String {
    guard text.count > limit else { return text }
    return String(text.prefix(limit)) + "..."
  }

  private static func containsAny(_ source: String, _ targets: [String]) -> Bool {
    targets.contains { source.localizedCaseInsensitiveContains($0) }
  }
}
