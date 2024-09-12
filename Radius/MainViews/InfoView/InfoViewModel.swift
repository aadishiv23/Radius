//
//  InfoViewModel.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/11/24.
//

import Foundation

class FriendsViewModel: ObservableObject {
    @Published var friends: [Profile] = []
    @Published var userGroups: [Group] = []
    @Published var userCompetitions: [GroupCompetition] = []
    
    private let friendsRepository: FriendsRepository
    private let groupsRepository: GroupsRepository
    private let competitionsRepository: CompetitionsRepository
    private let userId: UUID
    
    init(
        friendsRepository: FriendsRepository,
        groupsRepository: GroupsRepository,
        competitionsRepository: CompetitionsRepository,
        userId: UUID
    ) {
        self.friendsRepository = friendsRepository
        self.groupsRepository = groupsRepository
        self.competitionsRepository = competitionsRepository
        self.userId = userId
        
        // Load initial data
        Task {
            await loadFriends()
            await loadGroups()
            await loadCompetitions()
        }
    }
    
    func loadFriends() async {
        do {
            let fetchedFriends = try await friendsRepository.fetchFriends(for: userId)
            DispatchQueue.main.async {
                self.friends = fetchedFriends
            }
        } catch {
            print("Error fetching friends: \(error)")
        }
    }
    
    func loadGroups() async {
        do {
            let fetchedGroups = try await groupsRepository.fetchGroups(for: userId)
            DispatchQueue.main.async {
                self.userGroups = fetchedGroups
            }
        } catch {
            print("Error fetching groups: \(error)")
        }
    }
    
    func loadCompetitions() async {
        do {
            let fetchedCompetitions = try await competitionsRepository.fetchCompetitions(for: userId)
            DispatchQueue.main.async {
                self.userCompetitions = fetchedCompetitions
            }
        } catch {
            print("Error fetching competitions: \(error)")
        }
    }
    
    func refreshAllData() async {
        await loadFriends()
        await loadGroups()
        await loadCompetitions()
    }
    
    func invalidateCache() {
        friendsRepository.invalidateFriendsCache(for: userId)
    }
}
