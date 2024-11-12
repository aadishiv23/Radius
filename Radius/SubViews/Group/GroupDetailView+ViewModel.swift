//
//  GroupDetailView+ViewModel.swift
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
        @Published var currentRules: GroupRule?
        @Published var isLoadingRules = true

        private let friendsDataManager: FriendsDataManager

        private let group: Group
        private let groupsRepository: GroupsRepository

        init(
            group: Group,
            friendsDataManager: FriendsDataManager = FriendsDataManager(supabaseClient: supabase),
            groupsRepository: GroupsRepository = GroupsRepository.shared
        ) {
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

        /// Create Group Rules
        func createGroupRules(countZoneExit: Bool, maxExitsAllowed: Int, allowedZoneCategories: [ZoneCategory]) {
            Task {
                do {
                    // Initialize a groupRule
                    let groupRule = GroupRule(
                        groupId: group.id,
                        countZoneExits: countZoneExit,
                        maxExitsAllowed: maxExitsAllowed,
                        allowedZoneCategories: allowedZoneCategories
                    )
                    try await groupsRepository.createGroupRules(groupId: group.id.uuidString, groupRule: groupRule)
                    print("[GroupDetailView+ViewModel] - Successfully created group rules for group: \(group.id)")
                } catch {
                    print("[GroupDetailView+ViewModel] - Error creating group rules: \(error)")
                }
            }
        }

        func fetchCurrentRules() {
            Task {
                isLoadingRules = true
                do {
                    currentRules = try await groupsRepository.fetchGroupRules(groupId: group.id.uuidString)
                } catch {
                    print("Error fetching group rules: \(error)")
                }
                isLoadingRules = false
            }
        }

        func saveGroupRules(countZoneExit: Bool, maxExitsAllowed: Int, allowedZoneCategories: [ZoneCategory]) {
            Task {
                do {
                    let groupRule = GroupRule(
                        id: currentRules?.id ?? UUID(), // Use existing ID if updating
                        groupId: group.id,
                        countZoneExits: countZoneExit,
                        maxExitsAllowed: maxExitsAllowed,
                        allowedZoneCategories: allowedZoneCategories
                    )

                    if currentRules != nil {
                        try await groupsRepository.updateGroupRules(groupId: group.id.uuidString, groupRule: groupRule)
                        print("[GroupDetailView+ViewModel] - Successfully updated group rules for group: \(group.id)")
                    } else {
                        try await groupsRepository.createGroupRules(groupId: group.id.uuidString, groupRule: groupRule)
                        print("[GroupDetailView+ViewModel] - Successfully created group rules for group: \(group.id)")
                    }

                    // Update current rules after successful save
                    currentRules = groupRule

                } catch {
                    print("[GroupDetailView+ViewModel] - Error saving group rules: \(error)")
                }
            }
        }
    }
}
