//
//  GroupsRepository.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/11/24.
//

import Foundation
import Supabase

class GroupsRepository {
    private var cache: [UUID: [Group]] = [:] // In-memory cache for groups
    private var supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    // Fetch groups from cache or Supabase
    func fetchGroups(for userId: UUID) async throws -> [Group] {
        if let cachedGroups = cache[userId] {
            return cachedGroups
        }
        
        let groups: [Group] = try await supabaseClient
            .from("group_members")
            .select("group_id, groups!inner(*)")
            .eq("profile_id", value: userId.uuidString)
            .execute()
            .value
        
        cache[userId] = groups
        return groups
    }
    
    // Invalidate cache for groups
    func invalidateGroupsCache(for userId: UUID) {
        cache.removeValue(forKey: userId)
    }
}

