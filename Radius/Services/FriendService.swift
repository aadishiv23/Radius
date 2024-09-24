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
    
    // Method to fetch friends from Supabase
    func fetchFriends(for userId: UUID, retryCount: Int = 3) async throws -> [Profile] {
        // Fetch friend relationships where profile_id1 or profile_id2 equals userId
        let friendRelations: [FriendRelation] = try await supabaseClient
            .from("friends")
            .select("friendship_id, profile_id1, profile_id2")
            .or("profile_id1.eq.\(userId.uuidString),profile_id2.eq.\(userId.uuidString)")
            .execute()
            .value
        
        // Extract friend IDs
        let friendIds = Set(friendRelations.compactMap { relation -> UUID? in
            if relation.profile_id1 == userId {
                return relation.profile_id2
            } else if relation.profile_id2 == userId {
                return relation.profile_id1
            }
            return nil
        })
        
        // Fetch the actual friend profiles
        let friendProfiles: [Profile] = try await supabaseClient
            .from("profiles")
            .select("*, zones(*)")
            .in("id", values: friendIds.map { $0.uuidString })
            .execute()
            .value
        
        return friendProfiles
    }
    
    // Send Friend Request
    func sendFriendRequest(to receiverId: UUID, from senderId: UUID) async throws {
        try await supabaseClient
            .from("friend_requests")
            .insert([
                "sender_id": senderId.uuidString,
                "receiver_id": receiverId.uuidString,
                "status": "pending"
            ])
            .execute()
    }
    
    // Accept Friend Request
    func acceptFriendRequest(_ request: FriendRequest) async throws {
        try await supabaseClient
            .from("friend_requests")
            .update(["status": "accepted"])
            .eq("id", value: request.id.uuidString)
            .execute()

        // Insert friendship
        try await supabaseClient
            .from("friends")
            .insert([
                ["profile_id1": request.sender_id.uuidString, "profile_id2": request.receiver_id.uuidString],
                ["profile_id1": request.receiver_id.uuidString, "profile_id2": request.sender_id.uuidString]
            ])
            .execute()
    }
    
    // Fetch Pending Friend Requests
    func fetchPendingRequests(for userId: UUID) async throws -> [FriendRequest] {
        return try await supabaseClient
            .from("friend_requests")
            .select("*")
            .eq("receiver_id", value: userId.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value
    }
    
    // Delete Friend
    func deleteFriend(friendId: UUID) async throws {
        try await supabaseClient
            .from("friends")
            .delete()
            .eq("id", value: friendId.uuidString)
            .execute()
    }
}
