
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
    
    private var userZones: [Zone] = []
    private var lastZoneStatuses: [UUID: Bool] = [:] // Tracks whether user was in each zone


    @Published var userLocation: CLLocation?
    
    private override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.checkLocationAuthorization()
        self.locationManager.distanceFilter = 10 // Update location every 10 meters
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
    
    private func fetchUserZones() async {
        await fdm.fetchCurrentUserProfile()
        guard let currentUser = fdm.currentUser else { return }
        self.userZones = currentUser.zones
        
        // Initialize lastZoneStatuses
        for zone in userZones {
            lastZoneStatuses[zone.id] = isUserInZone(zone: zone, location: userLocation)
        }
    }
    
    private func checkZoneBoundaries(for location: CLLocation) {
        for zone in userZones {
            let wasInZone = lastZoneStatuses[zone.id] ?? false
            let isInZone = isUserInZone(zone: zone, location: location)
            
            if wasInZone && !isInZone {
                // User has left the zone
                Task {
                    await userLeftZone(zone, at: location.timestamp)
                }
            }
            
            lastZoneStatuses[zone.id] = isInZone
        }
    }
    
    private func isUserInZone(zone: Zone, location: CLLocation?) -> Bool {
        guard let location = location else { return false }
        let zoneCenter = CLLocation(latitude: zone.latitude, longitude: zone.longitude)
        return location.distance(from: zoneCenter) <= zone.radius
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
        Task {
            while true {
                await fetchUserZones()
                try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000) // Refresh every 5 minutes
            }
        }
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
