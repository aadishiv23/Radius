
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
    private let locationUpdateInterval: TimeInterval = 60
    private let minimumDistance: CLLocationDistance = 50
    
    let zoneUpdateManager = ZoneUpdateManager(supabaseClient: supabase)  // Add ZoneUpdateManager instance
    private let fdm = FriendsDataManager(supabaseClient: supabase)
    
    @Published var userZones: [Zone] = []
    private var lastZoneStatuses: [UUID: Bool] = [:]
    
    @Published var userLocation: CLLocation?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.checkLocationAuthorization()
        self.locationManager.distanceFilter = 10
        
        Task {
            await fetchUserZones()
        }
    }
    
    func checkIfLocationServicesIsEnabled() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func plsInitiateLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted, .denied:
            break
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
        
        for zone in userZones {
            lastZoneStatuses[zone.id] = isUserInZone(zone: zone, location: userLocation)
        }
    }
    
    private func checkZoneBoundaries(for location: CLLocation) {
        var exitedZones: [UUID] = []
        
        for zone in userZones {
            let wasInZone = lastZoneStatuses[zone.id] ?? false
            let isInZone = isUserInZone(zone: zone, location: location)
            
            if wasInZone && !isInZone {
                exitedZones.append(zone.id)
            }
            
            lastZoneStatuses[zone.id] = isInZone
        }
        
        if !exitedZones.isEmpty {
            handleZoneExits(exitedZones: exitedZones, at: location.timestamp)
        }
    }
    
    private func isUserInZone(zone: Zone, location: CLLocation?) -> Bool {
        guard let location = location else { return false }
        let zoneCenter = CLLocation(latitude: zone.latitude, longitude: zone.longitude)
        return location.distance(from: zoneCenter) <= zone.radius
    }
    
    private func handleZoneExits(exitedZones: [UUID], at time: Date) {
        guard let profileId = fdm.currentUser?.id else { return }
        Task {
            await zoneUpdateManager.handleZoneExits(for: profileId, zoneIds: exitedZones, at: time)
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
