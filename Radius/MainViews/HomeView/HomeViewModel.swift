//
//  HomeViewModel.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/23/24.
//

import Combine
import Foundation
import MapKit

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var friends: [Profile] = []
    @Published var currentUser: Profile?
    @Published var userGroups: [Group] = []
    @Published var pendingRequests: [FriendRequest] = []
    @Published var searchText: String = ""
        
    // MARK: - Dependencies

    private let friendsRepository: FriendsRepository
    private let groupsRepository: GroupsRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization

    init(friendsRepository: FriendsRepository,
         groupsRepository: GroupsRepository)
    {
        self.friendsRepository = friendsRepository
        self.groupsRepository = groupsRepository
        
        setupBindings()
        Task {
            await refreshAllData()
        }
    }
    
    // MARK: - Setup Bindings

    private func setupBindings() {
        // Example: Bind friends from repository to ViewModel
        friendsRepository.$friends
            .receive(on: DispatchQueue.main)
            .assign(to: \.friends, on: self)
            .store(in: &cancellables)
        
        // Similarly, bind groups and competitions
        groupsRepository.$groups
            .receive(on: DispatchQueue.main)
            .assign(to: \.userGroups, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Data Fetching

    func refreshAllData() async {
        do {
            // Fetch current user profile
            currentUser = try await friendsRepository.fetchCurrentUser()
            guard let userId = currentUser?.id else { return }
            
            // Fetch Friends
            friends = try await friendsRepository.fetchFriends(for: userId)
            
            // Fetch Groups
            userGroups = try await groupsRepository.fetchGroups(for: userId)
        } catch {
            print("Error refreshing data: \(error)")
            // Handle errors appropriately (e.g., show alerts)
        }
    }
    
    // MARK: - Additional Methods
    
    // Add more methods as needed
}
