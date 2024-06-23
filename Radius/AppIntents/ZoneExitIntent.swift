//
//  ZoneExitIntent.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/23/24.
//

import Foundation
import AppIntents
import SwiftUI

struct ZoneExitIntent: AppIntent {
    static var title: LocalizedStringResource = "Notify Zone Exit"
    static var description = IntentDescription("Notifies when a user leaves a zone")

    @Parameter(title: "Message")
    var message: String

    static var parameterSummary: some ParameterSummary {
        Summary("Notify \(\.$message) when a user leaves their zone")
    }

    func perform() async throws -> some IntentResult {
        // Fetch the latest zone exit
        let latestExit: ZoneExit = try await supabase
            .from("zone_exits")
            .select("*, profiles(*), zones(*)")
            .order("exit_time", ascending: false)
            .limit(1)
            .single()
            .execute()
            .value

        let formattedMessage = String(format: message,
                                      latestExit.profile.full_name,
                                      latestExit.zone.name,
                                      latestExit.exit_time as CVarArg)

        // Here you would typically send a notification or perform some action
        // For this example, we'll just print the message
        print(formattedMessage)

        return .result()
    }
}

struct ZoneExit: Codable {
    let zone_id: UUID
    let profile_id: UUID
    let exit_time: Date
    let profile: Profile
    let zone: Zone
}
