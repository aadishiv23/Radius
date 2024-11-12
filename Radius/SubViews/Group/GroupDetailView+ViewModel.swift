//
//  GroupViewModel.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 8/17/24.
//

import Foundation

// MARK: - GroupDetailView.ViewModel

extension GroupDetailView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var groupMembers: [Profile] = []
        @Published var isLoading = true

        private let friendsDataManager: FriendsDataManager
        
        private let group: Group
        private let groupsRepository: GroupsRepository


        init(group: Group, friendsDataManager: FriendsDataManager = FriendsDataManager(supabaseClient: supabase), groupsRepository: GroupsRepository = GroupsRepository.shared) {
            self.group = group
            self.friendsDataManager = friendsDataManager
            self.groupsRepository = groupsRepository
        }

        func fetchGroupMembers() {
            Task {
                do {
                    groupMembers = try await friendsDataManager.fetchGroupMembersProfiles(groupId: group.id)
                    isLoading = false
                } catch {
                    print("Error fetching group members: \(error)")
                    isLoading = false
                }
            }
        }
    }
}
