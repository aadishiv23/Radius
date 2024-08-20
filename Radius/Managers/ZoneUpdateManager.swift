//
//  ZoneUpdateManager.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 8/19/24.
//

import Foundation
import Supabase

final class ZoneUpdateManager {
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    func handleZoneExits(for profileId: UUID, zoneIds: [UUID], at time: Date) async {
        let dateFormatter = ISO8601DateFormatter()
        let exitTime = dateFormatter.string(from: time)
        
        do {
            for zoneId in zoneIds {
                let zoneExit = [
                    "profile_id": profileId.uuidString,
                    "zone_id": zoneId.uuidString,
                    "exit_time": exitTime
                ]
                
                try await supabaseClient
                    .from("zone_exits")
                    .insert(zoneExit)
                    .execute()
                
                print("Zone exit recorded successfully for zone \(zoneId)")
            }
        } catch {
            print("Failed to record zone exits: \(error)")
        }
    }
}
