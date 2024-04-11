//
//  LocationManager.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/6/24.
//
//import CoreLocation
//
//class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
//    private var locationManager = CLLocationManager()
//    @Published var userLocation: CLLocation?
//
//    override init() {
//        super.init()
//        self.locationManager.delegate = self
//        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        checkLocationAuthorization()
//    }
//    
//    func checkLocationAuthorization() {
//        switch locationManager.authorizationStatus {
//            case .notDetermined:
//                locationManager.requestWhenInUseAuthorization()
//            case .restricted, .denied:
//                break // Handle case where user has denied/restricted location usage
//            case .authorizedWhenInUse:
//                locationManager.requestAlwaysAuthorization()
//            case .authorizedAlways:
//                locationManager.startUpdatingLocation()
//            @unknown default:
//                break
//        }
//    }
//
//    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        checkLocationAuthorization()
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        self.userLocation = locations.last
//    }
//}
