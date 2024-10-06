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
    @Published var memberDailyPoints: [UUID: [DailyPoint]] = [:]
    
    // New Published Property for Combined Daily Points
    @Published var combinedDailyPoints: [CombinedDailyPoint] = []
    
    var friendsDataManager: FriendsDataManager
    let competitionManager: CompetitionManager
    private var cancellables = Set<AnyCancellable>()
    
    init(friendsDataManager: FriendsDataManager, competitionManager: CompetitionManager) {
        self.friendsDataManager = friendsDataManager
        self.competitionManager = competitionManager
        setupBindings()
        
        // Fetch competitions upon initialization
        Task {
            do {
                try await self.competitionManager.fetchCompetitions()
            } catch {
                print("Failed to fetch competitions: \(error)")
            }
        }
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
                
                // Prepare date formatter
                let dateFormatter = DateFormatter()
                dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let currentDateString = dateFormatter.string(from: Date())
                
                // Fetch today's points for all profiles at once
                let profileIds = profiles.map(\.id)
                let pointsMap = try await competitionManager.fetchPointsForProfiles(
                    profileIds: profileIds,
                    dateString: currentDateString
                )
                
                for profile in profiles {
                    let points = pointsMap[profile.id] ?? 0
                    let member = LeaderboardMember(id: profile.id, name: profile.full_name, points: points)
                    leaderboardMembers.append(member)
                }
                
                // Sort members
                leaderboardMembers.sort { $0.points > $1.points }
                
                // Fetch daily points for top 5 members
                let topMemberIds = leaderboardMembers.prefix(5).map(\.id)
                let dailyPointsMap = try await competitionManager.fetchDailyPointsForProfiles(profileIds: topMemberIds)
                
                DispatchQueue.main.async {
                    self.members = leaderboardMembers
                    self.memberDailyPoints = dailyPointsMap
                    self.aggregateDailyPoints() // Aggregate after fetching
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
                    let points = try await competitionManager.fetchCompetitionPoints(
                        for: competitor.profile_id,
                        competitionId: competitionId
                    )
                    
                    let member = LeaderboardMember(
                        id: competitor.profile_id,
                        name: competitor.profile_name ?? "Unknown",
                        groupName: competitor.group_name ?? "Unknown",
                        points: points
                    )
                    leaderboardMembers.append(member)
                }
                
                DispatchQueue.main.async {
                    self.members = leaderboardMembers.sorted { $0.points > $1.points }
                    self.aggregateDailyPoints() // If needed for competitions
                }
            } catch {
                print("Failed to fetch competition leaderboard data: \(error)")
            }
        }
    }
    
    // New Method to Aggregate Daily Points
    private func aggregateDailyPoints() {
        let topMembers = members.prefix(5)
        var combinedPoints: [CombinedDailyPoint] = []
        
        for member in topMembers {
            if let dailyPoints = memberDailyPoints[member.id] {
                for point in dailyPoints {
                    combinedPoints.append(
                        CombinedDailyPoint(
                            memberName: member.name,
                            date: point.date,
                            points: point.points
                        )
                    )
                }
            }
        }
        
        // Sort the combined points by date
        combinedPoints.sort { $0.date < $1.date }
        
        DispatchQueue.main.async {
            self.combinedDailyPoints = combinedPoints
        }
    }
}

enum LeaderboardCategory: String, CaseIterable {
    case groups = "Groups"
    case competitions = "Competitions"
}
