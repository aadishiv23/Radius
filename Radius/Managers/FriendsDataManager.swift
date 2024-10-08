//
//  FriendsDataManager.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/1/24.
//

import CoreData
import CoreLocation
import CryptoKit
import Foundation
import Supabase
import SwiftUI

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
        guard let userId else {
            return
        }

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
        // After converting all bytes to two-character strings, joined() concatenates all these strings into a single
        // string, resulting in the final hashed password in hexadecimal form.
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Method to send a friend request
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

    @MainActor
    func fetchFriendsAndGroups() async {
        guard let userId else {
            return
        }

        await fetchFriends(for: userId)
        await fetchUserGroups()
    }

    func fetchFriends(for userId: UUID) async {
        do {
            // Fetch friend relationships where profile_id1 or profile_id2 equals userId
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

            // Fetch the actual friend profiles
            let friendProfiles: [Profile] = try await supabaseClient
                .from("profiles")
                .select("*")
                .in("id", values: friendIds.map(\.uuidString))
                .execute()
                .value

            // Update the friends list on the main thread
            DispatchQueue.main.async {
                self.friends = friendProfiles
            }

        } catch let error as PostgrestError {
            // Handle Supabase thrown Error
            print("PostgrestError encountered: \(error.localizedDescription)")
        } catch let error as URLError {
            // Handle URL errors, e.g., timeouts
            if error.code == .timedOut {
                print("Request timed out: \(error.localizedDescription)")
            } else {
                print("URLError encountered: \(error.localizedDescription)")
            }
        } catch {
            // Handle any other unexpected error
            print("Unexpected error encountered: \(error.localizedDescription)")
        }
    }

    func fetchPendingFriendRequests() async {
        do {
            guard let userId else {
                return
            }

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

    /// Method to accept a friend request
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
            userId = user.id

            if let userId {
                do {
                    let profile: Profile = try await supabaseClient
                        .from("profiles")
                        .select("*, zones(*)")
                        .eq("id", value: userId)
                        .single()
                        .execute()
                        .value

                    // Successfully fetched profile, update state
                    await MainActor.run {
                        self.currentUser = profile
                    }
                } catch let error as PostgrestError {
                    // Handle specific Supabase error (PostgrestError)
                    print("Supabase error while fetching profile: \(error.localizedDescription)")
                    // You could also log the error or display a user-friendly message here
                } catch let error as URLError {
                    // Handle specific URL error (network error)
                    if error.code == .timedOut {
                        print("Request timed out: \(error.localizedDescription)")
                    } else if error.code == .notConnectedToInternet {
                        print("No internet connection: \(error.localizedDescription)")
                    } else {
                        print("Network error occurred: \(error.localizedDescription)")
                    }
                } catch {
                    // Handle any other unexpected errors
                    print("Unexpected error: \(error.localizedDescription)")
                }
            }
        } catch let error as PostgrestError {
            print("Supabase authentication error: \(error.localizedDescription)")
        } catch {
            print("Failed to get current session: \(error.localizedDescription)")
        }
    }

    func createGroup(name: String, description: String?, password: String) async {
        let hashedPassword = hashPassword(password)
        do {
            let result = try await supabaseClient
                .from("groups")
                .insert([
                    "name": name,
                    "description": description ?? "",
                    "password": hashedPassword,
                    "plain_password": password
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

        } catch let DecodingError.keyNotFound(key, context) {
            print("Could not find key \(key) in JSON: \(context)")
            return false

        } catch let DecodingError.typeMismatch(type, context) {
            print("Type mismatch for type \(type) in JSON: \(context)")
            return false

        } catch let DecodingError.valueNotFound(type, context) {
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

    /// Fetch the given zones for a friend
    func fetchZones(for profile_id: UUID) async throws -> [Zone] {
        let zones: [Zone] = try await supabaseClient
            .from("zones")
            .select("*")
            .eq("profile_id", value: profile_id.uuidString)
            .execute()
            .value

        return zones
    }

    func fdmFetchZoneExits(for profileId: UUID) async throws -> [ZoneExit] {
        do {
            let zoneExits: [ZoneExit] = try await supabaseClient
                .from("zone_exits")
                .select()
                .eq("profile_id", value: profileId.uuidString)
                .order("exit_time", ascending: false) // Adjust sorting based on your needs
                .execute()
                .value

            return zoneExits
        } catch {
            print("Failed to fetch zone exits for profile \(profileId): \(error)")
            throw error
        }
    }

    func fetchZonesDict(for zoneIds: [UUID]) async throws -> [UUID: Zone] {
        do {
            let zones: [Zone] = try await supabaseClient
                .from("zones")
                .select("*")
                .in("id", values: zoneIds.map(\.uuidString)) // Fetch zones by IDs
                .execute()
                .value

            // Create a dictionary with zoneId as the key
            let zoneDictionary = Dictionary(uniqueKeysWithValues: zones.map { ($0.id, $0) })
            return zoneDictionary
        } catch {
            print("Failed to fetch zones: \(error)")
            throw error
        }
    }

    /// insert a zone
    func insertZone(for friendId: UUID, zone: Zone) async throws {
        try await supabaseClient
            .from("zones")
            .insert(zone)
            .execute()
    }

    /// Add zones to a friend
    func addZones(to friendId: UUID, zones: [Zone]) async throws {
        for zone in zones {
            try await insertZone(for: friendId, zone: zone)
        }
    }

    func deleteZone(zoneId: UUID) async throws {
        do {
            // Delete zone from Supabase
            try await supabaseClient
                .from("zones")
                .delete()
                .eq("id", value: zoneId.uuidString)
                .execute()

            // Optionally, remove the corresponding geographic condition
            Task {
                await LocationManager.shared.removeGeographicCondition(for: zoneId)
            }

            // After deleting the zone, fetch the updated user profile
            await fetchCurrentUserProfile()
        } catch {
            print("Failed to delete zone: \(error)")
            throw error
        }
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

    ///    func fetchUserGroups() async {
    ///        guard let userId = userId else {
    ///            print("User ID is not set")
    ///            return
    ///        }
    ///        do {
    ///            let groups: [Group2] = try await supabaseClient
    ///                .from("group_members")
    ///                .select("group_id, groups!inner(name)")  // Using 'inner' to ensure a proper join.
    ///                .eq("profile_id", value: userId.uuidString)
    ///                .execute()
    ///                .value
    ///
    ///            DispatchQueue.main.async {
    ///                self.userGroups = groups
    ///            }
    ///        } catch {
    ///            print("Failed to fetch groups: \(error)")
    ///        }
    ///    }
    func fetchUserGroupMembers() async -> [GroupMember] {
        guard let userId else {
            print("User ID is not set")
            return []
        }
        do {
            let groupMembers: [GroupMember] = try await supabaseClient
                .from("group_members")
                .select("*")
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
            let groupIDStrings = groupIDs.map(\.uuidString)

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
        guard let userId else {
            print("User ID is not set")
            return
        }

        do {
            // Step 1: Fetch Group Members
            let groupMembers = await fetchUserGroupMembers()
            let groupIDs = groupMembers.map(\.group_id)

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

    ///    func fetchUserGroupMembers() async -> [GroupMember] {
    ///        guard let userId = userId else {
    ///            print("User ID is not set")
    ///            return []
    ///        }
    ///        do {
    ///            let groupMembers: [GroupMember] = try await supabaseClient
    ///                .from("group_members")
    ///                .select("group_id, profile_id")
    ///                .eq("profile_id", value: userId.uuidString)
    ///                .execute()
    ///                .value
    ///
    ///            return groupMembers
    ///        } catch {
    ///            print("Failed to fetch group members: \(error)")
    ///            return []
    ///        }
    ///    }
    ///
    ///    func fetchGroupMembers(groupId: UUID) async throws -> [Profile] {
    ///        do {
    ///            let members: [Profile] = try await supabaseClient
    ///                .from("group_members")
    ///                .select("profile_id, profiles(*)")
    ///                .eq("group_id", value: groupId.uuidString)
    ///                .execute()
    ///                .value
    ///            return members
    ///        } catch {
    ///            print("Failed to fetch group members: \(error)")
    ///            return []
    ///        }
    ///    }
    func fetchGroupMembersProfiles(groupId: UUID) async throws -> [Profile] {
        do {
            let groupMembers: [GroupMemberWoBS] = try await supabaseClient
                .from("group_members")
                .select("group_id, profile_id")
                .eq("group_id", value: groupId.uuidString)
                .execute()
                .value

            let profileIDs = groupMembers.map(\.profile_id)

            guard !profileIDs.isEmpty else {
                return []
            }

            let profiles: [Profile] = try await supabaseClient
                .from("profiles")
                .select("*, zones(*)")
                .in("id", values: profileIDs.map(\.uuidString))
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
        guard let userId else {
            throw NSError(
                domain: "FriendsDataManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "User ID is not set"]
            )
        }

        // Step 1: Fetch the user's groups
        let userGroups: [GroupMember] = try await supabaseClient
            .from("group_members")
            .select("group_id, profile_id")
            .eq("profile_id", value: userId.uuidString)
            .execute()
            .value

        let groupIds = userGroups.map(\.group_id.uuidString)

        // Step 2: Fetch competitions linked to these groups
        let groupCompetitionLinks: [GroupCompetitionLink] = try await supabaseClient
            .from("group_competition_links")
            .select("*")
            .in("group_id", values: groupIds)
            .execute()
            .value

        let competitionIds = groupCompetitionLinks.map(\.competition_id.uuidString)
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

    /// Fetch profile by senderId to get the username
    func fetchProfile(for senderId: UUID) async throws -> Profile? {
        let profile: Profile? = try await supabaseClient
            .from("profiles")
            .select("*")
            .eq("id", value: senderId.uuidString)
            .single()
            .execute()
            .value
        return profile
    }

    /// Method to decline a friend request
    func declineFriendRequest(_ request: FriendRequest) async throws {
        try await supabaseClient
            .from("friend_requests")
            .delete()
            .eq("id", value: request.id.uuidString)
            .execute()
    }
}
