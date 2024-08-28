//
//  CompetitionManager.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 8/26/24.
//

import Foundation
import Supabase

class CompetitionManager {
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    func fetchAllGroups() async throws -> [Group] {
        try await supabaseClient
            .from("groups")
            .select()
            .execute()
            .value
    }
    
    func createCompetition(competitionName: String, competitionDate: Date, maxPoints: Int, groupIds: [UUID]) async throws -> GroupCompetition {
        let competition = GroupCompetition(
            id: UUID(),
            competitionName: competitionName,
            competitionDate: competitionDate,
            maxPoints: maxPoints,
            createdAt: Date()
        )
        
        // Insert competition
        try await supabaseClient
            .from("group_competitions")
            .insert(competition)
            .execute()
        
        // Link groups to the competition
        for groupId in groupIds {
            let link = GroupCompetitionLink(id: UUID(), competitionId: competition.id, groupId: groupId)
            try await supabaseClient
                .from("group_competition_links")
                .insert(link)
                .execute()
        }
        
        // Update max points based on the total number of profiles in linked groups
        let profileCount = try await fetchProfileCount(for: competition.id)
        let updatedCompetition = GroupCompetition(
            id: competition.id,
            competitionName: competition.competitionName,
            competitionDate: competition.competitionDate,
            maxPoints: profileCount,
            createdAt: competition.createdAt
        )
        
        try await supabaseClient
            .from("group_competitions")
            .update(updatedCompetition)
            .eq("id", value: competition.id.uuidString)
            .execute()
        
        return updatedCompetition
    }
    
    private func fetchProfileCount(for competitionId: UUID) async throws -> Int {
        let profileCountResponse: Int = try await supabaseClient
            .rpc("count_profiles_in_competition", params: ["competition_id": competitionId.uuidString])
            .execute()
            .value
        
        return profileCountResponse
    }
}
