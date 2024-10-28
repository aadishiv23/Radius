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
    @Published var groups: [Group] = []
     private var cache: [UUID: CachedData<[Group]>] = [:] // In-memory cache for groups
    private var cacheExpiration: TimeInterval = 300 // 5 minutes
    private let groupService: GroupService

    init(groupService: GroupService) {
        self.groupService = groupService
    }

    /// Fetch groups from cache or Supabase
    func fetchGroups(for userId: UUID) async throws -> [Group] {
        do {
            if let cachedData = cache[userId], !isCacheExpired(cachedData.timestamp) {
                return cachedData.data
            }

            let fetchedGroups = try await groupService.fetchUserGroups(for: userId)
            cache[userId] = CachedData(data: fetchedGroups, timestamp: Date())

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

    /// Invalidate cache for groups
    func invalidateGroupsCache(for userId: UUID) {
        cache.removeValue(forKey: userId)
    }

    /// Invalidate all cache (for example, on logout)
    func invalidateAllGroupsCache() {
        cache.removeAll()
    }

    /// Check if cache is expired
    private func isCacheExpired(_ timestamp: Date) -> Bool {
        return Date().timeIntervalSince(timestamp) > cacheExpiration
        //return false
    }

    /// Helper function to debug decoding errors
    private func debugPrintDecodingError(_ error: DecodingError) {
        switch error {
        case .typeMismatch(let type, let context):
            print("Type mismatch error: \(type), \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        case .valueNotFound(let type, let context):
            print("Value not found: \(type), \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        case .keyNotFound(let key, let context):
            print("Key not found: \(key), \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
            if let lastPath = context.codingPath.last {
                print("Missing key: \(lastPath.stringValue)")
            }
            // Additional debugging for key not found
            print("Debug context: \(context)")
        case .dataCorrupted(let context):
            print("Data corrupted: \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        @unknown default:
            print("Unknown decoding error: \(error)")
        }
    }
}
