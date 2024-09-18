//
//  InfoViewModel.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/11/24.
//

import Foundation

//
// class InfoViewModel: ObservableObject {
//    @Published var friends: [Profile] = []
//    @Published var userGroups: [Group] = []
//    @Published var userCompetitions: [GroupCompetition] = []
//
//    private let friendsRepository: FriendsRepository
//    private let groupsRepository: GroupsRepository
//    private let competitionsRepository: CompetitionsRepository
//    private let userId: UUID
//
////    @Published var searchText: String = ""
////
////    private var cancellables = Set<AnyCancellable>()
//
//    init(
//        friendsRepository: FriendsRepository,
//        groupsRepository: GroupsRepository,
//        competitionsRepository: CompetitionsRepository,
//        userId: UUID
//    ) {
//        self.friendsRepository = friendsRepository
//        self.groupsRepository = groupsRepository
//        self.competitionsRepository = competitionsRepository
//        self.userId = userId
//
//        // Observe searchText changes to filter content
////        $searchText
////            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
////            .removeDuplicates()
////            .sink { [weak self] query in
////                self?.filterContent(searchQuery: query)
////            }
////            .store(in: &cancellables)
//
//        // Load initial data
//        Task {
//            await loadFriends()
//            await loadGroups()
//            await loadCompetitions()
//        }
//    }
//
//    func loadFriends() async {
//        do {
//            let fetchedFriends = try await friendsRepository.fetchFriends(for: userId)
//            await MainActor.run {
//                self.friends = fetchedFriends
//            }
//        } catch {
//            print("Error fetching friends: \(error)")
//        }
//    }
//
//    func loadGroups() async {
//        do {
//            let fetchedGroups = try await groupsRepository.fetchGroups(for: userId)
//            await MainActor.run {
//                self.userGroups = fetchedGroups
//            }
//        } catch {
//            print("Error fetching groups: \(error)")
//        }
//    }
//
//    func loadCompetitions() async {
//        do {
//            let fetchedCompetitions = try await competitionsRepository.fetchCompetitions(for: userId)
//            await MainActor.run {
//                self.userCompetitions = fetchedCompetitions
//            }
//        } catch {
//            print("Error fetching competitions: \(error)")
//        }
//    }
//
//    func refreshAllData() async {
//        await loadFriends()
//        await loadGroups()
//        await loadCompetitions()
//    }
//
//    func invalidateCache() {
//        friendsRepository.invalidateFriendsCache(for: userId)
//        groupsRepository.invalidateGroupsCache(for: userId)
//        competitionsRepository.invalidateCompetitionsCache(for: userId)
//    }
// }

import Combine
import Foundation

class InfoViewModel: ObservableObject {
    private var friendsRepository: FriendsRepository
    private var groupsRepository: GroupsRepository
    private var competitionsRepository: CompetitionsRepository
    private var userId: UUID
    
    // Original Data
    @Published var friends: [Profile] = []
    @Published var userGroups: [Group] = []
    @Published var userCompetitions: [GroupCompetition] = []
    
    // Search Functionality
    @Published var searchText: String = ""
    
    // Filtered Data
    @Published var filteredFriends: [Profile] = []
    @Published var filteredGroups: [Group] = []
    @Published var filteredCompetitions: [GroupCompetition] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init(friendsRepository: FriendsRepository, groupsRepository: GroupsRepository, competitionsRepository: CompetitionsRepository, userId: UUID) {
        self.friendsRepository = friendsRepository
        self.groupsRepository = groupsRepository
        self.competitionsRepository = competitionsRepository
        self.userId = userId
        
        // Observe changes to searchText and filter content accordingly
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main) // Debounce to improve performance
            .removeDuplicates()
            .sink { [weak self] query in
                self?.filterContent(searchQuery: query)
            }
            .store(in: &cancellables)
    }
    
    // Fetch and refresh all data
    func refreshAllData() async throws {
        async let fetchedFriends = friendsRepository.fetchFriends(for: userId)
        async let fetchedGroups = groupsRepository.fetchGroups(for: userId)
        async let fetchedCompetitions = competitionsRepository.fetchCompetitions(for: userId)
        
        let (friends, groups, competitions) = try await (fetchedFriends, fetchedGroups, fetchedCompetitions)
        
        await MainActor.run {
            self.friends = friends
            self.userGroups = groups
            self.userCompetitions = competitions
            
            // Initialize filtered data
            self.filterContent(searchQuery: self.searchText)
        }
    }
    
    // Filter content based on search query
    func filterContent(searchQuery: String) {
        if searchQuery.isEmpty {
            // If search query is empty, show all original data
            filteredFriends = friends
            filteredGroups = userGroups
            filteredCompetitions = userCompetitions
        } else {
            let lowercasedQuery = searchQuery.lowercased()
            filteredFriends = friends.filter { $0.full_name.lowercased().contains(lowercasedQuery) }
            filteredGroups = userGroups.filter { $0.name.lowercased().contains(lowercasedQuery) }
            filteredCompetitions = userCompetitions.filter { $0.competition_name.lowercased().contains(lowercasedQuery) }
        }
    }
    
    func invalidateCache() {
        friendsRepository.invalidateFriendsCache(for: userId)
        groupsRepository.invalidateGroupsCache(for: userId)
        competitionsRepository.invalidateCompetitionsCache(for: userId)
    }
}
