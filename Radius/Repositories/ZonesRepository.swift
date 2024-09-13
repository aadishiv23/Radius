//
//  ZonesRepository.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/11/24.
//

import Foundation
import Supabase

class ZonesRepository: ObservableObject {
    @Published var zones: [Zone] = []
    private var cache: [UUID: CachedData<[Zone]>] = [:] // In-memory cache for zones
    private let zoneService: ZoneService
    
    init(zoneService: ZoneService) {
        self.zoneService = zoneService
    }

    
    // Fetch zones from cache or Supabase
    func fetchZones(for profileId: UUID) async throws -> [Zone] {
        if let cachedZones = cache[profileId] {
            return cachedZones.data
        }
        
        let fetchedZones = try await zoneService.fetchZones(for: profileId)
        cache[profileId] = CachedData(data: fetchedZones, timestamp: Date())
        
        DispatchQueue.main.async {
            self.zones = fetchedZones
        }
        return fetchedZones
    }
    
    func addZone(to profileId: UUID, zone: Zone) async throws {
        try await zoneService.insertZone(for: profileId, zone: zone)
    }
    
    func removeZone(zoneId: UUID) async throws {
        try await zoneService.deleteZone(zoneId: zoneId)
    }
    
    // Invalidate cache for zones
    func invalidateZonesCache(for userId: UUID) {
        cache.removeValue(forKey: userId)
    }
}
