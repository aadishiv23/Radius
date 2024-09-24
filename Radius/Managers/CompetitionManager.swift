//
//  CompetitionManager.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 8/26/24.
//

import Foundation
import Supabase

class CompetitionManager {
    @Published var competitions: [GroupCompetition] = []

    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    func fetchCompetitions() async throws {
        let fetchedCompetitions: [GroupCompetition] = try await supabaseClient
            .from("group_competitions")
            .select("*")
            .execute()
            .value

        // Update the published competitions property
        DispatchQueue.main.async {
            self.competitions = fetchedCompetitions
        }
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
            competition_name: competitionName,
            competition_date: competitionDate,
            max_points: maxPoints,
            created_at: Date()
        )
        
        // Insert competition
        try await supabaseClient
            .from("group_competitions")
            .insert(competition)
            .execute()
        
        // Link groups to the competition
        for groupId in groupIds {
            let link = GroupCompetitionLink(id: UUID(), competition_id: competition.id, group_id: groupId)
            try await supabaseClient
                .from("group_competition_links")
                .insert(link)
                .execute()
        }
        
        // Update max points based on the total number of profiles in linked groups
        let profileCount = try await fetchProfileCount(for: competition.id)
        let updatedCompetition = GroupCompetition(
            id: competition.id,
            competition_name: competition.competition_name,
            competition_date: competition.competition_date,
            max_points: profileCount,
            created_at: competition.created_at
        )
        
        try await supabaseClient
            .from("group_competitions")
            .update(updatedCompetition)
            .eq("id", value: competition.id.uuidString)
            .execute()
        
        return updatedCompetition
    }
    
    private func fetchProfileCount(for competition_id: UUID) async throws -> Int {
        let profileCountResponse: Int = try await supabaseClient
            .rpc("count_profiles_in_competition", params: ["comp_id": competition_id.uuidString])
            .execute()
            .value
        
        return profileCountResponse
    }
    
    func fetchDailyPoints(from date: Date, for profileId: UUID) async throws -> Int {
        // Get the start of the day in UTC
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDateString = dateFormatter.string(from: date)

        // Fetch all relevant daily_zone_exits for the user on that specific day
        let dailyZoneExits: [DailyZoneExit] = try await supabaseClient
            .from("daily_zone_exits")
            .select("*")
            .eq("profile_id", value: profileId.uuidString)
            .eq("date", value: currentDateString) // Filter by today's date
            .execute()
            .value

        // Sum up all points earned from the daily_zone_exits
        let totalPoints = dailyZoneExits.reduce(0) { result, zoneExit in
            result + zoneExit.points_earned
        }

        return totalPoints
    }


    func fetchCompetitionPoints(for profileId: UUID, competitionId: UUID) async throws -> Int {
        let pointsResponse: Int = try await supabaseClient
            .rpc("fetch_competition_points", params: ["comp_id": competitionId.uuidString, "profile_id": profileId.uuidString])
            .execute()
            .value
        
        return pointsResponse
    }

    func fetchCompetitors(for competitionId: UUID) async throws -> [GroupMember] {
        let groupCompetitionLinks: [GroupCompetitionLink] = try await supabaseClient
            .from("group_competition_links")
            .select("group_id")
            .eq("competition_id", value: competitionId.uuidString)
            .execute()
            .value
        
        let groupIds = groupCompetitionLinks.map { $0.group_id }
        return try await fetchCompetitorsFromGroups(groupIds)
    }

    private func fetchCompetitorsFromGroups(_ groupIds: [UUID]) async throws -> [GroupMember] {
        let groupMembers: [GroupMember] = try await supabaseClient
            .from("group_members")
            .select("profile_id, group_id, profiles(full_name), groups(name)")
            .in("group_id", values: groupIds.map { $0.uuidString })
            .execute()
            .value
        
        return groupMembers
    }

}
