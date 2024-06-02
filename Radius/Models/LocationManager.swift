
//  LocationManager.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/6/24.

import CoreLocation
import Supabase

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    private let supabaseClient = supabase
    private let userId: UUID
    private var lastUploadedLocation: CLLocation?
    private let locationUpdateInterval: TimeInterval = 60 // Set the interval to 60 seconds
    private let minimumDistance: CLLocationDistance = 50 // Set the minimum distance to 50 meters

    @Published var userLocation: CLLocation?
    
    init(supabaseClient: SupabaseClient, userId: UUID) {
        self.userId = userId
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.checkLocationAuthorization()
    }
    
    func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted, .denied:
            break // Handle case where user has denied/restricted location usage
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.userLocation = locations.last
    }
    
    func plsInitiateLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
}


//class MapRegionObserver: ObservableObject {
//    @Published var showRecenterButton = false
//    private let initialCenter: CLLocationCoordinate2D
//    private var currentCenter: CLLocationCoordinate2D?
//    
//    init(initialCenter: CLLocationCoordinate2D) {
//        self.initialCenter = initialCenter
//    }
//    
//    func updateRegion(_ region: MKCoordinateRegion) {
//        let newCenter = region.center
//        if let currentCenter = currentCenter, currentCenter.distance(from: newCenter) > 500 {
//            showRecenterButton = true
//        } else if newCenter.distance(from: initialCenter) > 500 {
//            showRecenterButton = true
//        } else {
//            showRecenterButton = false
//        }
//        currentCenter = newCenter
//    }
//}
