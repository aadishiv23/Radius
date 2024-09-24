//
//  FriendsRepository.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/11/24.
//

import Foundation
import Supabase

class FriendsRepository: ObservableObject {
    @Published var friends: [Profile] = []
    @Published var currentUser: Profile? = nil

    private var cache: [UUID: CachedData<[Profile]>] = [:]
    private var cacheExpiration: TimeInterval = 300 // 5 minutes
    private let friendService: FriendService
    private var userId: UUID?

    init(friendService: FriendService) {
        self.friendService = friendService
    }
    
    /// Fetch friends from cache or supabase
    func fetchFriends(for userId: UUID) async throws -> [Profile] {
        if let cachedData = cache[userId], !isCacheExpired(cachedData.timestamp) {
            return cachedData.data
        }
        
        let fetchedFriends = try await friendService.fetchFriends(for: userId)
        cache[userId] = CachedData(data: fetchedFriends, timestamp: Date())
        
        DispatchQueue.main.async {
            self.friends = fetchedFriends
        }
        
        return fetchedFriends
    }
    
    /// Invalidate cache for friends
    func invalidateFriendsCache(for userId: UUID) {
        cache.removeValue(forKey: userId)
    }
    
    // Invalidate all cache (for example, on logout)
    func invalidateAllFriendsCache() {
        cache.removeAll()
    }
    
    func fetchCurrentUser() async throws -> Profile? {
//        if let currentUser = currentUser {
//            return currentUser
//        }
        
        let fetchedUser = try await friendService.fetchCurrentUserProfile()
        currentUser = fetchedUser
        
        return fetchedUser
    }
    
    // Check if cache is expired
    private func isCacheExpired(_ timestamp: Date) -> Bool {
        return Date().timeIntervalSince(timestamp) > cacheExpiration
    }
}
