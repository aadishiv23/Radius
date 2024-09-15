//
//  CompetitionsRepository.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/11/24.
//

import Foundation
import Supabase

class CompetitionsRepository: ObservableObject {
    private var cache: [UUID: [GroupCompetition]] = [:] // In-memory cache for competitions
    private var supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    // Fetch competitions from cache or Supabase
    func fetchCompetitions(for userId: UUID) async throws -> [GroupCompetition] {
        if let cachedCompetitions = cache[userId] {
            return cachedCompetitions
        }
        
        // Step 1: Fetch the user's groups
        let userGroups: [GroupMember] = try await supabaseClient
            .from("group_members")
            .select("group_id, profile_id")
            .eq("profile_id", value: userId.uuidString)
            .execute()
            .value
        
        let groupIds = userGroups.map { $0.group_id.uuidString }
        
        // Step 2: Fetch competitions linked to these groups
        let groupCompetitionLinks: [GroupCompetitionLink] = try await supabaseClient
            .from("group_competition_links")
            .select("*")
            .in("group_id", values: groupIds)
            .execute()
            .value
        
        let competitionIds = groupCompetitionLinks.map { $0.competition_id.uuidString }
       // Array(Set(groupCompetitionLinks.map { $0.competition_id.uuidString }))
        
        // Step 3: Fetch the actual competition details
        let competitions: [GroupCompetition] = try await supabaseClient
            .from("group_competitions")
            .select("*")
            .in("id", values: competitionIds)
            .execute()
            .value
        
        cache[userId] = competitions

        return competitions
    }
    
    // Invalidate cache for competitions
    func invalidateCompetitionsCache(for userId: UUID) {
        cache.removeValue(forKey: userId)
    }
}
