//
//  WeatherApiClient.swift
//  Weather App
//
//  Created by Isaac Higgins on 29/11/23.
//

import SwiftUI
import CoreLocation

enum NetworkError: Error {
    case invalidURL
    case noData
    case invalidData
    case decodingError
    case invalidResponse
    case invalidToken
}

final class WeatherApiClient: ObservableObject {
    @Published var weatherData: WeatherData?
    static let shared = WeatherApiClient()
    
    func RetrieveWeatherData(lat: Double, long: Double, completion: @escaping (Result<WeatherData, NetworkError>) -> Void) {
        var request = URLRequest(url: URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(long)&current=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=Australia%2FSydney")!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                DispatchQueue.main.async {
                    self.weatherData = weatherData
                }
                completion(.success(weatherData))
            } catch {
                completion(.failure(.decodingError))
            }
        }.resume()
    }
    
    
}

struct WeatherDay {
    var dayOfTheWeek: String = "???"
    var temperatureLow: Float = 0
    var temperatureHigh: Float = 0
    var currentTemperature: Float = 0
    var weatherIconName: String = "questionmark"
    
    func getAverageTemp() -> String {
        return String(format: "%.1f", ((temperatureHigh + temperatureLow) / 2))
    }
}

struct WeatherData: Codable {
    var latitude: Float
    var longitude: Float
    var generationtime_ms: Float
    var utc_offset_seconds: Int
    var timezone: String
    var timezone_abbreviation: String
    var elevation: Int
    var current_units: CurrentUnits
    var current: Current
    var daily_units: DailyUnits
    var daily: Daily
    
    func getCurrentWeatherDay() -> WeatherDay {
        return WeatherDay(dayOfTheWeek: self.getWeekdayText(self.daily.time[0]),
                          currentTemperature: self.current.temperature_2m,
                          weatherIconName: self.getWeatherIconName(self.current.weather_code))
    }
    
    func getWeatherDay(daysfromToday: Int) -> WeatherDay {
        if (daysfromToday < 0
            || daysfromToday > 5
            || daysfromToday >= self.daily.time.count) {
            return WeatherDay()
        }
        return WeatherDay(dayOfTheWeek: daysfromToday == 0 ? "Today" : self.getWeekdayText(self.daily.time[daysfromToday]),
                          temperatureLow: self.daily.temperature_2m_min[daysfromToday],
                          temperatureHigh: self.daily.temperature_2m_max[daysfromToday],
                          weatherIconName: self.getWeatherIconName(self.daily.weather_code[daysfromToday]))
    }
    
    func getWeatherIconName(_ weatherCode: Int) -> String {
        switch weatherCode {
        case 0, 1:
            return "sun.max.fill"
        case 2:
            return "cloud.sun.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53:
            return "cloud.drizzle.fill"
        case 55, 61:
            return "cloud.rain.fill"
        case 63, 65, 80, 81, 82:
            return "cloud.heavyrain.fill"
        case 56, 57, 66, 67:
            return "cloud.hail.fill"
        case 71, 73, 75, 77, 85, 86:
            return "cloud.snow.fill"
        case 95, 96, 99:
            return "cloud.bolt.fill"
        default:
            return "questionmark"
        }
    }
    
    func getWeekdayText(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_AU")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: dateString) else { return "???" }
        
        dateFormatter.dateFormat = "EEE"
        return dateFormatter.string(from: date)
    }
}

struct CurrentUnits: Codable {
    var time: String
    var interval: String
    var temperature_2m: String
    var weather_code: String
}

struct Current: Codable {
    var time: String
    var interval: Int
    var temperature_2m: Float
    var weather_code: Int
}

struct DailyUnits: Codable {
    var time: String
    var weather_code: String
    var temperature_2m_max: String
    var temperature_2m_min: String
}

struct Daily: Codable {
    var time: [String]
    var weather_code: [Int]
    var temperature_2m_max: [Float]
    var temperature_2m_min: [Float]
}



final class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager ()
    @Published var userLocation: CLLocation?
    @Published var userLocationName: String = "???"
    @Published var showPermissionsAlert = false
    @Published var permissionsError: LocationAlert.LocationErrorType?
    static let shared = LocationManager()
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
    }
    
    func requestLocationAuthorisation() {
        manager.requestWhenInUseAuthorization()
    }
    
    func GetSuburb(completionHandler: @escaping (String)->Void) {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: self.userLocation?.coordinate.latitude ?? 0,
                                                       longitude: self.userLocation?.coordinate.longitude ?? 0)) {(placemarks, error) in
            if error == nil {
                let placemark = placemarks?[0] ?? CLPlacemark(coder: NSCoder())
                let city = placemark?.locality ?? ""
                let state = placemark?.administrativeArea ?? ""
                DispatchQueue.main.async {
                    self.userLocationName = "\(city), \(state)"
                }
                completionHandler("\(city), \(state)")
            }
            else {
             // An error occurred during geocoding.
                completionHandler("")
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self.manager.requestWhenInUseAuthorization()
        case .restricted:
            self.permissionsError = LocationAlert.LocationErrorType(error: .locationRestricted)
            self.showPermissionsAlert = true
        case .denied:
            self.permissionsError = LocationAlert.LocationErrorType(error: .locationDenied)
            self.showPermissionsAlert = true
        case .authorizedAlways, .authorizedWhenInUse:
            self.userLocation = self.manager.location
            self.GetSuburb() { _ in }
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdatelocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location
        guard let lat = self.userLocation?.coordinate.latitude.magnitude else { return }
        guard let long = self.userLocation?.coordinate.longitude.magnitude else { return }
        WeatherApiClient.shared.RetrieveWeatherData(lat: lat,
                                 long: long) { _ in }
    }
}
