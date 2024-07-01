//
//  ZoneExitIntent.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/23/24.
//

import AppIntents
import CoreLocation

struct CheckZoneExitShortcut: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckZoneExitIntent(),
            phrases: [
                "Check if I've left my zones in \(.applicationName)",
                "Have I left any zones in \(.applicationName)?",
                "\(.applicationName) zone check"
            ],
            shortTitle: "Check Zone Exit",
            systemImageName: "mappin.and.ellipse"
        )
    }
}

struct CheckZoneExitIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Zone Exit"
    static var description = IntentDescription("Checks if you've left any of your zones")
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {
        let locationManager = LocationManager.shared
        let fdm = FriendsDataManager(supabaseClient: supabase)
        
        // Fetch the current user's profile
        await fdm.fetchCurrentUserProfile()
        guard let currentUser = fdm.currentUser else {
            return .result(
                value: "Couldn't find your profile",
                dialog: "Couldn't find your profile"
            )
        }
        
        // Get the current location
        guard let currentLocation = locationManager.userLocation else {
            return .result(
                value: "Couldn't get your current location",
                dialog: "Couldn't get your current location"
            )
        }
        
        var exitedZones: [String] = []
        
        // Check each zone
        for zone in currentUser.zones {
            let zoneCenter = CLLocation(latitude: zone.latitude, longitude: zone.longitude)
            let distance = currentLocation.distance(from: zoneCenter)
            
            if distance > zone.radius {
                // User has left the zone
                exitedZones.append(zone.name)
            }
        }
        
        if exitedZones.isEmpty {
            return .result(
                value: "You're still within all your zones",
                dialog: "You're still within all your zones"
            )
        } else {
            let zoneList = exitedZones.joined(separator: ", ")
            return .result(
                value: "You've left the following zones: \(zoneList)",
                dialog: "You've left the following zones: \(zoneList)"
            )
        }
    }
}

struct ZoneExit: Codable {
    let zone_id: UUID
    let profile_id: UUID
    let exit_time: Date
    let profile: Profile
    let zone: Zone
}
