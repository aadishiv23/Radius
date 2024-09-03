//
//  CompetitionDetailViewModel.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/2/24.
//

import Foundation

class CompetitionDetailViewModel: ObservableObject {
    @Published var groups: [Group] = []
    @Published var playersInGroup: [UUID: [Profile]] = [:]
    @Published var totalUsers: Int = 0

    func fetchDetails(for competition: GroupCompetition) async {
        do {
            // Fetch all group competition links for the competition
            let groupCompetitionLinks: [GroupCompetitionLink] = try await supabase
                .from("group_competition_links")
                .select("*")
                .eq("competition_id", value: competition.id.uuidString)
                .execute()
                .value

            // Extract group IDs
            let groupIds = groupCompetitionLinks.map { $0.group_id }

            // Fetch all groups involved in the competition
            let groups: [Group] = try await supabase
                .from("groups")
                .select("*")
                .in("id", values: groupIds.map { $0.uuidString })
                .execute()
                .value

            DispatchQueue.main.async {
                self.groups = groups
                self.totalUsers = groups.count // Example: set total users count based on group count
            }

            // Fetch players in each group
            var playersInGroup: [UUID: [Profile]] = [:]
            for groupId in groupIds {
                // First, fetch the profile IDs
                let groupMembers: [GroupMember] = try await supabase
                    .from("group_members")
                    .select("*")
                    .eq("group_id", value: groupId.uuidString)
                    .execute()
                    .value

                // Extract profile IDs
                let profileIds = groupMembers.map { $0.profile_id.uuidString }

                // Fetch profiles using the extracted IDs
                let players: [Profile] = try await supabase
                    .from("profiles")
                    .select("*")
                    .in("id", values: profileIds)
                    .execute()
                    .value

                playersInGroup[groupId] = players
            }

            DispatchQueue.main.async {
                self.playersInGroup = playersInGroup
                self.totalUsers = playersInGroup.values.reduce(0) { $0 + $1.count }
            }
        } catch {
            print("Failed to fetch competition details: \(error)")
        }
    }
}
