//
//  GroupsRepository.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/11/24.
//

import Foundation
import Supabase

/// TODO: make published
class GroupsRepository: ObservableObject {
    @Published var groups: [Group] = []
    private var cache: [UUID: CachedData<[Group]>] = [:] // In-memory cache for groups
    private var cacheExpiration: TimeInterval = 300 // 5 minutes
    private let groupService: GroupService

    
    init(groupService: GroupService) {
        self.groupService = groupService
    }
    
    // Fetch groups from cache or Supabase
    func fetchGroups(for userId: UUID) async throws -> [Group] {
        if let cachedData = cache[userId], !isCacheExpired(cachedData.timestamp) {
            return cachedData.data
        }
        
        let fetchedGroups = try await groupService.fetchUserGroups(for: userId)
        cache[userId] = CachedData(data: fetchedGroups, timestamp: Date())

        DispatchQueue.main.async {
            self.groups = fetchedGroups
        }
        return fetchedGroups
    }
    
    // Invalidate cache for groups
    func invalidateGroupsCache(for userId: UUID) {
        cache.removeValue(forKey: userId)
    }
        
    // Invalidate all cache (for example, on logout)
    func invalidateAllGroupsCache() {
        cache.removeAll()
    }
    
    // Check if cache is expired
    private func isCacheExpired(_ timestamp: Date) -> Bool {
        return Date().timeIntervalSince(timestamp) > cacheExpiration
    }
}

