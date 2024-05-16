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
    private let dataController: DataController
    private var supabaseClient: SupabaseClient
    
    @Published var friends: [FriendLocation] = []
    @Published var currentUser: FriendLocation?
    
    private var userId: UUID?


    
    init(dataController: DataController, supabaseClient: SupabaseClient) {
        self.dataController = dataController
        self.supabaseClient = supabaseClient
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
                    .select("*")
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                
                if let profile = profile {
                    await fetchFriends(for: userId)
                }
                print(profile?.fullName)
                print(profile?.username)
                print(profile?.website)
                print(user.email)
                // currentUser = FriendLocation(id: <#T##UUID#>, name: profile?.fullName, color: <#T##String#>, latitude: <#T##Double#>, longitude: <#T##Double#>, zones: <#T##[Zone]#>)
            }
        } catch {
            print("Failed to fetch current user profile: \(error)")
        }
    }
    
//    func checkUserDate(userId: UUID) async -> Bool {
//        do {
//            let result: [FriendLocation] = try await supabaseClient
//                .from("friends")
//                .select("*")
//                .eq("id", value: userId)
//                .single()
//                .execute()
//            
//            
//        } catch {
//            
//        }
//    }
    
    // Fetches all friends from friends table
    func fetchFriends(for userId: UUID) async {
        do {
            let friends: [FriendLocation] = try await supabaseClient
                .from("friends")
                .select("*")
                .eq("id", value: userId)
                .execute()
                .value
            
            var fetchedFriends = friends
            
            for i in 0..<fetchedFriends.count {
               fetchedFriends[i].zones = try await fetchZones(for: fetchedFriends[i].id)
            }
            
            DispatchQueue.main.async {
                self.friends = fetchedFriends // Reference to captured var 'fetchedFriends' in concurrently-executing code; this is an error in Swift 6
                self.currentUser = fetchedFriends.first { $0.id == self.userId }
                // waht
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
    
    
    func joinGroup(groupId: UUID, friendId: UUID, password: String) async throws -> Bool {
        do {
            let group: Group = try await supabaseClient
                .from("groups")
                .select("password")
                .eq("id", value: groupId.uuidString)
                .single()
                .execute()
                .value
            
            
            
            if group.password == hashPassword(password) {
                try await supabaseClient
                    .from("groups")
                    .insert([
                        "group_id": groupId,
                        "friendId": friendId
                    ])
                    .execute()
                return true
                
            } else {
                print("Unable to join desired group")
                return false
            }
            
        } catch {
            print("Failed to access group: \(error)")
            return false
        }
    }
    
    func fetchGroupMembers(groupId: UUID) async throws {
        let result = try await supabaseClient
            .from("group")
            .select("""
            friend_id,
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
    func fetchZones(for friendId: UUID) async throws -> [Zone] {
        let zones: [Zone] = try await supabaseClient
            .from("zones")
            .select("*")
            .eq("friendId", value: friendId.uuidString)
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

}
