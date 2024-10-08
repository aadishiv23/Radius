
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

    /// Initialize from a string or return a default value
    static func from(rawValue: String?) -> LocationAccuracyMode {
        guard let rawValue else {
            return .balanced
        }
        return LocationAccuracyMode(rawValue: rawValue) ?? .balanced
    }
}

@available(iOS 17.0, *)
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    private var locationManager = CLLocationManager()
    private var monitor: CLMonitor?
    private var lastUploadedLocation: CLLocation?
    private let locationUpdateInterval: TimeInterval = 60
    private let minimumDistance: CLLocationDistance = 50
    private let userDefaultsKey = "LocationAccuracyMode"
    private var profileFetched = false // Flag to check if profile is fetched

    let zoneUpdateManager: ZoneUpdateManager
    private let fdm: FriendsDataManager

    @Published var userZones: [Zone] = []
    @Published var userLocation: CLLocation?

    private var initializationCancellable: AnyCancellable? // ⬅️ Added: To manage initialization sequence

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

        // Start the initialization sequence ⬅️ Changed: Moved initialization to a separate method
        initializeLocationManager()
    }

    // MARK: - Initialization Sequence ⬅️ Added: New section for initialization

    private func initializeLocationManager() { // ⬅️ Added: New method for initialization
        Task {
            do {
                try await fetchUserProfileAndZones() // Fetch profile and zones first
                self.profileFetched = true // Set flag once profile is fetched
                await setupMonitor() // Setup monitor after fetching zones
                startMonitoringSignificantLocationChanges() // Start monitoring
                locationManager.startUpdatingLocation() // Start updating location
            } catch {
                print("Initialization failed: \(error)")
            }
        }
    }

    // MARK: - monitor signfiicant locaiton changes

    /// Ensure the app keeps tracking location when terminated or suspended
    func startMonitoringSignificantLocationChanges() {
        locationManager.startMonitoringSignificantLocationChanges()
    }

    // MARK: - Fetch User Profile and Zones ⬅️ Added: New section for fetching user data

    private func fetchUserProfileAndZones() async throws { // ⬅️ Changed: Modified to throw errors
        await fdm.fetchCurrentUserProfile() // Await fetch
        print("fetched")
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

    // MARK: - Monitor Setup ⬅️ Added: New section for monitor setup

    private func setupMonitor() async { // ⬅️ Changed: Made setupMonitor asynchronous
        monitor = await CLMonitor("ZoneMonitor")
        print("[setupMonitor] Initialized Monitor 'ZoneMonitor'.")

        print("User zones: \(userZones.count)")

        for zone in userZones {
            let center = CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude)
            let condition = CLMonitor.CircularGeographicCondition(center: center, radius: zone.radius)

            await monitor?.add(condition, identifier: zone.id.uuidString, assuming: .satisfied)
            print("[setupMonitor] Added condition for zone ID: \(zone.id.uuidString)")
        }

        Task {
            guard let monitor else {
                return
            }
            print("[setupMonitor] Starting to listen for monitor events.")
            for try await event in await monitor.events { // ⬅️ Changed: Updated to use `for await`
                print("[setupMonitor] Received event: \(event)")
                handleMonitorEvent(event)
            }
        }
    }

    // MARK: - Handle Monitor Events ⬅️ Added: New section for handling monitor events

    private func handleMonitorEvent(_ event: CLMonitor.Event) {
        print("[handleMonitorEvent] Event received: \(event.state.rawValue) for identifier: \(event.identifier)")
        if event.state == .unsatisfied {
            Task {
                guard let currentUserId = fdm.currentUser?.id,
                      let zoneId = UUID(uuidString: event.identifier)
                else {
                    print("[handleMonitorEvent] Invalid user or zone ID")
                    return
                }

                do {
                    // Fetch zone details before proceeding
                    let zone: Zone = try await zoneUpdateManager.fetchZone(for: zoneId)
                    print("[handleMonitorEvent] Fetched zone details: \(zone.name)")

                    // Upload zone exit
                    try await zoneUpdateManager.uploadZoneExit(for: currentUserId, zoneIds: [zoneId], at: event.date)
                    print("[handleMonitorEvent] Uploaded zone exit for zone: \(zone.name)")

                    // Handle daily zone exits and points
                    try await zoneUpdateManager.handleDailyZoneExits(
                        for: currentUserId,
                        zoneIds: [zoneId],
                        at: event.date
                    )
                    print("[handleMonitorEvent] Handled daily zone exits for zone: \(zone.name)")

                } catch {
                    print("[handleMonitorEvent] Failed to handle monitor event: \(error)")
                }
            }
        }
    }

    // MARK: - Remove a geographic condition upon deletion of a zone

    func removeGeographicCondition(for zoneId: UUID) async {
        guard let monitor else {
            return
        }

        // Remove the monitored condition by accessing its identifier
        await monitor.remove(zoneId.uuidString)

        print("Removed geographic condition for zone: \(zoneId)")
    }

    // MARK: - Location Updates ⬅️ Changed: Updated location updates section

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else {
            return
        }

        Task {
            await ensureProfileIsFetched() // Wait for profile fetch
            DispatchQueue.main.async {
                self.userLocation = newLocation
            }
            if shouldUploadLocation(newLocation) {
                uploadLocation(newLocation)
            }
        }
    }

    // Ensure the profile is fetched before proceeding ⬅️ Added: New method to ensure profile is fetched

    private func ensureProfileIsFetched() async {
        while !profileFetched {
            try? await Task.sleep(nanoseconds: 500_000_000) // Wait 500ms
        }
    }

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
                await fdm.fetchCurrentUserProfile() // Fetch profile again before updating location
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

    // MARK: - Accuracy Settings ⬅️ Changed: Moved accuracy settings below location updates

    @Published var accuracyMode: LocationAccuracyMode = .balanced {
        didSet {
            saveUserPreference()
            applyAccuracySettings()
        }
    }

    private func applyAccuracySettings() {
        switch accuracyMode {
        case .highAccuracy:
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.distanceFilter = 25 // frequent updates
        case .balanced:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = 100 // moderate updates
        case .lowPower:
            locationManager.desiredAccuracy = kCLLocationAccuracyReduced
            locationManager.distanceFilter = 500 // infrequent updates
        }
    }

    private func saveUserPreference() {
        UserDefaults.standard.set(accuracyMode.rawValue, forKey: userDefaultsKey)
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

    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted, .denied:
            print("Location access denied")
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            // Only start updating location if initialization is complete ⬅️ Changed: Added check for profileFetched
            if profileFetched {
                locationManager.startUpdatingLocation()
            }
        @unknown default:
            break
        }
    }

    func plsInitiateLocationUpdates() {
        if profileFetched { // ⬅️ Changed: Added check for profileFetched
            locationManager.startUpdatingLocation()
        } else {
            print("Cannot initiate location updates before profile is fetched.")
        }
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}

extension LocationManager {
    func getMonitoredZones() async -> [(zoneId: UUID, isMonitored: Bool)] {
        var monitoredZones: [(UUID, Bool)] = []

        // Fetch the list of monitored region identifiers
        let monitoredIdentifiers = await monitor?.identifiers ?? []

        for zone in userZones {
            // Check if the zone ID is in the monitoredIdentifiers list
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
        print("hello")
        if let monitor {
            for zone in userZones {
                if let record = await monitor.record(for: zone.id.uuidString) {
                    print("Record condition: \(record.condition)")
                    print("Record last event: \(record.lastEvent)")
                    records.append((zone.id, record))
                } else {
                    print("No record found for zone ID: \(zone.id)")
                }
            }
        } else {
            print("Monitor is not initialized.")
        }

        return records
    }

    /// Function to reinitialize location monitoring after app relaunch
    func reinitializeMonitoringIfNeeded() {
        // Check if the app is authorized to monitor location
        let authorizationStatus = locationManager.authorizationStatus

        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            // Reinitialize the monitoring logic here
            Task {
                do {
                    // Ensure profile and zones are fetched
                    try await fetchUserProfileAndZones()

                    // Setup monitor for zones
                    await setupMonitor()

                    // Start updating location
                    locationManager.startUpdatingLocation()

                } catch {
                    print("Error reinitializing monitoring: \(error)")
                }
            }
        } else {
            // Request location permissions if necessary
            locationManager.requestAlwaysAuthorization()
        }
    }
}
