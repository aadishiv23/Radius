
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
    
    let zoneUpdateManager: ZoneUpdateManager  // Add ZoneUpdateManager instance
    private let fdm: FriendsDataManager
    
    @Published var userZones: [Zone] = []
    private var lastZoneStatuses: [UUID: Bool] = [:]
    
    @Published var userLocation: CLLocation?
    
    override init() {
        self.zoneUpdateManager = ZoneUpdateManager(supabaseClient: supabase)
        self.fdm = FriendsDataManager(supabaseClient: supabase)
        
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.checkLocationAuthorization()
        self.locationManager.distanceFilter = 10
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        
        Task {
            await fetchUserZones()
        }
    }
    
    func checkIfLocationServicesIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            checkLocationAuthorization()
        } else {
            print("Location services are disabled")
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func plsInitiateLocationUpdates() {
        locationManager.startUpdatingLocation()
        setupGeofences()
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            setupGeofences()
        case .restricted, .denied:
            break
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
            setupGeofences()
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            setupGeofences()
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
        setupGeofences()
    }
    
    func setupGeofences() {
        // Removes all prexisting monitoring zones
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        
        // Set-up geofences for zones
        for zone in userZones {
            let center = CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude)
            let region = CLCircularRegion(center: center, radius: zone.radius, identifier: zone.id.uuidString)
            region.notifyOnExit = true
            locationManager.startMonitoring(for: region)
        }
    }
    
    func stopLocationUpdates() {
            locationManager.stopUpdatingLocation()
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
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

struct LocalZoneExit: Identifiable {
    let id = UUID()
    let zoneName: String
    let exitTime: Date
    let latitude: Double
    let longitude: Double
}

extension Notification.Name {
    static let zoneExited = Notification.Name("zoneExited")
}

extension LocationManager {
    private func notifyZoneExit(zone: Zone, location: CLLocation) {
        let localZoneExit = LocalZoneExit(
            zoneName: zone.name,
            exitTime: Date(),
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        NotificationCenter.default.post(name: .zoneExited, object: localZoneExit)
    }

    private func checkZoneBoundaries(for location: CLLocation) {
        for zone in userZones {
            let zoneCenter = CLLocation(latitude: zone.latitude, longitude: zone.longitude)
            let distance = location.distance(from: zoneCenter)
            
            if distance > zone.radius {
                // User has exited the zone
                Task {
                    await zoneUpdateManager.handleZoneExits(for: fdm.currentUser?.id ?? UUID(), zoneIds: [zone.id], at: Date())
                }
                notifyZoneExit(zone: zone, location: location)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion,
              let zoneId = UUID(uuidString: circularRegion.identifier),
              let profileId = fdm.currentUser?.id,
              let zone = userZones.first(where: { $0.id == zoneId }),
              let location = manager.location else {
            return
        }
        
        Task {
            await zoneUpdateManager.handleZoneExits(for: profileId, zoneIds: [zoneId], at: Date())
        }
        notifyZoneExit(zone: zone, location: location)
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
