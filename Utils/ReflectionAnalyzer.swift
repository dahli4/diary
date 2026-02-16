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
    ("분노", ["화", "짜증", "분노", "답답", "억울", "빡침", "멍청", "구려"]),
    ("슬픔", ["슬픔", "우울", "눈물", "외롭", "허무"]),
    ("집중", ["몰입", "집중", "성취", "해냈", "완료"])
  ]

  private static let stopwords: Set<String> = [
    "그리고", "그러나", "하지만", "그래서", "그런데", "정말", "진짜", "그냥", "너무", "조금",
    "오늘", "어제", "내일", "지금", "이제", "이거", "저거", "그거", "내용", "부분", "상황",
    "문제", "생각", "기분", "때문", "관련", "대한", "위해", "에서", "으로", "에게", "했다", "하는"
  ]

  private static let issueHints = ["왜", "문제", "한계", "성능", "오류", "실패", "안됨", "안돼", "부담"]

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
      return ReflectionAnalysis(summary: "오늘 기록이 짧아 핵심 요약을 만들기 어려움", emotionTags: [])
    }

    let sentences = extractSentences(from: cleaned)
    let main = pickMainSentence(from: sentences, source: cleaned)
    let context = pickContextSentence(from: sentences, excluding: main)

    var detected = detectEmotionTags(in: cleaned)
    if let mood, let moodTag = moodTag(from: mood) {
      detected.append(moodTag)
    }
    let uniqueTags = orderedUnique(detected)

    let summary = buildOneLineSummary(main: main, context: context, emotionTag: uniqueTags.first)
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

  private static func buildOneLineSummary(main: String, context: String?, emotionTag: String?) -> String {
    var line = clipped(main, limit: 72)

    if let context, !context.isEmpty {
      line += "; " + clipped(context, limit: 46)
    }

    if let emotionTag, !emotionTag.isEmpty {
      line += " (\(emotionTag))"
    }

    return normalizedSummaryLine(line)
  }

  private static func pickMainSentence(from sentences: [String], source: String) -> String {
    guard !sentences.isEmpty else { return source }
    let frequencies = tokenFrequency(from: source)

    let ranked = sentences.map { sentence -> (sentence: String, score: Double) in
      let tokens = wordTokens(from: sentence)
      let keywordScore = tokens.reduce(0.0) { partial, token in
        partial + Double(frequencies[token] ?? 0)
      }
      let uniqueBonus = tokens.isEmpty ? 0.0 : Double(Set(tokens).count) / Double(tokens.count)
      let hintBonus = issueHints.contains(where: { sentence.localizedCaseInsensitiveContains($0) }) ? 1.2 : 0.0
      let lengthBonus = (sentence.count >= 14 && sentence.count <= 90) ? 0.2 : -0.1
      return (sentence, keywordScore + uniqueBonus + hintBonus + lengthBonus)
    }
    .sorted { $0.score > $1.score }

    return ranked.first?.sentence ?? sentences[0]
  }

  private static func pickContextSentence(from sentences: [String], excluding main: String) -> String? {
    guard sentences.count > 1 else { return nil }
    let mainTokenSet = Set(wordTokens(from: main))

    for sentence in sentences where sentence != main {
      let candidateSet = Set(wordTokens(from: sentence))
      if jaccard(mainTokenSet, candidateSet) < 0.72 {
        return sentence
      }
    }

    return sentences.first(where: { $0 != main })
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

  private static func extractSentences(from text: String) -> [String] {
    var sentences: [String] = []
    let tokenizer = NLTokenizer(unit: .sentence)
    tokenizer.string = text

    tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
      let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
      let cleaned = stripTrailingPunctuation(sentence)
      if !cleaned.isEmpty {
        sentences.append(cleaned)
      }
      return true
    }

    if !sentences.isEmpty { return sentences }

    return text
      .components(separatedBy: CharacterSet(charactersIn: ".!?。！？\n"))
      .map { stripTrailingPunctuation($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
      .filter { !$0.isEmpty }
  }

  private static func tokenFrequency(from text: String) -> [String: Int] {
    var result: [String: Int] = [:]
    for token in wordTokens(from: text) {
      result[token, default: 0] += 1
    }
    return result
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

  private static func orderedUnique(_ values: [String]) -> [String] {
    var seen: Set<String> = []
    var result: [String] = []
    for value in values where !seen.contains(value) {
      seen.insert(value)
      result.append(value)
    }
    return result
  }

  private static func jaccard(_ lhs: Set<String>, _ rhs: Set<String>) -> Double {
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

  private static func stripTrailingPunctuation(_ text: String) -> String {
    text.trimmingCharacters(in: CharacterSet(charactersIn: ".!?。！？ ").union(.whitespacesAndNewlines))
  }

  private static func clipped(_ text: String, limit: Int) -> String {
    guard text.count > limit else { return text }
    return String(text.prefix(limit)) + "..."
  }

  private static func normalizedSummaryLine(_ text: String) -> String {
    let compact = text
      .replacingOccurrences(of: "\n", with: " ")
      .components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
      .joined(separator: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    if compact.hasSuffix(".") || compact.hasSuffix("!") || compact.hasSuffix("?") {
      return compact
    }
    return compact + "."
  }
}
