import Foundation
import CoreLocation
import Combine

@MainActor
class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
  let objectWillChange = ObservableObjectPublisher()

  // Xcode > Build Settings > INFOPLIST_KEY_OPENWEATHER_API_KEY 에 키를 설정하세요.
  // 키가 없으면 날씨 기능이 비활성화됩니다.
  static let apiKey: String = {
    Bundle.main.infoDictionary?["OPENWEATHER_API_KEY"] as? String ?? ""
  }()
  static let shared = WeatherService()

  // 날씨 조회 에러 상태 — DiaryEditorView에서 observe
  @Published var fetchError: WeatherFetchError?

  private let locationManager = CLLocationManager()

  // 델리게이트 콜백을 비동기 흐름으로 연결
  private var weatherContinuation: CheckedContinuation<WeatherType, Never>?

  enum WeatherFetchError: LocalizedError {
    case locationDenied
    case apiKeyMissing
    case networkError(Error)

    var errorDescription: String? {
      switch self {
      case .locationDenied:
        return "위치 권한이 없어 날씨를 불러올 수 없습니다. 설정 앱에서 위치 접근을 허용해 주세요."
      case .apiKeyMissing:
        return "날씨 API 키가 설정되지 않았습니다."
      case .networkError:
        return "날씨 정보를 불러오지 못했습니다. 인터넷 연결을 확인해 주세요."
      }
    }
  }

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
  }

  enum WeatherType: String, CaseIterable, Codable {
    case sunny = "sun.max.fill"
    case cloudy = "cloud.fill"
    case rain = "cloud.rain.fill"
    case snow = "cloud.snow.fill"
    case lightning = "cloud.bolt.fill"
    case unknown = "questionmark.circle"

    var description: String {
      switch self {
      case .sunny: return "맑음"
      case .cloudy: return "흐림"
      case .rain: return "비"
      case .snow: return "눈"
      case .lightning: return "번개"
      case .unknown: return "알 수 없음"
      }
    }
  }

  // 오픈웨더맵 응답 모델
  struct WeatherResponse: Codable {
    let weather: [WeatherParams]
  }

  struct WeatherParams: Codable {
    let id: Int
    let main: String
  }

  func fetchCurrentWeather() async -> WeatherType {
    fetchError = nil

    // API 키 없으면 에러 상태 설정 후 반환
    guard !WeatherService.apiKey.isEmpty else {
      fetchError = .apiKeyMissing
      return .unknown
    }

    // 권한 요청
    if locationManager.authorizationStatus == .notDetermined {
      locationManager.requestWhenInUseAuthorization()
    }

    // 위치 권한 없으면 에러 상태 설정
    guard locationManager.authorizationStatus == .authorizedWhenInUse ||
          locationManager.authorizationStatus == .authorizedAlways else {
      if locationManager.authorizationStatus != .notDetermined {
        fetchError = .locationDenied
      }
      return .unknown
    }

    return await withCheckedContinuation { continuation in
      if let existing = weatherContinuation {
        existing.resume(returning: .unknown)
      }
      weatherContinuation = continuation
      locationManager.requestLocation()
    }
  }

  // MARK: - 위치 델리게이트

  nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    Task { @MainActor in
      guard let location = locations.first else {
        self.resume(with: .unknown)
        return
      }
      let weather = await self.fetchWeather(for: location)
      self.resume(with: weather)
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    Task { @MainActor in
      self.fetchError = .networkError(error)
      self.resume(with: .unknown)
    }
  }

  private func resume(with weather: WeatherType) {
    weatherContinuation?.resume(returning: weather)
    weatherContinuation = nil
  }

  private func fetchWeather(for location: CLLocation) async -> WeatherType {
    let lat = location.coordinate.latitude
    let lon = location.coordinate.longitude
    let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(WeatherService.apiKey)"

    guard let url = URL(string: urlString) else { return .unknown }

    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      let decoded = try JSONDecoder().decode(WeatherResponse.self, from: data)
      if let firstWeather = decoded.weather.first {
        return mapWeatherID(id: firstWeather.id)
      }
    } catch {
      fetchError = .networkError(error)
    }

    return .unknown
  }

  // internal — 단위 테스트에서 접근 가능
  func mapWeatherID(id: Int) -> WeatherType {
    switch id {
    case 200...232: return .lightning
    case 300...531: return .rain
    case 600...622: return .snow
    case 800: return .sunny
    case 801...804: return .cloudy
    default: return .sunny
    }
  }
}
