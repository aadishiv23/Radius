//
//  FriendsRepository.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/11/24.
//

import Foundation
import Supabase

class FriendsRepository {
    private var cache: [UUID: CachedData<[Profile]>] = [:]
    private var cacheExpiration: TimeInterval = 300
    private var supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    /// Fetch friends from cache or supabase
    func fetchFriends(for userId: UUID) async throws -> [Profile] {
            // Check if data is cached and not expired
            if let cachedData = cache[userId], !isCacheExpired(cachedData.timestamp) {
                return cachedData.data
            }
            
            // If no valid cache, fetch data from Supabase
            let friends: [Profile] = try await supabaseClient
                .from("friends")
                .select("profile_id2, profiles!inner(*)")
                .eq("profile_id1", value: userId.uuidString)
                .execute()
                .value
            
            // Cache the result with the current timestamp
            cache[userId] = CachedData(data: friends, timestamp: Date())
            
            return friends
        }
    
    /// Invalidate cache for friends
    func invalidateFriendsCache(for userId: UUID) {
        cache.removeValue(forKey: userId)
    }
    
    // Invalidate all cache (for example, on logout)
    func invalidateAllFriendsCache() {
        cache.removeAll()
    }
    
    // Check if cache is expired
    private func isCacheExpired(_ timestamp: Date) -> Bool {
        return Date().timeIntervalSince(timestamp) > cacheExpiration
    }
}
