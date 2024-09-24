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

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)! // UTC
        let startOfDay = calendar.startOfDay(for: time)

        do {
            // Fetch the user's groups
            let userGroups = try await fetchUserGroupsZum(for: profileId)
            var globalExitOrder = 1
            var totalUsers = 0
            var competitionExists = false

            for group in userGroups {
                if let competition = try await fetchCompetitionZum(for: group.group_id) {
                    competitionExists = true
                    // Calculate total users in the competition (across groups)
                    totalUsers = try await fetchTotalUsersInCompetitionZum(competition.id)
                    globalExitOrder = try await calculateGlobalExitOrder(dateString: currentDateString, competitionId: competition.id, totalUsers: totalUsers)
                    break
                }
            }

            if !competitionExists {
                // No competition, calculate based on group members only
                for group in userGroups {
                    totalUsers = try await fetchTotalUsersInGroupZum(group.group_id)
                    globalExitOrder = try await calculateGlobalExitOrder(dateString: currentDateString, groupId: group.group_id, totalUsers: totalUsers)
                }
            }

            // For each zone, calculate points and insert into daily_zone_exits
            for zoneId in zoneIds {
                let exitOrder = globalExitOrder
                let pointsEarned = calculatePoints(for: exitOrder, totalUsers: totalUsers)

                // Fetch the corresponding `zone_exit_id` from the previous insertion
                let insertedZoneExit: ZoneExit = try await supabaseClient
                    .from("zone_exits")
                    .select("*")
                    .eq("profile_id", value: profileId.uuidString)
                    .eq("zone_id", value: zoneId.uuidString)
                    .order("exit_time", ascending: false)
                    .limit(1)
                    .single()
                    .execute()
                    .value

                let dailyZoneExit = DailyZoneExit(
                    id: UUID(),
                    date: startOfDay,
                    profile_id: profileId,
                    zone_exit_id: insertedZoneExit.id,
                    exit_order: exitOrder,
                    points_earned: pointsEarned
                )

                try await supabaseClient
                    .from("daily_zone_exits")
                    .insert(dailyZoneExit)
                    .execute()

                globalExitOrder += 1
            }

            print("Daily zone exit recorded successfully.")
        } catch {
            print("Failed to handle daily zone exits: \(error)")
            throw error
        }
    }

    private func fetchUserGroupsZum(for profileId: UUID) async throws -> [GroupMember] {
        let userGroups: [GroupMember] = try await supabaseClient
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

        let groupIds = groupCompetitionLinks.map { $0.group_id }

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

    private func calculateGlobalExitOrder(dateString: String, competitionId: UUID? = nil, groupId: UUID? = nil, totalUsers: Int) async throws -> Int {
        var query = supabaseClient.from("daily_zone_exits").select("*").eq("date", value: dateString)

        if let competitionId = competitionId {
            // Fetch exits across all groups in the competition
            let groupCompetitionLinks: [GroupCompetitionLink] = try await supabaseClient
                .from("group_competition_links")
                .select("*")
                .eq("competition_id", value: competitionId.uuidString)
                .execute()
                .value

            let groupIds = groupCompetitionLinks.map { $0.group_id.uuidString }
            query = query.in("group_id", values: groupIds)
        } else if let groupId = groupId {
            // Fetch exits for a specific group
            query = query.eq("group_id", value: groupId.uuidString)
        }

        let exitCountResponse: [DailyZoneExit] = try await query.execute().value
        return exitCountResponse.count + 1 // Next exit order
    }

    private func calculatePoints(for exitOrder: Int, totalUsers: Int) -> Int {
        return max(totalUsers - exitOrder, 0)
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
