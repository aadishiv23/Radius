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
    
    // static let shortcutTileColor: ShortcutTileColor.navy

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordZoneExitIntent(),
            phrases: [
                "Record my zone exit in \(.applicationName)",
                "Have I left any zones in \(.applicationName)?",
                "\(.applicationName) zone check",
                "Record my \(\.$selectedZone) exit with \(.applicationName)"
            ],
            shortTitle: "Record Zone Exit",
            systemImageName: "mappin.and.ellipse"
        )
    }
}

struct RecordZoneExitIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Zone Exit"
    static var description = IntentDescription("Record that you've left a zone")
    
    static var parameterSummary: some ParameterSummary {
        Summary("Record zone exit for \(\.$selectedZone)")
    }

    @Parameter(title: "Zone", optionsProvider: ZoneQuery())
    var selectedZone: ZoneEntity

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
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

        // Find the selected zone in the user's zones
        guard let zone = currentUser.zones.first(where: { $0.id == selectedZone.id }) else {
            throw AppIntentError.message("Couldn't find the selected zone.")
        }
        
        let zoneEntity = ZoneEntity(from: zone)

        // Check if we've already recorded an exit today
        if try await zum.hasAlreadyExitedToday(for: currentUser.id, zoneId: zone.id, category: zone.category) {
            return .result(
                dialog: """
                You've already recorded an exit for \(zone.name) today.
                """,
                view: zoneExitSnippetView(zone: zoneEntity, status: .alreadyRecorded)
            )
        }

        // Record the zone exit
        do {
            let now = Date()
            try await zum.uploadZoneExit(for: currentUser.id, zoneIds: [zone.id], at: now)
            try await zum.handleDailyZoneExits(for: currentUser.id, zoneIds: [zone.id], at: now)

            return .result(
                dialog: """
                Successfully recorded your exit from \(zone.name) at \(now.formatted(date: .abbreviated, time: .shortened))
                """,
                view: zoneExitSnippetView(zone: zoneEntity, status: .success(timestamp: now))
            )
        } catch {
            throw AppIntentError
                .message("Failed to record zone exit: \(error.localizedDescription)")
        }
    }
}

// Helper view and enums
enum ZoneExitStatus {
    case success(timestamp: Date)
    case alreadyRecorded
}

func zoneExitSnippetView(zone: ZoneEntity, status: ZoneExitStatus) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Spacer()
        Text(zone.name)
            .font(.headline)
        
        switch status {
        case .success(let timestamp):
            Text("Exit recorded at \(timestamp.formatted(date: .abbreviated, time: .shortened))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        case .alreadyRecorded:
            Text("Already recorded today")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
