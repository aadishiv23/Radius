//
//  Friends.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/24/24.
//

import Foundation
import MapKit
import CoreLocation

class FriendData: ObservableObject {
    @Published var friendsLocations: [FriendLocation] = [
        FriendLocation(name: "Alice", color: .red, coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)),
        FriendLocation(name: "Bob", color: .blue, coordinate: CLLocationCoordinate2D(latitude: 40.7158, longitude: -74.0080)),
        FriendLocation(name: "Charlie", color: .green, coordinate: CLLocationCoordinate2D(latitude: 40.7108, longitude: -74.0100)),
        FriendLocation(name: "David", color: .yellow, coordinate: CLLocationCoordinate2D(latitude: 40.7138, longitude: -74.0120))
    ]
}
//
//class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
//    private var locationManager: CLLocationManager?
//    @Published var userLocation: CLLocation?
//
//    func checkIfLocationServicesIsEnabled() {
//        if CLLocationManager.locationServicesEnabled() {
//            locationManager = CLLocationManager()
//            locationManager!.delegate = self
//            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
//            locationManager!.requestWhenInUseAuthorization()
//        } else {
//            print("Location services are not enabled")
//        }
//    }
//
//    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        switch manager.authorizationStatus {
//        case .notDetermined, .restricted, .denied:
//            print("Not authorized to use location services")
//        case .authorizedWhenInUse, .authorizedAlways:
//            locationManager?.startUpdatingLocation()
//        @unknown default:
//            break
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.last else { return }
//        userLocation = location
//    }
//    
//    func plsInitiateLocationUpdates() {
//        locationManager.startUpdatingLocation()
//    }
//}

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