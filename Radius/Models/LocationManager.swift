
//  LocationManager.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/6/24.

import CoreLocation
import Supabase

@available(iOS 17.0, *)
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    private var locationManager = CLLocationManager()
    private var monitor: CLMonitor?
    private var lastUploadedLocation: CLLocation?
    private let locationUpdateInterval: TimeInterval = 60
    private let minimumDistance: CLLocationDistance = 50
    
    let zoneUpdateManager: ZoneUpdateManager
    private let fdm: FriendsDataManager
    
    @Published var userZones: [Zone] = []
    @Published var userLocation: CLLocation?
    
    override init() {
        self.zoneUpdateManager = ZoneUpdateManager(supabaseClient: supabase)
        self.fdm = FriendsDataManager(supabaseClient: supabase)
        
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 10
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        
        checkLocationAuthorization()
        
        Task {
            await fetchUserZones()
            await setupMonitor()
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
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted, .denied:
            print("Location access denied")
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    private func fetchUserZones() async {
        await fdm.fetchCurrentUserProfile()
        guard let currentUser = fdm.currentUser else { return }
        self.userZones = currentUser.zones
    }
    
    private func setupMonitor() async {
        monitor = await CLMonitor("ZoneMonitor")
        
        for zone in userZones {
            let center = CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude)
            let condition = CLMonitor.CircularGeographicCondition(center: center, radius: zone.radius)
            
            await monitor?.add(condition, identifier: zone.id.uuidString, assuming: .unsatisfied)
        }
        
        Task {
            guard let monitor = monitor else { return }
            for try await event in await monitor.events {
                handleMonitorEvent(event)
            }
        }
    }
    
    private func handleMonitorEvent(_ event: CLMonitor.Event) {
        if event.state == .unsatisfied {
            Task {
                guard let currentUserId = fdm.currentUser?.id, let zoneId = UUID(uuidString: event.identifier) else { return }
                
                // Fetch zone details before proceeding
                let zone: Zone = try await zoneUpdateManager.fetchZone(for: zoneId)

                // Check if the zone is categorized as "home" and if it has already been exited today
                let hasAlreadyExitedToday = try await zoneUpdateManager.hasAlreadyExitedToday(for: currentUserId, zoneId: zoneId, category: zone.category)

                if !hasAlreadyExitedToday {
                    // Upload zone exit first
                    try await zoneUpdateManager.uploadZoneExit(for: currentUserId, zoneIds: [zoneId], at: Date())

                    // Handle daily zone exits and points
                    try await zoneUpdateManager.handleDailyZoneExits(for: currentUserId, zoneIds: [zoneId], at: Date())
                } else {
                    print("Zone \(zone.name) has already been exited today. Skipping exit update.")
                }
            }
        }
    }

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        self.userLocation = newLocation
        if shouldUploadLocation(newLocation) {
            uploadLocation(newLocation)
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
                guard let currentUser = fdm.currentUser else {
                    print("Current user is nil, cannot update location.")
                    return
                }
                try await supabase
                    .from("profiles")
                    .update(locationArr)
                    .eq("id", value: currentUser.id.uuidString)
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

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
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
}
//
//extension LocationManager {
//
//    func subscribeToRealtimeLocationUpdates() {
//        // Assuming 'profiles' is the table where location data is stored
//        let subscription = supabase
//            .from("profiles")
//            .on(SupabaseRealtimeEventType.all) { event in
//                if let newLocationData = event.new {
//                    self.handleRealtimeLocationUpdate(newLocationData)
//                }
//            }
//            .subscribe()
//
//        // Store the subscription if you need to manage it (e.g., unsubscribe later)
//        supabaseSubscriptions["locationUpdates"] = subscription
//    }
//
//    private func handleRealtimeLocationUpdate(_ newLocationData: [String: Any]) {
//        guard let latitude = newLocationData["latitude"] as? Double,
//              let longitude = newLocationData["longitude"] as? Double,
//              let friendId = UUID(uuidString: newLocationData["id"] as? String ?? ""),
//              let friendIndex = fdm.friends.firstIndex(where: { $0.id == friendId }) else {
//            return
//        }
//
//        let newLocation = CLLocation(latitude: latitude, longitude: longitude)
//
//        // Update the friend's location in FriendsDataManager
//        DispatchQueue.main.async {
//            self.fdm.friends[friendIndex].latitude = newLocation.coordinate.latitude
//            self.fdm.friends[friendIndex].longitude = newLocation.coordinate.longitude
//
//        }
//    }
//
//    private func checkFriendZoneBoundaries(for location: CLLocation, friendId: UUID) {
//        // Optionally, implement logic to handle friend's movement in/out of zones
//        for zone in userZones {
//            let zoneCenter = CLLocation(latitude: zone.latitude, longitude: zone.longitude)
//            let distance = location.distance(from: zoneCenter)
//
//            if distance > zone.radius {
//                // Handle friend exiting a zone if necessary
//                Task {
//                    await zoneUpdateManager.handleFriendZoneExits(for: friendId, zoneIds: [zone.id], at: Date())
//                }
//                // Notify or update UI about the friend's exit from a zone
//            }
//        }
//    }
//
//    func unsubscribeFromRealtimeLocationUpdates() {
//        if let subscription = supabaseSubscriptions["locationUpdates"] {
//            subscription.unsubscribe()
//            supabaseSubscriptions.removeValue(forKey: "locationUpdates")
//        }
//    }
//}



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
