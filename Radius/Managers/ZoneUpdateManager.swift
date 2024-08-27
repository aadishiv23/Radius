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
            for (index, zoneId) in zoneIds.enumerated() {
                let zoneExit = [
                    "profile_id": profileId.uuidString,
                    "zone_id": zoneId.uuidString,
                    "exit_time": exitTime
                ]
                
                let insertedZoneExit: ZoneExit = try await supabaseClient
                    .from("zone_exits")
                    .insert(zoneExit)
                    .select()
                    .single()
                    .execute()
                    .value
                
                // Insert into daily_zone_exits
                let dailyZoneExit = DailyZoneExit(
                    id: UUID(),  // Generate a new UUID for this entry
                    date: Date(),
                    profileId: profileId,
                    zoneExitId: insertedZoneExit.id,
                    exitOrder: index + 1,
                    pointsEarned: calculatePoints(for: index)
                )
                
                try await supabaseClient
                    .from("daily_zone_exits")
                    .insert(dailyZoneExit)
                    .execute()
                
                print("Daily zone exit recorded successfully for zone \(zoneId)")
            }
        } catch {
            print("Failed to record zone exits: \(error)")
        }
    }
    
    private func calculatePoints(for exitOrder: Int) -> Int {
           // Assuming points decrease by 1 with each subsequent exit
           let maxPoints = 12 // Adjust based on game rules
           return max(maxPoints - exitOrder, 0)
       }
}
