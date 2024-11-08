//
//  ZoneExitIntent.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/23/24.
//

import AppIntents
import CoreLocation
import SwiftUI

enum AppIntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case message(_ message: String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case let .message(message): "\(message)"
        }
    }
}

struct RecordZoneExitShortcut: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordZoneExitIntent(),
            phrases: [
                "Record my zone exit in \(.applicationName)",
                "Have I left any zones in \(.applicationName)?",
                "\(.applicationName) zone check"
            ],
            shortTitle: "Record Zone Exit",
            systemImageName: "mappin.and.ellipse"
        )
    }
}

struct RecordZoneExitIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Zone Exit"
    static var description = IntentDescription("Record that you've left a zone")

    /// Ensure that the App Intent opens the app when run
    /// This is needed since we require network operations to run upon succesful exit of a zone
    static var openAppWhenRun = true

    /// Add parameter for zone selection
    @Parameter(title: "Zone", optionsProvider: ZoneQuery())
    var selectedZone: ZoneEntity

    private func zoneExitSuccessView(for zoneName: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.green)
                .imageScale(.large)
                .font(.largeTitle)

            VStack {
                Text("Successfully left:")
                    .font(.title)
                Text(zoneName)
                    .font(.headline)
            }
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let locationManager = LocationManager.shared
        let zum = ZoneUpdateManager(supabaseClient: supabase)

        // Get the current user's profile
        let fdm = FriendsDataManager(supabaseClient: supabase)
        await fdm.fetchCurrentUserProfile()
        guard let currentUser = fdm.currentUser else {
            throw AppIntentError.message("Couldn't find your user profile.")
        }

        guard CLLocationManager.locationServicesEnabled() else {
            throw AppIntentError.message("Location services are disabled. Enable location access in Settings.")
        }

//        // Request location and wait for it with timeout
//        locationManager.plsInitiateLocationUpdates()
//
//        // Wait for up to 10 seconds for location
//        let startTime = Date()
//        while locationManager.userLocation == nil {
//            if Date().timeIntervalSince(startTime) > 10 {
//                throw AppIntentError.message("Timeout waiting for location. Please try again.")
//            }
//            try await Task.sleep(nanoseconds: 500_000_000) // Sleep for 0.5 seconds
//        }
//
//        guard let currentLocation = locationManager.userLocation else {
//            throw AppIntentError.message("Couldn't get your current location.")
//        }

        // Find the selected zone in the user's zones
        guard let zone = currentUser.zones.first(where: { $0.id == selectedZone.id }) else {
            throw AppIntentError.message("Couldn't find the selected zone.")
        }

        // Verify user has actually left the zone
//        let zoneCenter = CLLocation(latitude: zone.latitude, longitude: zone.longitude)
//        let distance = currentLocation.distance(from: zoneCenter)
//
//        guard distance > zone.radius else {
//            return .result(
//                value: "You're still inside  \(zone.name)",
//                dialog: "You're still inside \(zone.name). You need to be outside the zone to record an exit"
//            )
//        }

        // Check if we've already recorded an exit today
        if try await zum.hasAlreadyExitedToday(for: currentUser.id, zoneId: zone.id, category: zone.category) {
            return .result(
                value: "Already recorded zone exit",
                dialog: "You've already recorded an exit for \(zone.name) today."
            )
        }

        // Record the zone exit
        do {
            let now = Date()
            try await zum.uploadZoneExit(for: currentUser.id, zoneIds: [zone.id], at: now)
            try await zum.handleDailyZoneExits(for: currentUser.id, zoneIds: [zone.id], at: now)

            return .result(
                value: "Exit recorded",
                dialog: "Successfully recorded your exit from \(zone.name)",
                view: zoneExitSuccessView(for: zone.name)
            )
        } catch {
            throw AppIntentError
                .message("Failed to record zone exit: \(error.localizedDescription)")
        }
    }
}
