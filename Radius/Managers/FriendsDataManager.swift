//
//  FriendsDataManager.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/1/24.
//

import Foundation
import CoreData
import CoreLocation
import SwiftUI
import CryptoKit
import Supabase

class FriendsDataManager: ObservableObject {
    private var supabaseClient: SupabaseClient
    private var locationSubscription: RealtimeChannelV2?
    
    @Published var friends: [Profile] = []
    @Published var currentUser: Profile!
    @Published var userGroups: [Group] = []
    @Published var pendingRequests: [FriendRequest] = []
    
    private var userId: UUID?

    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
        Task {
            await fetchCurrentUserProfile()
        }
    }

    /// Start listening for real-time location updates
    func startRealtimeLocationUpdates() {
        Task {
           await subscribeToRealtimeLocationUpdates()
       }
    }
    
    func stopRealtimeLocationUpdates() async {
        Task {
            await locationSubscription?.unsubscribe()
            locationSubscription = nil
        }
    }
    
    func subscribeToRealtimeLocationUpdates() async {
        guard let userId = userId else { return }
        
        locationSubscription = await supabaseClient.realtimeV2.channel("public:profiles")
        
        // Listen explicitly for only updates to latitude and longitude
        let updates = await locationSubscription!.postgresChange(UpdateAction.self, table: "profiles")
     
        await locationSubscription?.subscribe()
        
        for await update in await updates {
            await handleRealtimeLocationUpdate(update)
        }
    }
    
    private func handleRealtimeLocationUpdate(_ update: UpdateAction) async {
        do {
            let updatedProfile = try update.decodeRecord(decoder: decoder) as Profile
            DispatchQueue.main.async {
                if let index = self.friends.firstIndex(where: { $0.id == updatedProfile.id }) {
                    self.friends[index].latitude = updatedProfile.latitude
                    self.friends[index].longitude = updatedProfile.longitude
                }
            }
        } catch {
            print("[Real-time Location] - Failed to handle real-time location update: \(error)")
        }
    }
    
    private func hashPassword(_ password: String) -> String {
        let hashed = SHA256.hash(data: Data(password.utf8))
        
        // The hash result is a series of bytes. Each byte is an integer between 0 and 255.
        // This line converts each byte into a two-character hexadecimal string.
        // %x indicates hexadecimal formatting.
        // 02 ensures that the hexadecimal number is padded with zeros to always have two digits.
        // This is important because a byte represented in hexadecimal can have one or two digits (e.g., 0x3 or 0x03),
        // and consistent formatting requires two digits.
        // After converting all bytes to two-character strings, joined() concatenates all these strings into a single string, resulting in the final hashed password in hexadecimal form.
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // Method to send a friend request
    func sendFriendRequest(to username: String) async throws {
        do {
            let receiverProfile: Profile? = try await supabaseClient
                .from("profiles")
                .select("id")
                .eq("username", value: username)
                .single()
                .execute()
                .value
            
            guard let receiverId = receiverProfile?.id, let senderId = userId else {
                print("Receiver not found or sender ID is nil")
                return
            }
            
            try await supabaseClient
                .from("friend_requests")
                .insert([
                    "sender_id": senderId.uuidString,
                    "receiver_id": receiverId.uuidString,
                    "status": "pending"
                ])
                .execute()
            
            print("Friend request sent to \(username)")
        } catch {
            print("Failed to send friend request: \(error)")
        }
    }
    
    func fetchFriendsAndGroups() async {
        guard let userId = self.userId else { return }
        
        await fetchFriends(for: userId)
        await fetchUserGroups()
    }
    
    func fetchFriends(for userId: UUID) async {
            do {
                // First, fetch friend relationships
                let friendRelations: [FriendRelation] = try await supabaseClient
                    .from("friends")
                    .select("*")
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

                // Now fetch the actual friend profiles
                let friendProfiles: [Profile] = try await supabaseClient
                    .from("profiles")
                    .select("*")
                    .in("id", values: friendIds.map { $0.uuidString })
                    .execute()
                    .value

                DispatchQueue.main.async {
                    self.friends = friendProfiles
                }
            } catch {
                print("Failed to fetch friends: \(error)")
            }
        }

    func fetchPendingFriendRequests() async {
        do {
            guard let userId = userId else { return }
            
            let requests: [FriendRequest] = try await supabaseClient
                .from("friend_requests")
                .select("*")
                .eq("receiver_id", value: userId.uuidString)
                .eq("status", value: "pending")
                .execute()
                .value
            
            DispatchQueue.main.async {
                self.pendingRequests = requests
            }
        } catch {
            print("Failed to fetch pending friend requests: \(error)")
        }
    }


    // Method to accept a friend request
    func acceptFriendRequest(_ request: FriendRequest) async {
        do {
            try await supabaseClient
                .from("friend_requests")
                .update(["status": "accepted"])
                .eq("id", value: request.id.uuidString)
                .execute()
            
            // Assuming you want to add both profiles as friends
            try await supabaseClient
                .from("friends")
                .insert([
                    ["profile_id1": request.sender_id.uuidString, "profile_id2": request.receiver_id.uuidString],
                    ["profile_id1": request.receiver_id.uuidString, "profile_id2": request.sender_id.uuidString]
                ])
                .execute()
            
            print("Friend request accepted")
            // Refresh friends list
            await fetchFriends(for: userId!)
        } catch {
            print("Failed to accept friend request: \(error)")
        }
    }

    
    func fetchCurrentUserProfile() async {
        do {
            let user = try await supabaseClient.auth.session.user
            self.userId = user.id
            
            if let userId = self.userId {
                let profile: Profile? = try await supabaseClient
                    .from("profiles")
                    .select("*, zones(*)") // Ensure zones are included in the query
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                
                if let profile = profile {
                    await OldfetchFriends(for: userId)
                    print(profile.full_name)
                    print(profile.username)
                    print(user.email ?? "N/A")
                    
                    DispatchQueue.main.async {
                       self.currentUser = profile
                   }
                }
            }
        } catch {
            print("Failed to fetch current user profile: \(error)")
        }
    }
        
    func OldfetchFriends(for userId: UUID) async {
        do {
            let friends: [Profile] = try await supabaseClient
                .from("profiles")
                .select("*, zones(*)")
                .eq("id", value: userId)
                .execute()
                .value
            
            var fetchedFriends = friends
            
            for i in 0..<fetchedFriends.count {
                fetchedFriends[i].zones = try await fetchZones(for: fetchedFriends[i].id)
            }
            
            DispatchQueue.main.async {
                self.friends = fetchedFriends
                self.currentUser = fetchedFriends.first { $0.id == self.userId }
            }
            
        } catch {
            print("Failed to fetch friends old: \(error)")
        }
    }

    
    func createGroup(name: String, description: String?, password: String) async {
        let hashedPassword = hashPassword(password)
        do {
            let result = try await supabaseClient
                .from("groups")
                .insert([
                    "name" : name,
                    "description" : description ?? "",
                    "password" : hashedPassword
                ])
                .execute()
            
            print("Group created: \(result)")
        } catch {
            print("Failed to create group: \(error)")
        }
    }
    
    
    func joinGroup(groupName: String, password: String) async throws -> Bool {
        do {
            let result = try await supabaseClient
                    .from("groups")
                    .select("id, password")
                    .eq("name", value: groupName)
                    .execute()
                    .response

            print("Response: \(result)")

            let groups: [Group] = try await supabaseClient
                .from("groups")
                .select("id, name, password")
                .eq("name", value: groupName)
                .execute()
                .value
            
            guard let group = groups.first else {
                print("No group found with the name: \(groupName)")
                return false
            }
            
            if group.password == hashPassword(password) {
                // If password matches, add current user to the group
                guard let currentUserID = userId else {
                    print("Current user ID is not set")
                    return false
                }
                
                // Insert the current user into the group
                let insertResult = try await supabaseClient
                    .from("group_members") // Assuming 'group_members' is the table where group memberships are stored
                    .insert([
                        "group_id": group.id.uuidString,
                        "profile_id": currentUserID.uuidString
                    ])
                    .execute()

                print("User successfully added to group: \(insertResult)")
                return true
                
            } else {
                print("Unable to join desired group")
                return false
            }
            
        }  catch DecodingError.keyNotFound(let key, let context) {
            print("Could not find key \(key) in JSON: \(context)")
            return false

        } catch DecodingError.typeMismatch(let type, let context) {
            print("Type mismatch for type \(type) in JSON: \(context)")
            return false

        } catch DecodingError.valueNotFound(let type, let context) {
            print("Value not found for type \(type) in JSON: \(context)")
            return false

        } catch {
            print("General error: \(error)")
            return false
        }
    }
    
    func fetchGroupMembers(groupId: UUID) async throws {
        let result = try await supabaseClient
            .from("group")
            .select("""
            profile_id,
            friends!inner(*)
            """)
            .eq("groupId", value: groupId)
            .execute()
        
        print("Group members \(result)")
    }
    
    
    func addFriend(name: String, color: String, profileId: UUID) async throws {
        try await supabaseClient
            .from("friends")
            .insert([
                "name": name,
                "color": color,
                "profile_id": profileId.uuidString
            ])
            .execute()
    }
    
    func deleteFriend(friendId: UUID) async throws {
        try await supabaseClient
            .from("friends")
            .delete()
            .eq("id", value: friendId.uuidString)
            .execute()
    }
    
    
    // Fetch the given zones for a friend
    func fetchZones(for profile_id: UUID) async throws -> [Zone] {
        let zones: [Zone] = try await supabaseClient
            .from("zones")
            .select("*")
            .eq("profile_id", value: profile_id.uuidString)
            .execute()
            .value
        
        return zones
    }
    
    // insert a zone
    func insertZone(for friendId: UUID, zone: Zone) async throws {
        try await supabaseClient
            .from("zones")
            .insert(zone)
            .execute()
    }
    
// Add zones to a friend
    func addZones(to friendId: UUID, zones: [Zone]) async throws {
        for zone in zones {
            try await insertZone(for: friendId, zone: zone)
        }
    }
    
    func deleteZone(zoneId: UUID) async throws {
        try await supabaseClient
            .from("zones")
            .delete()
            .eq("id", value: zoneId.uuidString)
            .execute()
    }

    func renameZone(zoneId: UUID, newName: String) async throws {
        do {
            try await supabaseClient
                .from("zones")
                .update(["name": newName])
                .eq("id", value: zoneId.uuidString)
                .execute()
        } catch {
            print("Failed to rename zone: \(error)")
        }
    }

//    func fetchUserGroups() async {
//        guard let userId = userId else {
//            print("User ID is not set")
//            return
//        }
//        do {
//            let groups: [Group2] = try await supabaseClient
//                .from("group_members")
//                .select("group_id, groups!inner(name)")  // Using 'inner' to ensure a proper join.
//                .eq("profile_id", value: userId.uuidString)
//                .execute()
//                .value
//
//            DispatchQueue.main.async {
//                self.userGroups = groups
//            }
//        } catch {
//            print("Failed to fetch groups: \(error)")
//        }
//    }
    func fetchUserGroupMembers() async -> [GroupMember] {
        guard let userId = userId else {
            print("User ID is not set")
            return []
        }
        do {
            let groupMembers: [GroupMember] = try await supabaseClient
                .from("group_members")
                .select("group_id, profile_id")
                .eq("profile_id", value: userId.uuidString)
                .execute()
                .value
            
            return groupMembers
        } catch {
            print("Failed to fetch group members: \(error)")
            return []
        }
    }
   
    func fetchGroupsByIDs(_ groupIDs: [UUID]) async -> [Group] {
        do {
            // Convert UUIDs to Strings
            let groupIDStrings = groupIDs.map { $0.uuidString }

            let groups: [Group] = try await supabaseClient
                .from("groups")
                .select("id, name, description, password")
                .in("id", values: groupIDStrings)
                .execute()
                .value
            return groups
        } catch {
            print("Failed to fetch groups: \(error)")
            return []
        }
    }


    
    func fetchUserGroups() async {
        guard let userId = userId else {
            print("User ID is not set")
            return
        }
        
        do {
            // Step 1: Fetch Group Members
            let groupMembers = await fetchUserGroupMembers()
            let groupIDs = groupMembers.map { $0.group_id }
            
            guard !groupIDs.isEmpty else {
                print("No groups found for user")
                return
            }
            
            // Step 2: Fetch Groups by IDs
            let groups = await fetchGroupsByIDs(groupIDs)
            
            // Update the userGroups property on the main thread
            DispatchQueue.main.async {
                self.userGroups = groups
            }
        } catch {
            print("Failed to fetch user groups: \(error)")
        }
    }


//    func fetchUserGroupMembers() async -> [GroupMember] {
//        guard let userId = userId else {
//            print("User ID is not set")
//            return []
//        }
//        do {
//            let groupMembers: [GroupMember] = try await supabaseClient
//                .from("group_members")
//                .select("group_id, profile_id")
//                .eq("profile_id", value: userId.uuidString)
//                .execute()
//                .value
//            
//            return groupMembers
//        } catch {
//            print("Failed to fetch group members: \(error)")
//            return []
//        }
//    }
//
//    func fetchGroupMembers(groupId: UUID) async throws -> [Profile] {
//        do {
//            let members: [Profile] = try await supabaseClient
//                .from("group_members")
//                .select("profile_id, profiles(*)")
//                .eq("group_id", value: groupId.uuidString)
//                .execute()
//                .value
//            return members
//        } catch {
//            print("Failed to fetch group members: \(error)")
//            return []
//        }
//    }
    func fetchGroupMembersProfiles(groupId: UUID) async throws -> [Profile] {
            do {
                let groupMembers: [GroupMember] = try await supabaseClient
                    .from("group_members")
                    .select("group_id, profile_id")
                    .eq("group_id", value: groupId.uuidString)
                    .execute()
                    .value

                let profileIDs = groupMembers.map { $0.profile_id }
                
                guard !profileIDs.isEmpty else {
                    return []
                }

                let profiles: [Profile] = try await supabaseClient
                    .from("profiles")
                    .select("*")
                    .in("id", values: profileIDs.map { $0.uuidString })
                    .execute()
                    .value
                
                return profiles
            } catch {
                print("Failed to fetch group members' profiles: \(error)")
                throw error
            }
        }
}


extension FriendsDataManager {
    func fetchUserCompetitions() async throws -> [GroupCompetition] {
        guard let userId = userId else {
            throw NSError(domain: "FriendsDataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User ID is not set"])
        }
        
        // Step 1: Fetch the user's groups
        let userGroups: [GroupMember] = try await supabaseClient
            .from("group_members")
            .select("group_id, profile_id")
            .eq("profile_id", value: userId.uuidString)
            .execute()
            .value
        
        let groupIds = userGroups.map { $0.group_id.uuidString }
        
        // Step 2: Fetch competitions linked to these groups
        let groupCompetitionLinks: [GroupCompetitionLink] = try await supabaseClient
            .from("group_competition_links")
            .select("*")
            .in("group_id", values: groupIds)
            .execute()
            .value
        
        let competitionIds = groupCompetitionLinks.map { $0.competition_id.uuidString }
       // Array(Set(groupCompetitionLinks.map { $0.competition_id.uuidString }))
        
        // Step 3: Fetch the actual competition details
        let competitions: [GroupCompetition] = try await supabaseClient
            .from("group_competitions")
            .select("*")
            .in("id", values: competitionIds)
            .execute()
            .value
        
        return competitions
    }
    
    func removePendingRequest(_ request: FriendRequest) {
        if let index = pendingRequests.firstIndex(where: { $0.id == request.id }) {
            pendingRequests.remove(at: index)
        }
    }

//    func getProfile(for profileId: UUID) -> Profile? {
//        return profiles.first(where: { $0.id == profileId })
//    }
}
