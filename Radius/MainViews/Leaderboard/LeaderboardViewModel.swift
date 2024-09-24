//
//  LeaderboardViewModel.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/23/24.
//

import Combine
import Foundation

class LeaderboardViewModel: ObservableObject {
    @Published var selectedCategory: LeaderboardCategory = .groups
    @Published var selectedGroup: Group?
    @Published var selectedCompetition: GroupCompetition?
    @Published var members: [LeaderboardMember] = []
    
    var friendsDataManager: FriendsDataManager
    let competitionManager: CompetitionManager
    private var cancellables = Set<AnyCancellable>()
    
    init(friendsDataManager: FriendsDataManager, competitionManager: CompetitionManager) {
        self.friendsDataManager = friendsDataManager
        self.competitionManager = competitionManager
        setupBindings()
    }
    
    private func setupBindings() {
        // Update leaderboard data whenever selected category or group/competition changes
        $selectedCategory
            .sink { [weak self] _ in
                self?.fetchLeaderboardData()
            }
            .store(in: &cancellables)
        
        $selectedGroup
            .sink { [weak self] _ in
                self?.fetchLeaderboardData()
            }
            .store(in: &cancellables)
        
        $selectedCompetition
            .sink { [weak self] _ in
                self?.fetchLeaderboardData()
            }
            .store(in: &cancellables)
    }
    
    func fetchLeaderboardData() {
        switch selectedCategory {
        case .groups:
            if let group = selectedGroup {
                fetchGroupLeaderboard(groupId: group.id)
            }
        case .competitions:
            if let competition = selectedCompetition {
                fetchCompetitionLeaderboard(competitionId: competition.id)
            }
        }
    }
    
    func fetchGroupLeaderboard(groupId: UUID) {
        Task {
            do {
                let profiles = try await friendsDataManager.fetchGroupMembersProfiles(groupId: groupId)
                var leaderboardMembers: [LeaderboardMember] = []
                print("Fetched profiles for group \(groupId): \(profiles)") // Add this to check profiles

                // Use a for loop to handle async mapping
                for profile in profiles {
                    let points = try await competitionManager.fetchDailyPoints(from: Date(), for: profile.id)
                    let member = LeaderboardMember(id: profile.id, name: profile.full_name, points: points)
                    leaderboardMembers.append(member)
                }
                
                DispatchQueue.main.async {
                    self.members = leaderboardMembers.sorted { $0.points > $1.points }
                }
            } catch {
                print("Failed to fetch group leaderboard data: \(error)")
            }
        }
    }

    func fetchCompetitionLeaderboard(competitionId: UUID) {
        Task {
            do {
                let groupCompetitors = try await competitionManager.fetchCompetitors(for: competitionId)
                var leaderboardMembers: [LeaderboardMember] = []
                
                // Use a for loop to handle async mapping
                for competitor in groupCompetitors {
                    let points = try await competitionManager.fetchCompetitionPoints(for: competitor.profile_id, competitionId: competitionId)
                    
                    let member = LeaderboardMember(
                        id: competitor.profile_id,
                        name: competitor.profile_name ?? "Unknown", // Now using the profile_name
                        groupName: competitor.group_name ?? "Unknown", // Now using the group_name
                        points: points
                    )
                    leaderboardMembers.append(member)
                }
                
                DispatchQueue.main.async {
                    self.members = leaderboardMembers.sorted { $0.points > $1.points }
                }
            } catch {
                print("Failed to fetch competition leaderboard data: \(error)")
            }
        }
    }
}

enum LeaderboardCategory: String, CaseIterable {
    case groups = "Groups"
    case competitions = "Competitions"
}
