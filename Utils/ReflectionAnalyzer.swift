import Foundation

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
    ("기쁨", ["행복", "기쁨", "웃", "설렘", "뿌듯", "즐거"]),
    ("감사", ["감사", "고마", "든든", "따뜻"]),
    ("피로", ["피곤", "지침", "지쳤", "무기력", "졸림"]),
    ("불안", ["불안", "걱정", "초조", "긴장", "압박", "부담", "비용", "비싼", "언제", "출시"]),
    ("분노", ["화", "짜증", "분노", "답답", "억울", "멍청", "구려", "빡침"]),
    ("슬픔", ["슬픔", "우울", "눈물", "외롭", "허무"]),
    ("집중", ["몰입", "집중", "성취", "해냈", "완료"])
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
    let cleaned = content
      .replacingOccurrences(of: "\n", with: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    let sentences = cleaned
      .components(separatedBy: CharacterSet(charactersIn: ".!?。！？"))
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    var detected: [String] = []
    for rule in emotionRules {
      if rule.keywords.contains(where: { cleaned.localizedCaseInsensitiveContains($0) }) {
        detected.append(rule.tag)
      }
    }

    if let mood, let moodTag = moodTag(from: mood) {
      detected.append(moodTag)
    }

    let uniqueTags = Array(NSOrderedSet(array: detected)) as? [String] ?? []
    let summary = buildSummary(sentences: sentences, emotionTags: uniqueTags)

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

  private static func buildSummary(sentences: [String], emotionTags: [String]) -> String {
    if sentences.isEmpty {
      return "1. 핵심 이슈: 기록 내용이 짧아 핵심 이슈를 특정하기 어려움\n2. 상황 맥락: 오늘 있었던 구체적인 장면이 더 필요함\n3. 감정 흐름: 감정 단서가 충분하지 않음"
    }

    let issueSentence = primaryIssueSentence(from: sentences)
    let issue = issueSummary(from: sentences, primary: issueSentence)
    let context = contextSentence(from: sentences, excluding: issueSentence)
    let emotion = inferredEmotionLine(from: emotionTags, sentences: sentences)

    return [
      "1. 핵심 이슈: \(issue)",
      "2. 상황 맥락: \(clipped(context, limit: 46))",
      "3. 감정 흐름: \(emotion)"
    ].joined(separator: "\n")
  }

  private static func primaryIssueSentence(from sentences: [String]) -> String {
    let issueKeywords = ["왜", "문제", "한계", "성능", "오류", "실패", "멍청", "구려", "안됨", "안돼"]

    let scored = sentences.map { sentence -> (sentence: String, score: Int) in
      let score = issueKeywords.reduce(0) { partial, token in
        partial + (sentence.localizedCaseInsensitiveContains(token) ? 1 : 0)
      }
      return (sentence, score)
    }
    .sorted { $0.score > $1.score }

    return scored.first?.sentence ?? sentences[0]
  }

  private static func contextSentence(from sentences: [String], excluding primary: String) -> String {
    let joined = sentences.joined(separator: " ")
    var themes: [String] = []

    if containsAny(joined, ["요약", "상황", "맥락", "문장"]) {
      themes.append("요약 방식의 정확도 점검")
    }
    if containsAny(joined, ["온디바이스", "업데이트", "성능", "애플"]) {
      themes.append("온디바이스 성능 변화 관찰")
    }
    if containsAny(joined, ["토큰", "비용", "비싼", "녹아", "과금"]) {
      themes.append("개발 비용 부담")
    }
    if containsAny(joined, ["코덱스", "앱", "개발", "출시"]) {
      themes.append("앱 개발 진행 상황")
    }

    let uniqueThemes = Array(NSOrderedSet(array: themes)) as? [String] ?? []
    if uniqueThemes.count >= 2 {
      return "\(uniqueThemes[0])과 \(uniqueThemes[1])이 함께 언급됨"
    }
    if let first = uniqueThemes.first {
      return first
    }
    if primary.localizedCaseInsensitiveContains("테스트") {
      return "테스트를 반복하며 업데이트 전후 변화를 비교함"
    }
    return "기록된 내용을 바탕으로 원인과 흐름을 점검함"
  }

  private static func issueSummary(from sentences: [String], primary: String) -> String {
    let joined = sentences.joined(separator: " ")

    if containsAny(joined, ["요약", "상황", "맥락", "문장"]) &&
      containsAny(joined, ["온디바이스", "업데이트", "성능"]) {
      return "요약 품질과 온디바이스 성능 저하 원인을 점검하는 문제"
    }
    if containsAny(joined, ["요약", "정리", "문장"]) {
      return "요약 결과의 정확도와 표현 방식 개선 필요"
    }
    if containsAny(joined, ["온디바이스", "업데이트", "성능", "한계"]) {
      return "업데이트 이후 온디바이스 성능 변화를 검증할 필요"
    }
    if containsAny(joined, ["비용", "토큰", "과금", "비싼"]) {
      return "개발 비용과 품질 사이의 균형이 핵심 과제"
    }
    if containsAny(joined, ["출시", "언제", "일정"]) {
      return "개발 진행 속도와 출시 일정 불확실성 해소 필요"
    }

    return "기록에서 드러난 핵심 이슈를 구조적으로 점검할 필요"
  }

  private static func inferredEmotionLine(from emotionTags: [String], sentences: [String]) -> String {
    if let first = emotionTags.first {
      return first
    }

    let joined = sentences.joined(separator: " ")
    let frustrationHints = ["왜", "답답", "멍청", "구려", "화", "짜증", "억울"]
    let anxietyHints = ["걱정", "불안", "초조", "긴장", "비용", "비싼", "압박", "출시", "언제"]

    if frustrationHints.contains(where: { joined.localizedCaseInsensitiveContains($0) }) {
      return "답답함과 의문이 함께 나타남"
    }
    if anxietyHints.contains(where: { joined.localizedCaseInsensitiveContains($0) }) {
      return "불안과 걱정이 함께 나타남"
    }
    return "감정 표현이 비교적 중립적임"
  }

  private static func clipped(_ text: String, limit: Int) -> String {
    guard text.count > limit else { return text }
    return String(text.prefix(limit)) + "..."
  }

  private static func containsAny(_ source: String, _ targets: [String]) -> Bool {
    targets.contains { source.localizedCaseInsensitiveContains($0) }
  }
}
