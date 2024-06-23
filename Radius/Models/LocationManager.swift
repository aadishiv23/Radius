
//  LocationManager.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/6/24.

import CoreLocation
import Supabase

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private var locationManager = CLLocationManager()
    private var lastUploadedLocation: CLLocation?
    private let locationUpdateInterval: TimeInterval = 60 // Set the interval to 60 seconds
    private let minimumDistance: CLLocationDistance = 50 // Set the minimum distance to 50 meters
    private let fdm = FriendsDataManager(supabaseClient: supabase)
    


    @Published var userLocation: CLLocation?
    
    private override init() {
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
        guard let newLocation = locations.last else { return }
        
        self.userLocation = newLocation
        if shouldUploadLocation(newLocation) {
            uploadLocation(newLocation)
        }
        
        checkZoneBoundaries(for: newLocation)
    }
    
    private func checkZoneBoundaries(for location: CLLocation) {
        Task {
            await fdm.fetchCurrentUserProfile()
            guard let currentUser = fdm.currentUser else { return }
            
            for zone in currentUser.zones {
                let zoneCenter = CLLocation(latitude: zone.latitude, longitude: zone.longitude)
                   if location.distance(from: zoneCenter) > zone.radius {
                       // User has left the zone
                      // userLeftZone(zone, at: location.timestamp)
                       break
                       //await userLeftZone(zone, at: location.timestamp)
                   }
            }
        }
    }
    
    private func userLeftZone(_ zone: Zone, at time: Date) async {
       do {
           let zoneExit = [
            "profile_id": fdm.currentUser?.id.uuidString ?? "",
               "zone_id": zone.id.uuidString,
               "exit_time": ISO8601DateFormatter().string(from: time)
           ]
           
           try await supabase
               .from("zone_exits")
               .insert(zoneExit)
               .execute()
           
           print("Zone exit recorded successfully")
       } catch {
           print("Failed to record zone exit: \(error)")
       }
   }
    
    private func shouldUploadLocation(_ newLocation: CLLocation) -> Bool {
        guard let lastLocation = lastUploadedLocation else {
            return true
        }
        
        let timeInterval = newLocation.timestamp.timeIntervalSince(lastLocation.timestamp)
        let distance = newLocation.distance(from: lastLocation)
        return timeInterval >= locationUpdateInterval || distance >= minimumDistance
    }
    
    private func uploadLocation(_ newLocation: CLLocation) {
        let locationArr = [
            "latitude": newLocation.coordinate.latitude,
            "longitude": newLocation.coordinate.longitude
        ]
        Task {
            do {
                await fdm.fetchCurrentUserProfile()
                try await supabase
                    .from("profiles")
                    .update(locationArr)
                    .eq("id", value: fdm.currentUser?.id.uuidString)
                    .execute()
                
                DispatchQueue.main.async {
                    self.lastUploadedLocation = newLocation
                }
            } catch {
                print("Failed to update location: \(error)")
            }
        }
    }
    
    func plsInitiateLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
    
    func startUpdatingLocation() {
       locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
       locationManager.stopUpdatingLocation()
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
