import Foundation
import CoreLocation
import Combine

@MainActor
class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
  let objectWillChange = ObservableObjectPublisher()

  // Xcode > Build Settings > INFOPLIST_KEY_OPENWEATHER_API_KEY 에 키를 설정하세요.
  static let apiKey: String = {
    Bundle.main.infoDictionary?["OPENWEATHER_API_KEY"] as? String ?? ""
  }()
  static let shared = WeatherService()

  // 사용자에게 보여줄 에러 메시지 (기술 용어 없음)
  @Published var userFacingError: String?

  private let locationManager = CLLocationManager()
  private var weatherContinuation: CheckedContinuation<WeatherType, Never>?

  enum WeatherType: String, CaseIterable, Codable {
    case sunny    = "sun.max.fill"
    case cloudy   = "cloud.fill"
    case rain     = "cloud.rain.fill"
    case snow     = "cloud.snow.fill"
    case lightning = "cloud.bolt.fill"
    case unknown  = "questionmark.circle"

    var description: String {
      switch self {
      case .sunny:     return "맑음"
      case .cloudy:    return "흐림"
      case .rain:      return "비"
      case .snow:      return "눈"
      case .lightning: return "번개"
      case .unknown:   return "알 수 없음"
      }
    }
  }

  struct WeatherResponse: Codable {
    let weather: [WeatherParams]
  }

  struct WeatherParams: Codable {
    let id: Int
    let main: String
  }

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
  }

  func fetchCurrentWeather() async -> WeatherType {
    userFacingError = nil

    // API 키 미설정 → 조용히 무시 (사용자에게 에러 노출 안 함)
    guard !WeatherService.apiKey.isEmpty else {
      return .unknown
    }

    switch locationManager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      // 이미 권한 있으면 바로 위치 조회
      return await requestLocationAndWait()

    case .notDetermined:
      // 권한 요청 → 사용자 응답을 대기 (locationManagerDidChangeAuthorization 델리게이트에서 처리)
      return await withCheckedContinuation { continuation in
        if let existing = weatherContinuation {
          existing.resume(returning: .unknown)
        }
        weatherContinuation = continuation
        locationManager.requestWhenInUseAuthorization()
      }

    case .denied, .restricted:
      userFacingError = "날씨 기능을 사용하려면 설정 앱에서 위치 접근을 허용해 주세요."
      return .unknown

    @unknown default:
      return .unknown
    }
  }

  // MARK: - CLLocationManagerDelegate

  // 권한 응답 수신 → 허용이면 바로 위치 조회 시작
  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    Task { @MainActor in
      switch manager.authorizationStatus {
      case .authorizedWhenInUse, .authorizedAlways:
        if self.weatherContinuation != nil {
          self.locationManager.requestLocation()
        }
      case .denied, .restricted:
        self.userFacingError = "날씨 기능을 사용하려면 설정 앱에서 위치 접근을 허용해 주세요."
        self.resume(with: .unknown)
      case .notDetermined:
        break
      @unknown default:
        self.resume(with: .unknown)
      }
    }
  }

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
      self.userFacingError = "날씨 정보를 가져오지 못했어요. 잠시 후 다시 시도해 주세요."
      self.resume(with: .unknown)
    }
  }

  // MARK: - Private

  private func requestLocationAndWait() async -> WeatherType {
    return await withCheckedContinuation { continuation in
      if let existing = weatherContinuation {
        existing.resume(returning: .unknown)
      }
      weatherContinuation = continuation
      locationManager.requestLocation()
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
      userFacingError = "날씨 정보를 가져오지 못했어요. 잠시 후 다시 시도해 주세요."
    }

    return .unknown
  }

  // internal — 단위 테스트에서 접근 가능
  func mapWeatherID(id: Int) -> WeatherType {
    switch id {
    case 200...232: return .lightning
    case 300...531: return .rain
    case 600...622: return .snow
    case 800:       return .sunny
    case 801...804: return .cloudy
    default:        return .sunny
    }
  }
}
