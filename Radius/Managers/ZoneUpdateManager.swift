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
                .order("exit_time", ascending: false) // Adjust sorting based on your needs
                .execute()
                .value

            return zoneExits
        } catch {
            print("Failed to fetch zone exits for profile \(profileId): \(error)")
            throw error
        }
    }

    func uploadZoneExit(for profileId: UUID, zoneIds: [UUID], at time: Date) async throws {
        // Create a DateFormatter for UTC
        let exitTimeUTC = ISO8601DateFormatter.shared.string(from: time)

        for zoneId in zoneIds {
          
            let zoneExit = [
                "profile_id": profileId.uuidString,
                "zone_id": zoneId.uuidString,
                "exit_time": exitTimeUTC // Store the time in UTC
            ]

            do {
                // Insert the zone exit record
                _ = try await supabaseClient
                    .from("zone_exits")
                    .insert(zoneExit)
                    .select()
                    .single()
                    .execute()

                print("Zone exit uploaded successfully for zone \(zoneId)")
            } catch {
                print("Failed to upload zone exit: \(error)")
                throw error
            }
        }
    }

    func handleDailyZoneExits(for profileId: UUID, zoneIds: [UUID], at time: Date) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDateString = dateFormatter.string(from: time)

        // Fetch the user's groups
        let userGroups = try await fetchUserGroupsZum(for: profileId)

        for group in userGroups {
            for zoneId in zoneIds {
                // Step 1: Fetch the most recent zone_exit_id for the profile and zone
                guard let zoneExitId = try await fetchLatestZoneExitId(for: profileId, zoneId: zoneId) else {
                    print("No zone exit found for profile \(profileId) and zone \(zoneId)")
                    continue
                }

                // Step 2: Prepare parameters for the RPC function
                let params: [String: String] = [
                    "p_profile_id": profileId.uuidString,
                    "p_zone_exit_id": zoneExitId.uuidString,
                    "p_zone_id": zoneId.uuidString,
                    "p_date": currentDateString,
                    "p_group_id": group.group_id.uuidString
                ]

                do {
                    // Step 3: Call the RPC function
                    _ = try await supabaseClient
                        .rpc("insert_daily_zone_exit", params: params)
                        .execute()

                    print("Successfully inserted daily zone exit for profile \(profileId) and zone \(zoneId)")
                } catch {
                    print("Error inserting daily zone exit: \(error)")
                    throw error
                }
            }
        }
        print("Daily zone exit recorded successfully.")
    }

    private func fetchLatestZoneExitId(for profileId: UUID, zoneId: UUID) async throws -> UUID? {
        let zoneExits: [ZoneExit] = try await supabaseClient
            .from("zone_exits")
            .select("*")
            .eq("profile_id", value: profileId.uuidString)
            .eq("zone_id", value: zoneId.uuidString)
            .order("exit_time", ascending: false) // Order by most recent exit
            .limit(1)
            .execute()
            .value

        // Return the zone_exit_id if found
        return zoneExits.first?.id
    }

    private func fetchUserGroupsZum(for profileId: UUID) async throws -> [GroupMemberWoBS] {
        let userGroups: [GroupMemberWoBS] = try await supabaseClient
            .from("group_members")
            .select("*")
            .eq("profile_id", value: profileId.uuidString)
            .execute()
            .value

        return userGroups
    }

    private func fetchCompetitionZum(for groupId: UUID) async throws -> GroupCompetition? {
        // Step 1: Fetch the competition link
        let competitionLinks: [GroupCompetitionLink] = try await supabaseClient
            .from("group_competition_links")
            .select("*")
            .eq("group_id", value: groupId.uuidString)
            .execute()
            .value

        // Step 2: If there is a competition link, use it to fetch the actual competition
        guard let competitionLink = competitionLinks.first else {
            return nil // No competition linked to this group
        }

        // Fetch the actual competition
        let competitions: [GroupCompetition] = try await supabaseClient
            .from("group_competitions")
            .select("*")
            .eq("id", value: competitionLink.competition_id.uuidString)
            .execute()
            .value

        return competitions.first
    }

    private func fetchTotalUsersInGroupZum(_ groupId: UUID) async throws -> Int {
        let groupMembers: [GroupMember] = try await supabaseClient
            .from("group_members")
            .select("*")
            .eq("group_id", value: groupId.uuidString)
            .execute()
            .value

        return groupMembers.count
    }

    private func fetchTotalUsersInCompetitionZum(_ competitionId: UUID) async throws -> Int {
        let groupCompetitionLinks: [GroupCompetitionLink] = try await supabaseClient
            .from("group_competition_links")
            .select("*")
            .eq("competition_id", value: competitionId.uuidString)
            .execute()
            .value

        let groupIds = groupCompetitionLinks.map(\.group_id)

        var totalUsers = 0
        for groupId in groupIds {
            totalUsers += try await fetchTotalUsersInGroupZum(groupId)
        }

        return totalUsers
    }

//    private func calculateGlobalExitOrder(dateString: String, totalUsers: Int) async throws -> Int {
//        let exitCountResponse: [DailyZoneExit] = try await supabaseClient
//            .from("daily_zone_exits")
//            .select("*")
//            .eq("date", value: dateString)
//            .execute()
//            .value
//
//        return exitCountResponse.count + 1 // Next exit order
//    }

    private func calculateGlobalExitOrder(
        dateString: String,
        competitionId: UUID? = nil,
        groupId: UUID? = nil,
        totalUsers: Int
    ) async throws -> Int {
        var query = supabaseClient.from("daily_zone_exits").select("*").eq("date", value: dateString)

        if let competitionId {
            // Fetch group ids related to the competition
            let groupCompetitionLinks: [GroupCompetitionLink] = try await supabaseClient
                .from("group_competition_links")
                .select("*")
                .eq("competition_id", value: competitionId.uuidString)
                .execute()
                .value

            // Extract group_ids from the competition links
            let groupIds = groupCompetitionLinks.map(\.group_id.uuidString)

            // Fetch profiles of users belonging to these groups via the `group_members` table
            let groupMembers: [GroupMember] = try await supabaseClient
                .from("group_members")
                .select("*")
                .in("group_id", values: groupIds)
                .execute()
                .value

            let profileIds = groupMembers.map(\.profile_id.uuidString)

            // Now, fetch exits from `daily_zone_exits` where `profile_id` belongs to the group members
            let exitCountResponse: [DailyZoneExit] = try await supabaseClient
                .from("daily_zone_exits")
                .select("*")
                .in("profile_id", values: profileIds)
                .eq("date", value: dateString)
                .execute()
                .value

            return exitCountResponse.count + 1 // Next exit order based on exits for competition group members
        } else if let groupId {
            // Fetch profile ids of users in the specific group
            let groupMembers: [GroupMember] = try await supabaseClient
                .from("group_members")
                .select("*")
                .eq("group_id", value: groupId.uuidString)
                .execute()
                .value

            let profileIds = groupMembers.map(\.profile_id.uuidString)

            // Fetch exits from `daily_zone_exits` for this specific group
            let exitCountResponse: [DailyZoneExit] = try await supabaseClient
                .from("daily_zone_exits")
                .select("*")
                .in("profile_id", values: profileIds)
                .eq("date", value: dateString)
                .execute()
                .value

            return exitCountResponse.count + 1 // Next exit order for specific group members
        }

        // If no competitionId or groupId is provided, return based on overall total exits
        let exitCountResponse: [DailyZoneExit] = try await query.execute().value
        return exitCountResponse.count + 1 // General next exit order if no specific group/competition provided
    }

    private func calculatePoints(for exitOrder: Int, totalUsers: Int) -> Int {
        max(totalUsers - exitOrder, 0)
    }
}

extension ZoneUpdateManager {
    func fetchZone(for zoneId: UUID) async throws -> Zone {
        let zone: Zone = try await supabaseClient
            .from("zones")
            .select("*")
            .eq("id", value: zoneId.uuidString)
            .single()
            .execute()
            .value

        return zone
    }

    func hasAlreadyExitedToday(for profileId: UUID, zoneId: UUID, category: ZoneCategory?) async throws -> Bool {
        // Only perform the check for "home" zones
        if category == .home {
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let currentDateString = dateFormatter.string(from: Date())

            let existingExit: [DailyZoneExit] = try await supabaseClient
                .from("daily_zone_exits")
                .select("*")
                .eq("profile_id", value: profileId.uuidString)
                .eq("zone_id", value: zoneId.uuidString)
                .eq("date", value: currentDateString)
                .execute()
                .value

            return !existingExit.isEmpty
        }
        // If it's not a "home" zone, always return false
        return false
    }
}

extension ISO8601DateFormatter {
    static let shared: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
