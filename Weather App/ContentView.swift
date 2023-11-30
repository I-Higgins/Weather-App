//
//  ContentView.swift
//  Weather App
//
//  Created by Isaac Higgins on 29/11/23.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var weatherClient = WeatherApiClient.shared
    @ObservedObject var locationManager = LocationManager.shared
    var body: some View {
        ZStack {
            BackgroundView(darkMode: colorScheme == .dark)
            VStack {
                MainWeatherView(weatherDay: weatherClient.weatherData?.getCurrentWeatherDay() ?? WeatherDay(), cityName: locationManager.userLocationName)
                
                HStack(spacing: 20) {
                    WeatherDayView(weatherDay: weatherClient.weatherData?.getWeatherDay(daysfromToday: 0) ?? WeatherDay())
                    WeatherDayView(weatherDay: weatherClient.weatherData?.getWeatherDay(daysfromToday: 1) ?? WeatherDay())
                    WeatherDayView(weatherDay: weatherClient.weatherData?.getWeatherDay(daysfromToday: 2) ?? WeatherDay())
                    WeatherDayView(weatherDay: weatherClient.weatherData?.getWeatherDay(daysfromToday: 3) ?? WeatherDay())
                    WeatherDayView(weatherDay: weatherClient.weatherData?.getWeatherDay(daysfromToday: 4) ?? WeatherDay())
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            if LocationManager.shared.userLocation == nil {
                LocationManager.shared.requestLocationAuthorisation()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WeatherApiClient())
}

struct WeatherDayView: View {
    var weatherDay: WeatherDay
    
    var body: some View {
        VStack {
            WhiteText(weatherDay.dayOfTheWeek, size: 16)
            
            Image(systemName: weatherDay.weatherIconName)
                .symbolRenderingMode(.multicolor)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
            
            HStack {
                VStack {
                    Image(systemName: "thermometer.high")
                        .symbolRenderingMode(.multicolor)
                    Image(systemName: "thermometer.low")
                        .symbolRenderingMode(.multicolor)
                }
                VStack {
                    WhiteText("\(String(format: "%.0f", weatherDay.temperatureHigh))°", size: 20)
                    WhiteText("\(String(format: "%.0f", weatherDay.temperatureLow))°", size: 20)
                    
                }
            }
        }
    }
}

struct BackgroundView: View {
    var darkMode: Bool
    var body: some View {
        
        ContainerRelativeShape()
            .fill(darkMode ? Color.black.gradient : Color.blue.gradient)
            .ignoresSafeArea(.all)
    }
}

struct MainWeatherView: View {
    var weatherDay: WeatherDay
    var cityName: String
    var body: some View {
        VStack(spacing: 14) {
            WhiteText(cityName, size: 32)
                .padding()
            Image(systemName: weatherDay.weatherIconName)
                .symbolRenderingMode(.multicolor)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            
            WhiteText("\(weatherDay.currentTemperature)°", size: 70)
        }
        .padding(.bottom, 80)
    }
}


final class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var showPermissionsAlert = false
    @Published var permissionsError: LocationAlert.LocationErrorType?
    static var shared = LocationViewModel()
    var locationManager: CLLocationManager?
    var location: CLLocation?
     
    func checkLocationServicesIsEnabled() {
        DispatchQueue.global().async { [weak self] in
            if CLLocationManager.locationServicesEnabled() {
                self?.locationManager = CLLocationManager()
                self?.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
                self?.locationManager!.delegate = self
            } else {
                self?.permissionsError = LocationAlert.LocationErrorType(error: .locationServicesDisabled)
                self?.showPermissionsAlert = true
            }
        }
    }
    
    func checkLocationAuthorization() {
        guard let locationManager = locationManager else { return }
        print(locationManager.authorizationStatus)
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            permissionsError = LocationAlert.LocationErrorType(error: .locationRestricted)
            showPermissionsAlert = true
        case .denied:
            permissionsError = LocationAlert.LocationErrorType(error: .locationDenied)
            showPermissionsAlert = true
        case .authorizedAlways, .authorizedWhenInUse:
            location = locationManager.location
            break
        @unknown default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}

enum LocationAlert {
    enum LocationError: Error, LocalizedError {
        case none
        case locationDenied
        case locationRestricted
        case locationServicesDisabled
        
        var errorDescription: String? {
            switch self {
            case .none:
                return NSLocalizedString("", comment: "")
            case .locationDenied:
                return NSLocalizedString("Location services are disabled. Please enable \"while using\" in settings", comment: "")
            case .locationRestricted:
                return NSLocalizedString("You are not allowed to access location services", comment: "")
            case .locationServicesDisabled:
                return NSLocalizedString("EIS Staff app does not have access to your Location. Tap \"Settings\" to enable Location access", comment: "")
            }
        }
    }
    
    struct LocationErrorType {
        let error: LocationError
        var message: String
        var button: Button = Button("") {}
        init(error: LocationError) {
            self.error = error
            self.message = error.localizedDescription
            self.button = Button("Settings", role: .cancel) {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            }
        }
    }
}
