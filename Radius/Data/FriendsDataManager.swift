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

/*
 rather than load friends can also call swift fr directly in view
 @FetchRequest(
 entity: FriendLocationEntity.entity(),
 sortDescriptors: [NSSortDescriptor(keyPath: \FriendLocationEntity.name, ascending: true)]
 ) var friends: FetchedResults<FriendLocationEntity>
 */

class FriendsDataManager: ObservableObject {
    private var supabaseClient: SupabaseClient
    private var channel: RealtimeChannelV2?
    
    @Published var friends: [Profile] = []
    @Published var currentUser: Profile!
    @Published var userGroups: [Group] = []
    
    private var userId: UUID?


    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
        setupRealtime()
        Task {
            await fetchCurrentUserProfile()
        }
    }
    
    private func setupRealtime() {
        Task {
            channel = await supabaseClient.realtimeV2.channel("public:profiles")

            let insertions = await channel!.postgresChange(InsertAction.self, schema: "public", table: "profiles")
            let updates = await channel!.postgresChange(UpdateAction.self, table: "profiles")
            let deletions = await channel!.postgresChange(DeleteAction.self, table: "profiles")

            await channel?.subscribe()

            Task {
                for await insertion in insertions {
                    handleInsertedChannel(insertion)
                }
            }
            Task {
                for await update in updates {
                    handleUpdatedChannel(update)
                }
            }
            Task {
                for await deletion in deletions {
                    handleDeletionChannel(deletion)
                }
            }
        }
    }
    
    private func handleInsertedChannel(_ action: InsertAction) {
        do {
            let newProfile = try action.decodeRecord(decoder: decoder) as Profile
            DispatchQueue.main.async {
                self.friends.append(newProfile)
            }
        } catch {
            print("Failed to handle InsertedChannel due to \(error)")
        }
    }
    
    private func handleUpdatedChannel(_ action: UpdateAction) {
        do {
            let updatedProfile = try action.decodeRecord(decoder: decoder) as Profile
            if let index = friends.firstIndex(where: { $0.id == updatedProfile.id }) {
                DispatchQueue.main.async {
                    self.friends[index] = updatedProfile
                }
            }
        } catch {
            print("Failed to handle updated channel due to \(error)")
        }
    }
    
    private func handleDeletionChannel(_ action: DeleteAction) {
        do {
            let profileToDelete = try action.decodeOldRecord(decoder: decoder) as Profile
            if let index = friends.firstIndex(where: { $0.id == profileToDelete.id }) {
                DispatchQueue.main.async {
                    self.friends.remove(at: index)
                }
            }
        } catch {
            print("Failed to handle deleted channel update due to \(error)")
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
                    await fetchFriends(for: userId)
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
        
    func fetchFriends(for userId: UUID) async {
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
            print("Failed to fetch friends: \(error)")
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
