import Foundation
import CoreLocation
import Combine

@MainActor
class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
  let objectWillChange = ObservableObjectPublisher()

    // 구역: 설정
    // 할 일: 실제 오픈웨더맵 에이피아이 키로 교체
    static let apiKey = "YOUR_OPENWEATHERMAP_API_KEY"
    static let shared = WeatherService()
    
    private let locationManager = CLLocationManager()
    
    // 델리게이트 콜백을 비동기 흐름으로 연결
    private var weatherContinuation: CheckedContinuation<WeatherType, Never>?
    
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
        // 필요 시 권한 요청
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        // 권한이 없으면 기본값(맑음) 반환
        guard locationManager.authorizationStatus == .authorizedWhenInUse || 
              locationManager.authorizationStatus == .authorizedAlways else {
             if locationManager.authorizationStatus == .notDetermined {
                 // 대기
             } else {
                 return .sunny
             }
             return .sunny // 폴백
        }

        return await withCheckedContinuation { continuation in
            // 이전 요청 취소
            if let existing = weatherContinuation {
                existing.resume(returning: .sunny)
            }
            
            weatherContinuation = continuation
            locationManager.requestLocation()
        }
    }
    
    // 구역: 위치 델리게이트
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.first else {
                self.resume(with: .sunny)
                return
            }
            let weather = await self.fetchWeather(for: location)
            self.resume(with: weather)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("Location error: \(error.localizedDescription)")
            self.resume(with: .sunny) // 폴백
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
        
        guard let url = URL(string: urlString) else { return .sunny }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(WeatherResponse.self, from: data)
            
            if let firstWeather = decoded.weather.first {
                return mapIDToWeatherType(id: firstWeather.id)
            }
        } catch {
            print("Weather fetch error: \(error)")
        }
        
        return .sunny
    }
    
    private func mapIDToWeatherType(id: Int) -> WeatherType {
        // 오픈웨더맵 아이디 매핑
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

