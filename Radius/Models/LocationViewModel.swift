//
//  LocationViewModel.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/25/24.
//

import Foundation
import MapKit

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40, longitude: -120),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func checkIfLocationServicesIsEnabled() {
        locationManager.requestWhenInUseAuthorization()
    }

    func plsInitiateLocationUpdates() {
        locationManager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }

    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                // Alert the user that they have denied/restricted location usage
                break
            case .authorizedWhenInUse, .authorizedAlways:
                locationManager.startUpdatingLocation()
            @unknown default:
                break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.first else { return }
        DispatchQueue.main.async {
            self.userLocation = latestLocation
            self.updateRegion(center: latestLocation.coordinate)
        }
    }

    func updateRegion(center: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
