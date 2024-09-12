//
//  CompetitionsRepository.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/11/24.
//

import Foundation
import Supabase

class CompetitionsRepository {
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
        
        let competitions: [GroupCompetition] = try await supabaseClient
            .from("group_competitions")
            .select("*")
            .eq("profile_id", value: userId.uuidString)
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
