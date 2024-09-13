//
//  ZoneService.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/12/24.
//

import Foundation
import Supabase

class ZoneService {
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    // Fetch Zones
    func fetchZones(for profileId: UUID) async throws -> [Zone] {
        return try await supabaseClient
            .from("zones")
            .select("*")
            .eq("profile_id", value: profileId.uuidString)
            .execute()
            .value
    }
    
    // Insert Zone
    func insertZone(for friendId: UUID, zone: Zone) async throws {
        try await supabaseClient
            .from("zones")
            .insert(zone)
            .execute()
    }

    // Delete Zone
    func deleteZone(zoneId: UUID) async throws {
        try await supabaseClient
            .from("zones")
            .delete()
            .eq("id", value: zoneId.uuidString)
            .execute()
    }
}
