
//  LocationManager.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/6/24.

import Combine
import CoreLocation
import Supabase

enum LocationAccuracyMode: String {
    case highAccuracy = "HighAccuracy"
    case balanced = "Balanced"
    case lowPower = "LowPower"

    static func from(rawValue: String?) -> LocationAccuracyMode {
        guard let rawValue else {
            return .balanced
        }
        return LocationAccuracyMode(rawValue: rawValue) ?? .balanced
    }
}

@available(iOS 17.0, *)
class LocationManager: NSObject, ObservableObject {
    // MARK: - Properties
    static let shared = LocationManager()
    private var locationManager = CLLocationManager()
    private var monitor: CLMonitor?
    private var lastUploadedLocation: CLLocation?
    private let locationUpdateInterval: TimeInterval = 60
    private let minimumDistance: CLLocationDistance = 50
    private let userDefaultsKey = "LocationAccuracyMode"
    private var profileFetched = false
    
    // Temporary Zone Properties
    private var temporaryZoneId: UUID?
    private let temporaryZoneRadius: CLLocationDistance = 150
    private var lastSignificantMovement: Date?
    private let inactivityThreshold: TimeInterval = 15 * 60 // 15 minutes
    private let minimumSignificantDistance: CLLocationDistance = 50 // meters

    let zoneUpdateManager: ZoneUpdateManager
    private let fdm: FriendsDataManager

    @Published var userZones: [Zone] = []
    @Published var userLocation: CLLocation?
    @Published var accuracyMode: LocationAccuracyMode = .balanced {
        didSet {
            saveUserPreference()
            applyAccuracySettings()
        }
    }

    // MARK: - Initialization
    override init() {
        self.zoneUpdateManager = ZoneUpdateManager(supabaseClient: supabase)
        self.fdm = FriendsDataManager(supabaseClient: supabase)

        super.init()
        
        let savedMode = UserDefaults.standard.string(forKey: userDefaultsKey)
        self.accuracyMode = LocationAccuracyMode.from(rawValue: savedMode)
        
        locationManager.delegate = self
        applyAccuracySettings()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        checkLocationAuthorization()
        initializeLocationManager()
        
        // Initialize last movement time
        lastSignificantMovement = Date()
    }

    private func initializeLocationManager() {
        Task {
            do {
                try await fetchUserProfileAndZones()
                self.profileFetched = true
                await setupMonitor()
                startMonitoringSignificantLocationChanges()
                locationManager.startUpdatingLocation()
            } catch {
                print("Initialization failed: \(error)")
            }
        }
    }

    // MARK: - Location Updates
    private func handleLocationUpdate(_ location: CLLocation) {
        let previousLocation = userLocation
        userLocation = location
        
        // If this is the first location update, just store it and return
        guard let previousLocation = previousLocation else { return }
        
        let distance = location.distance(from: previousLocation)
        
        // If movement is detected, update last movement time
        if distance > minimumSignificantDistance {
            lastSignificantMovement = Date()
            
            // If there was a temporary zone, remove it
            if let tempId = temporaryZoneId {
                Task {
                    await removeGeographicCondition(for: tempId)
                    temporaryZoneId = nil
                }
            }
        } else {
            // Check if we've been stationary long enough to create a temporary zone
            let timeStationary = Date().timeIntervalSince(lastSignificantMovement ?? Date())
            if timeStationary >= inactivityThreshold && temporaryZoneId == nil {
                createTemporaryZoneIfNeeded()
            }
        }
    }

    // MARK: - Location Services ⬅️ Changed: Updated location services section

    func checkIfLocationServicesIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            checkLocationAuthorization()
        } else {
            print("Location services are disabled")
            locationManager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - Monitor Setup
    private func setupMonitor() async {
        monitor = await CLMonitor("ZoneMonitor")
        print("[setupMonitor] Initialized Monitor 'ZoneMonitor'.")

        for zone in userZones {
            let center = CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude)
            let condition = CLMonitor.CircularGeographicCondition(center: center, radius: zone.radius)
            await monitor?.add(condition, identifier: zone.id.uuidString, assuming: .satisfied)
        }

        Task {
            guard let monitor else { return }
            for try await event in await monitor.events {
                handleMonitorEvent(event)
            }
        }
    }

    // MARK: - Temporary Zone Management
    private func createTemporaryZoneIfNeeded() {
        guard let currentLocation = userLocation,
              temporaryZoneId == nil else { return }
        
        let newZoneId = UUID()
        let center = currentLocation.coordinate
        
        Task {
            let condition = CLMonitor.CircularGeographicCondition(
                center: center,
                radius: temporaryZoneRadius
            )
            
            await monitor?.add(condition, identifier: newZoneId.uuidString, assuming: .satisfied)
            temporaryZoneId = newZoneId
            
            // Store the creation time and location
            UserDefaults.standard.set(Date(), forKey: "tempZoneCreationTime")
            UserDefaults.standard.set(center.latitude, forKey: "tempZoneLatitude")
            UserDefaults.standard.set(center.longitude, forKey: "tempZoneLongitude")
        }
    }

    private func cleanupStaleTemporaryZones() {
        if let creationTime = UserDefaults.standard.object(forKey: "tempZoneCreationTime") as? Date,
           Date().timeIntervalSince(creationTime) > 24 * 60 * 60 {
            if let tempId = temporaryZoneId {
                Task {
                    await removeGeographicCondition(for: tempId)
                    temporaryZoneId = nil
                    
                    UserDefaults.standard.removeObject(forKey: "tempZoneCreationTime")
                    UserDefaults.standard.removeObject(forKey: "tempZoneLatitude")
                    UserDefaults.standard.removeObject(forKey: "tempZoneLongitude")
                }
            }
        }
    }

    // MARK: - Monitor Events
    private func handleMonitorEvent(_ event: CLMonitor.Event) {
        print("[handleMonitorEvent] Event received: \(event.state.rawValue) for identifier: \(event.identifier)")
        if event.state == .unsatisfied {
            Task {
                guard let currentUserId = fdm.currentUser?.id,
                      let zoneId = UUID(uuidString: event.identifier) else {
                    print("[handleMonitorEvent] Invalid user or zone ID")
                    return
                }

                if zoneId == temporaryZoneId {
                    print("[handleMonitorEvent] User exited temporary zone.")
                    await removeGeographicCondition(for: zoneId)
                    self.temporaryZoneId = nil
                    return
                }

                do {
                    let zone: Zone = try await zoneUpdateManager.fetchZone(for: zoneId)
                    try await zoneUpdateManager.uploadZoneExit(for: currentUserId, zoneIds: [zoneId], at: event.date)
                    try await zoneUpdateManager.handleDailyZoneExits(
                        for: currentUserId,
                        zoneIds: [zoneId],
                        at: event.date
                    )
                } catch {
                    print("[handleMonitorEvent] Failed to handle monitor event: \(error)")
                }
            }
        }
    }

    // MARK: - Location Services
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted, .denied:
            print("Location access denied")
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            if profileFetched {
                locationManager.startUpdatingLocation()
            }
        @unknown default:
            break
        }
    }

    // MARK: - Profile and Zones
    private func fetchUserProfileAndZones() async throws {
        await fdm.fetchCurrentUserProfile()
        guard let currentUser = fdm.currentUser else {
            throw NSError(
                domain: "LocationManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Current user is nil"]
            )
        }
        await MainActor.run {
            self.userZones = currentUser.zones
        }
    }

    private func ensureProfileIsFetched() async {
        while !profileFetched {
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }

    // MARK: - Location Upload
    private func shouldUploadLocation(_ newLocation: CLLocation) -> Bool {
        guard let lastLocation = lastUploadedLocation else {
            return true
        }
        let timeInterval = newLocation.timestamp.timeIntervalSince(lastLocation.timestamp)
        let distance = newLocation.distance(from: lastLocation)
        return timeInterval >= locationUpdateInterval || distance >= locationManager.distanceFilter
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

                await MainActor.run {
                    self.lastUploadedLocation = newLocation
                }
            } catch {
                print("Failed to update location: \(error)")
            }
        }
    }

    // MARK: - Accuracy Settings
    private func applyAccuracySettings() {
        switch accuracyMode {
        case .highAccuracy:
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.distanceFilter = 25
        case .balanced:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = 100
        case .lowPower:
            locationManager.desiredAccuracy = kCLLocationAccuracyReduced
            locationManager.distanceFilter = 500
        }
    }

    private func saveUserPreference() {
        UserDefaults.standard.set(accuracyMode.rawValue, forKey: userDefaultsKey)
    }

    // MARK: - Public Methods
    func startMonitoringSignificantLocationChanges() {
        locationManager.startMonitoringSignificantLocationChanges()
    }

    func removeGeographicCondition(for zoneId: UUID) async {
        await monitor?.remove(zoneId.uuidString)
        print("Removed geographic condition for zone: \(zoneId)")
    }

    func plsInitiateLocationUpdates() {
        if profileFetched {
            locationManager.startUpdatingLocation()
        } else {
            print("Cannot initiate location updates before profile is fetched.")
        }
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - App Lifecycle Methods
    func applicationDidEnterBackground() {
        locationManager.startMonitoringSignificantLocationChanges()
        
        if let lastMovement = lastSignificantMovement,
           Date().timeIntervalSince(lastMovement) >= inactivityThreshold {
            createTemporaryZoneIfNeeded()
        }
    }
    
    func applicationWillEnterForeground() {
        if let tempId = temporaryZoneId {
            Task {
                await removeGeographicCondition(for: tempId)
                temporaryZoneId = nil
            }
        }
        lastSignificantMovement = Date()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task {
            await ensureProfileIsFetched()
            
            await MainActor.run {
                handleLocationUpdate(location)
            }
            
            if shouldUploadLocation(location) {
                uploadLocation(location)
            }
        }
    }
}

// MARK: - Monitoring Utilities
extension LocationManager {
    func getMonitoredZones() async -> [(zoneId: UUID, isMonitored: Bool)] {
        var monitoredZones: [(UUID, Bool)] = []
        let monitoredIdentifiers = await monitor?.identifiers ?? []
        
        for zone in userZones {
            let isMonitored = monitoredIdentifiers.contains(zone.id.uuidString)
            monitoredZones.append((zone.id, isMonitored))
        }
        
        return monitoredZones
    }
    
    func getMonitorEvents() async throws -> [CLMonitor.Event] {
        var events: [CLMonitor.Event] = []
        if let monitor {
            for try await event in await monitor.events {
                events.append(event)
            }
        }
        return events
    }
    
    func getMonitorRecords() async -> [(zoneId: UUID, record: CLMonitor.Record)] {
        var records: [(UUID, CLMonitor.Record)] = []
        if let monitor {
            for zone in userZones {
                if let record = await monitor.record(for: zone.id.uuidString) {
                    records.append((zone.id, record))
                }
            }
        }
        return records
    }
    
    func reinitializeMonitoringIfNeeded() {
        let authorizationStatus = locationManager.authorizationStatus
        
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            Task {
                do {
                    try await fetchUserProfileAndZones()
                    await setupMonitor()
                    locationManager.startUpdatingLocation()
                } catch {
                    print("Error reinitializing monitoring: \(error)")
                }
            }
        } else {
            locationManager.requestAlwaysAuthorization()
        }
    }
}
