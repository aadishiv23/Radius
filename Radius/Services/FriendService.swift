//
//  FriendService.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/12/24.
//

import Foundation
import Supabase

class FriendService {
    private let supabaseClient: SupabaseClient
    private var userId: UUID?

    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }

    func fetchCurrentUserProfile() async throws -> Profile {
        let user = try await supabase.auth.session.user
        userId = user.id

        let profile: Profile = try await supabase
            .from("profiles")
            .select("*, zones(*)") // Ensure zones are included in the query
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        return profile
    }

    /// Method to fetch friends from Supabase
    func fetchFriends(for userId: UUID) async throws -> [Profile] {
        do {
            let friendRelations: [FriendRelation] = try await supabaseClient
                .from("friends")
                .select("*")
                .or("profile_id1.eq.\(userId.uuidString),profile_id2.eq.\(userId.uuidString)")
                .execute()
                .value

            let friendIds = Set(friendRelations.compactMap { relation -> UUID? in
                if relation.profile_id1 == userId {
                    return relation.profile_id2
                } else if relation.profile_id2 == userId {
                    return relation.profile_id1
                }
                return nil
            })

            let friendProfiles: [Profile] = try await supabaseClient
                .from("profiles")
                .select("*, zones(*)")
                .in("id", values: friendIds.map(\.uuidString))
                .execute()
                .value

            return friendProfiles

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
            print("Unexpected error while fetching friends 1: \(error.localizedDescription)")
            throw error
        }
    }

    func sendFriendRequest(to receiverId: UUID, from senderId: UUID) async throws {
        do {
            try await supabaseClient
                .from("friend_requests")
                .insert([
                    "sender_id": senderId.uuidString,
                    "receiver_id": receiverId.uuidString,
                    "status": "pending"
                ])
                .execute()

        } catch let error as PostgrestError {
            print("Supabase error while sending friend request: \(error.localizedDescription)")
            throw error
        } catch let error as URLError {
            if error.code == .timedOut {
                print("Network timeout: \(error.localizedDescription)")
            } else {
                print("URLError: \(error.localizedDescription)")
            }
            throw error
        } catch {
            print("Unexpected error while sending friend request: \(error.localizedDescription)")
            throw error
        }
    }

    func acceptFriendRequest(_ request: FriendRequest) async throws {
        do {
            try await supabaseClient
                .from("friend_requests")
                .update(["status": "accepted"])
                .eq("id", value: request.id.uuidString)
                .execute()

            try await supabaseClient
                .from("friends")
                .insert([
                    ["profile_id1": request.sender_id.uuidString, "profile_id2": request.receiver_id.uuidString],
                    ["profile_id1": request.receiver_id.uuidString, "profile_id2": request.sender_id.uuidString]
                ])
                .execute()

        } catch let error as PostgrestError {
            print("Supabase error while accepting friend request: \(error.localizedDescription)")
            throw error
        } catch let error as URLError {
            if error.code == .timedOut {
                print("Network timeout: \(error.localizedDescription)")
            } else {
                print("URLError: \(error.localizedDescription)")
            }
            throw error
        } catch {
            print("Unexpected error while accepting friend request: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchPendingRequests(for userId: UUID) async throws -> [FriendRequest] {
        do {
            return try await supabaseClient
                .from("friend_requests")
                .select("*")
                .eq("receiver_id", value: userId.uuidString)
                .eq("status", value: "pending")
                .execute()
                .value

        } catch let error as PostgrestError {
            print("Supabase error while fetching pending requests: \(error.localizedDescription)")
            throw error
        } catch let error as URLError {
            if error.code == .timedOut {
                print("Network timeout: \(error.localizedDescription)")
            } else {
                print("URLError: \(error.localizedDescription)")
            }
            throw error
        } catch {
            print("Unexpected error while fetching pending requests: \(error.localizedDescription)")
            throw error
        }
    }

    func deleteFriend(friendId: UUID) async throws {
        do {
            try await supabaseClient
                .from("friends")
                .delete()
                .eq("id", value: friendId.uuidString)
                .execute()

        } catch let error as PostgrestError {
            print("Supabase error while deleting friend: \(error.localizedDescription)")
            throw error
        } catch let error as URLError {
            if error.code == .timedOut {
                print("Network timeout: \(error.localizedDescription)")
            } else {
                print("URLError: \(error.localizedDescription)")
            }
            throw error
        } catch {
            print("Unexpected error while deleting friend: \(error.localizedDescription)")
            throw error
        }
    }
}
