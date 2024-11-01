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

    /// Search Functionality
    @Published var searchText = ""

    // Filtered Data
    @Published var filteredFriends: [Profile] = []
    @Published var filteredGroups: [Group] = []
    @Published var filteredCompetitions: [GroupCompetition] = []

    private var cancellables = Set<AnyCancellable>()

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

        // Observe changes to searchText and filter content accordingly
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main) // Debounce to improve performance
            .removeDuplicates()
            .sink { [weak self] query in
                self?.filterContent(searchQuery: query)
            }
            .store(in: &cancellables)
    }

    /// Fetch and refresh all data
    func refreshAllData() async throws {
        print("Starting to refresh all data with TaskGroup...")

        var fetchedFriends: [Profile] = []
        var fetchedGroups: [Group] = []
        var fetchedCompetitions: [GroupCompetition] = []

        do {
            try await withTaskGroup(of: (String, Result<Any, Error>).self) { group in
                // Add friends fetching task
                group.addTask {
                    let result: Result<[Profile], Error> = await Result {
                        try await self.friendsRepository.fetchFriends(for: self.userId)
                    }
                    return ("friends", result.map { $0 as Any })
                }

                // Add groups fetching task
                group.addTask {
                    let result: Result<[Group], Error> = await Result {
                        try await self.groupsRepository.fetchGroups(for: self.userId)
                    }
                    return ("groups", result.map { $0 as Any })
                }

                // Add competitions fetching task
                group.addTask {
                    let result: Result<[GroupCompetition], Error> = await Result {
                        try await self.competitionsRepository.fetchCompetitions(for: self.userId)
                    }
                    return ("competitions", result.map { $0 as Any })
                }

                // Process each result as it completes
                for await (type, result) in group {
                    await MainActor.run {
                        switch (type, result) {
                        case let ("friends", .success(friends)):
                            fetchedFriends = friends as! [Profile]
                        case let ("groups", .success(groups)):
                            fetchedGroups = groups as! [Group]
                        case let ("competitions", .success(competitions)):
                            fetchedCompetitions = competitions as! [GroupCompetition]
                        case let (_, .failure(error)):
                            print("Failed to fetch \(type): \(error.localizedDescription)")
                        default:
                            break
                        }
                    }
                }
            }

            // Update all published properties on the main thread
            await MainActor.run {
                self.friends = fetchedFriends
                self.userGroups = fetchedGroups
                self.userCompetitions = fetchedCompetitions

                // Apply initial filter based on search text
                self.filterContent(searchQuery: self.searchText)
            }

            print("Successfully refreshed all data with TaskGroup.")
        } catch {
            print("Error refreshing data in TaskGroup: \(error.localizedDescription)")
            throw error // Propagate error to let the caller handle it
        }
    }

    /// Filter content based on search query
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
            filteredCompetitions = userCompetitions
                .filter { $0.competition_name.lowercased().contains(lowercasedQuery) }
        }
    }

    func invalidateCache() {
        friendsRepository.invalidateFriendsCache(for: userId)
        groupsRepository.invalidateGroupsCache(for: userId)
        competitionsRepository.invalidateCompetitionsCache(for: userId)
    }
}
