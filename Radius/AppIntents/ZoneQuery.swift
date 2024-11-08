//
//  ZoneQuery.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 11/6/24.
//

import AppIntents
import Foundation

/// Query to fetch available zones
struct ZoneQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [ZoneEntity] {
        // Fetch specific zones from their ids
        let fdm = FriendsDataManager(supabaseClient: supabase)
        await fdm.fetchCurrentUserProfile()
        guard let currentUser = fdm.currentUser else { return [] }
        
        return currentUser.zones
            .filter { identifiers.contains($0.id) }
            .map { ZoneEntity(id: $0.id, name: $0.name)}
    }
    
    func suggestedEntities() async throws -> [ZoneEntity] {
        // Fetch all available zones for the current user
        let fdm = FriendsDataManager(supabaseClient: supabase)
        await fdm.fetchCurrentUserProfile()
        guard let currentUser = fdm.currentUser else { return [] }
        
        return currentUser.zones.map { ZoneEntity(id: $0.id, name: $0.name) }
    }
}
