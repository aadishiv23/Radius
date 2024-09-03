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
    
    func fetchZoneExits(for profileId: UUID) async throws -> [ZoneExit] {
        do {
            let zoneExits: [ZoneExit] = try await supabaseClient
                .from("zone_exits")
                .select()
                .eq("profile_id", value: profileId.uuidString)
                .order("exit_time", ascending: false)  // Adjust sorting based on your needs
                .execute()
                .value
            
            return zoneExits
        } catch {
            print("Failed to fetch zone exits for profile \(profileId): \(error)")
            throw error
        }
    }
    
    func handleZoneExits(for profileId: UUID, zoneIds: [UUID], at time: Date) async {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "EDT")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let exitTime = dateFormatter.string(from: time)
        let currentDateString = dateFormatter.string(from: time)

        do {
            // Fetch the user's group
            let userGroups = try await fetchUserGroupsZum(for: profileId)
            var globalExitOrder = 1
            var totalUsers = 0  // Define totalUsers outside the conditional block

            for group in userGroups {
                if let competition = try await fetchCompetitionZum(for: group.group_id) {
                    // Calculate total users in competition
                    totalUsers = try await fetchTotalUsersInCompetitionZum(competition.id)
                    globalExitOrder = try await calculateGlobalExitOrder(dateString: currentDateString, totalUsers: totalUsers)
                    break
                } else {
                    // Calculate total users in the group
                    totalUsers = try await fetchTotalUsersInGroupZum(group.group_id)
                    globalExitOrder = try await calculateGlobalExitOrder(dateString: currentDateString, totalUsers: totalUsers)
                }

                for zoneId in zoneIds {
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

                    let dailyZoneExit = DailyZoneExit(
                        id: UUID(),
                        date: Date(),
                        profileId: profileId,
                        zoneExitId: insertedZoneExit.id,
                        exitOrder: globalExitOrder,
                        pointsEarned: calculatePoints(for: globalExitOrder, totalUsers: totalUsers) // Use totalUsers here
                    )

                    try await supabaseClient
                        .from("daily_zone_exits")
                        .insert(dailyZoneExit)
                        .execute()

                    globalExitOrder += 1
                }
            }
        } catch {
            print("Failed to record zone exits: \(error)")
        }
    }

    
    private func fetchUserGroupsZum(for profileId: UUID) async throws -> [GroupMember] {
        return try await supabaseClient
            .from("group_members")
            .select("group_id, profile_id")
            .eq("profile_id", value: profileId.uuidString)
            .execute()
            .value
    }
    
    private func fetchCompetitionZum(for groupId: UUID) async throws -> GroupCompetition? {
        let competitions: [GroupCompetition] = try await supabaseClient
            .from("group_competition_links")
            .select("*")
            .eq("group_id", value: groupId.uuidString)
            .execute()
            .value

        return competitions.first
    }
    
    private func fetchTotalUsersInGroupZum(_ groupId: UUID) async throws -> Int {
        let groupMembers: [GroupMember] = try await supabaseClient
            .from("group_members")
            .select("profile_id")
            .eq("group_id", value: groupId.uuidString)
            .execute()
            .value
        
        return groupMembers.count
    }

    private func fetchTotalUsersInCompetitionZum(_ competitionId: UUID) async throws -> Int {
        let groupCompetitionLinks: [GroupCompetitionLink] = try await supabaseClient
            .from("group_competition_links")
            .select("group_id")
            .eq("competion_id", value: competitionId.uuidString)
            .execute()
            .value
        
        let groupIds = groupCompetitionLinks.map { $0.group_id}
        
        var totalUsers = 0
        for groupId in groupIds {
            totalUsers += try await fetchTotalUsersInGroupZum(groupId)
        }

        return totalUsers
    }
    
    private func calculateGlobalExitOrder(dateString: String, totalUsers: Int) async throws -> Int {
        let exitCountResponse: [DailyZoneExit] = try await supabaseClient
            .from("daily_zone_exits")
            .select("*")
            .eq("date", value: dateString)
            .execute()
            .value

        return exitCountResponse.count + 1  // Next exit order
    }

    private func calculatePoints(for exitOrder: Int, totalUsers: Int) -> Int {
        return max(totalUsers - exitOrder, 0)
    }
}
