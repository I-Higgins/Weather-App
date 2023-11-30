//
//  Weather_AppApp.swift
//  Weather App
//
//  Created by Isaac Higgins on 29/11/23.
//

import SwiftUI

@main
struct Weather_AppApp: App {
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) {
                    if (scenePhase == .active) {
                        LocationViewModel.shared.checkLocationServicesIsEnabled()
                        LocationViewModel.shared.checkLocationAuthorization()
                    }
                }
                .onChange(of: LocationManager.shared.userLocation) {
                    guard let lat = LocationManager.shared.userLocation?.coordinate.latitude.magnitude else { return }
                    guard let long = LocationManager.shared.userLocation?.coordinate.longitude.magnitude else { return }
                    WeatherApiClient.shared.RetrieveWeatherData(lat: lat,
                                             long: long) { _ in }
                }
        }
    }
}
