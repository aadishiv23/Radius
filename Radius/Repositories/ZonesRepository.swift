//
//  ZonesRepository.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/11/24.
//

import Foundation
import Supabase

class ZonesRepository {
    private var cache: [UUID: [Zone]] = [:] // In-memory cache for zones
    private var supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    // Fetch zones from cache or Supabase
    func fetchZones(for userId: UUID) async throws -> [Zone] {
        if let cachedZones = cache[userId] {
            return cachedZones
        }
        
        let zones: [Zone] = try await supabaseClient
            .from("zones")
            .select("*")
            .eq("profile_id", value: userId.uuidString)
            .execute()
            .value
        
        cache[userId] = zones
        return zones
    }
    
    // Invalidate cache for zones
    func invalidateZonesCache(for userId: UUID) {
        cache.removeValue(forKey: userId)
    }
}
