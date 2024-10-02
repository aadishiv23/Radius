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
        do {
            if let cachedData = cache[userId], !isCacheExpired(cachedData.timestamp) {
                return cachedData.data
            }

            let fetchedFriends = try await friendService.fetchFriends(for: userId)
            cache[userId] = CachedData(data: fetchedFriends, timestamp: Date())

            DispatchQueue.main.async {
                self.friends = fetchedFriends
            }
            return fetchedFriends

        } catch let error as PostgrestError {
            print("Supabase error while fetching friends: \(error.localizedDescription)")
            throw error
        } catch let error as URLError {
            if error.code == .timedOut {
                print("Network timeout: \(error.localizedDescription)")
            } else {
                print("URLError: \(error.localizedDescription)")
            }
            throw error
        } catch {
            print("Unexpected error while fetching friends 2: \(error.localizedDescription)")
            throw error
        }
    }

    /// Invalidate cache for friends
    func invalidateFriendsCache(for userId: UUID) {
        cache.removeValue(forKey: userId)
    }

    /// Invalidate all cache (for example, on logout)
    func invalidateAllFriendsCache() {
        cache.removeAll()
    }

    @MainActor
    func fetchCurrentUser() async throws -> Profile? {
        do {
            let fetchedUser = try await friendService.fetchCurrentUserProfile()
            currentUser = fetchedUser
            return fetchedUser

        } catch let error as PostgrestError {
            print("Supabase error while fetching current user: \(error.localizedDescription)")
            throw error
        } catch let error as URLError {
            if error.code == .timedOut {
                print("Network timeout: \(error.localizedDescription)")
            } else {
                print("URLError: \(error.localizedDescription)")
            }
            throw error
        } catch {
            print("Unexpected error while fetching current user: \(error.localizedDescription)")
            throw error
        }
    }

    /// Check if cache is expired
    private func isCacheExpired(_ timestamp: Date) -> Bool {
        Date().timeIntervalSince(timestamp) > cacheExpiration
    }
}
