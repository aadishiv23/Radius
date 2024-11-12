//
//  GroupsRepository.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/11/24.
//

import Foundation
import Supabase

// TODO: make published
class GroupsRepository: ObservableObject {
    static let shared = GroupsRepository(groupService: GroupService(supabaseClient: supabase))
    @Published var groups: [Group] = []
    private var cache: [String: CachedData<[Group]>] = [:] // In-memory cache for groups
    private var cacheExpiration: TimeInterval = 300 // 5 minutes
    private let groupService: GroupService

    init(groupService: GroupService = GroupService(supabaseClient: supabase)) {
        self.groupService = groupService
    }

    /// Fetch groups from cache or Supabase
    func fetchGroups(for userId: UUID) async throws -> [Group] {
        let userIdString = userId.uuidString // Convert UUID to String for cache key

        do {
            if let cachedData = cache[userIdString], !isCacheExpired(cachedData.timestamp) {
                return cachedData.data
            }

            let fetchedGroups = try await groupService.fetchUserGroups(for: userId)
            cache[userIdString] = CachedData(data: fetchedGroups, timestamp: Date())

            DispatchQueue.main.async {
                self.groups = fetchedGroups
            }
            return fetchedGroups

        } catch let error as PostgrestError {
            print("Supabase error while fetching groups: \(error.localizedDescription)")
            throw error
        } catch let error as URLError {
            if error.code == .timedOut {
                print("Network timeout: \(error.localizedDescription)")
            } else {
                print("URLError: \(error.localizedDescription)")
            }
            throw error
        } catch let error as DecodingError {
            debugPrintDecodingError(error)
            throw error
        } catch {
            print("Unexpected error while fetching groups: \(error.localizedDescription)")
            throw error
        }
    }

    func createGroupRules(groupId: String, groupRule: GroupRule) async throws {
        do {
            try await groupService.createGroupRules(groupId: groupId, groupRule: groupRule)
            print("[GroupsRepository] - Successfully created group rules for group: \(groupId)")
        } catch let error as PostgrestError {
            print("Supabase error while creating group rules: \(error.localizedDescription)")
            throw error
        } catch {
            print("Unexpected error while creating group rules: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchGroupRules(groupId: String) async throws -> GroupRule {
        do {
            let groupRules = try await groupService.fetchGroupRules(for: groupId)
            print("[GroupsRepository] - Successfully fetched group rules for group: \(groupId)")
            return groupRules
        } catch let error as PostgrestError {
            print("[GroupsRepository] - PostgrestError while fetching group rules: \(error.localizedDescription)")
            throw error
        } catch {
            print("[GroupsRepository] - Unexpected error while fetching group rules: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateGroupRules(groupId: String, groupRule: GroupRule) async throws {
        do {
            try await groupService.updateGroupRules(groupId: groupId, groupRule: groupRule)
            print("[GroupRepository] {updateGroupRules} - Successfully updated group rules for group: \(groupId)")
        } catch {
            print("[GroupsRepository] - updateGroupRules: \(error.localizedDescription)")
        }
    }

    /// Invalidate cache for groups
    func invalidateGroupsCache(for userId: UUID) {
        cache.removeValue(forKey: userId.uuidString)
    }

    /// Invalidate all cache (for example, on logout)
    func invalidateAllGroupsCache() {
        cache.removeAll()
    }

    /// Check if cache is expired
    private func isCacheExpired(_ timestamp: Date) -> Bool {
        Date().timeIntervalSince(timestamp) > cacheExpiration
    }

    /// Helper function to debug decoding errors
    private func debugPrintDecodingError(_ error: DecodingError) {
        switch error {
        case let .typeMismatch(type, context):
            print("Type mismatch error: \(type), \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        case let .valueNotFound(type, context):
            print("Value not found: \(type), \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        case let .keyNotFound(key, context):
            print("Key not found: \(key), \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
            if let lastPath = context.codingPath.last {
                print("Missing key: \(lastPath.stringValue)")
            }
            print("Debug context: \(context)")
        case let .dataCorrupted(context):
            print("Data corrupted: \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        @unknown default:
            print("Unknown decoding error: \(error)")
        }
    }
}
