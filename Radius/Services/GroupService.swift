//
//  GroupService.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/12/24.
//

import CryptoKit
import Foundation
import Supabase

class GroupService {
    private let supabaseClient: SupabaseClient

    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }

    /// Create Group with error handling
    func createGroup(name: String, description: String?, password: String) async throws {
        let hashedPassword = SHA256.hash(data: Data(password.utf8)).compactMap { String(format: "%02x", $0) }.joined()

        do {
            try await supabaseClient
                .from("groups")
                .insert([
                    "name": name,
                    "description": description ?? "",
                    "password": hashedPassword,
                    "plain_password": password
                ])
                .execute()

        } catch let error as PostgrestError {
            print("Supabase error while creating group: \(error.localizedDescription)")
            throw error
        } catch let error as URLError {
            if error.code == .timedOut {
                print("Network timeout: \(error.localizedDescription)")
            } else {
                print("URLError: \(error.localizedDescription)")
            }
            throw error
        } catch let error as DecodingError {
            debugPrintDecodingError(error)
            throw error
        } catch {
            print("Unexpected error while creating group: \(error.localizedDescription)")
            throw error
        }
    }

    /// Fetch User Groups with error handling
    func fetchUserGroups(for userId: UUID) async throws -> [Group] {
        do {
            let groupMembers: [GroupMemberWoBS] = try await supabaseClient
                .from("group_members")
                .select("group_id, profile_id") // Explicitly specify fields needed
                .eq("profile_id", value: userId.uuidString)
                .execute()
                .value

            // Debugging: Print the fetched group members to see if it contains the expected data
            print("Fetched group members: \(groupMembers)")

            // Check if groupMembers is empty
            guard !groupMembers.isEmpty else {
                print("No group memberships found for user ID: \(userId)")
                return []
            }

            let groupIDs = groupMembers.compactMap { groupMember in
                groupMember.group_id.uuidString
            }

            // Debugging: Print group IDs to ensure they are valid
            print("Group IDs to fetch: \(groupIDs)")

            // Fetch the groups based on fetched group IDs
            let fetchedGroups: [Group] = try await supabaseClient
                .from("groups")
                .select("*")
                .in("id", values: groupIDs)
                .execute()
                .value

            // Debugging: Print the fetched groups
            print("Fetched groups: \(fetchedGroups)")

            return fetchedGroups

        } catch let error as PostgrestError {
            print("Supabase error while fetching user groups: \(error.localizedDescription)")
            throw error
        } catch let error as URLError {
            if error.code == .timedOut {
                print("Network timeout: \(error.localizedDescription)")
            } else {
                print("URLError: \(error.localizedDescription)")
            }
            throw error
        } catch let error as DecodingError {
            debugPrintDecodingError(error)
            throw error
        } catch {
            print("Unexpected error while fetching user groups: \(error.localizedDescription)")
            throw error
        }
    }

    func createGroupRules(groupId: String, groupRule: GroupRule) async throws {
        do {
            // Check if the group exists first
            let groupExists: Group? = try await supabaseClient
                .from("groups")
                .select("*")
                .eq("id", value: groupId)
                .single()
                .execute()
                .value
            if let groupExists {
                // Convert allowed zone categories to an array of raw values
                let categoriesArray = "{" + groupRule.allowed_zone_categories
                    .map(\.rawValue)
                    .joined(separator: ",") + "}"
                // let allowedZoneCategoriesString = String(data: categoriesArray, encoding: .utf8)
                // Insert the group rules with values converted to strings where necessary
                try await supabaseClient
                    .from("group_rule")
                    .insert([
                        "id": groupRule.id.uuidString,
                        "group_id": groupId,
                        "count_zone_exits": String(groupRule.count_zone_exits), // Convert Bool to String
                        "max_exits_allowed": String(groupRule.max_exits_allowed), // Convert Int to String
                        "allowed_zone_categories": categoriesArray
                    ])
                    .execute()

                print("[Group Service] - Group rules created successfully for group: \(groupId)")
            } else {
                print("[Group Service] - Group \(groupId) not found")
            }
        } catch let error as PostgrestError {
            print("Supabase error while creating group rules: \(error.localizedDescription)")
            throw error
        } catch {
            print("Unexpected error while creating group rules: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchGroupRules(for groupId: String) async throws -> GroupRule {
        do {
            let rules: GroupRule = try await supabaseClient
                .from("group_rule")
                .select("*")
                .eq("group_id", value: groupId)
                .single()
                .execute()
                .value

            print("[GroupService] - Successfully fetched rules for group: \(groupId)")
            return rules
        } catch let error as PostgrestError {
            print("[GroupService] - Supabase error while fetching group rules: \(error.localizedDescription)")
            throw error
        } catch {
            print("[GroupService] - Unexpected error while fetching group rules: \(error.localizedDescription)")
            throw error
        }
    }

    func updateGroupRules(groupId: String, groupRule: GroupRule) async throws {
        do {
            // Convert allowed zone categories to array string
            let categoriesArray = "{" + groupRule.allowed_zone_categories
                .map(\.rawValue)
                .joined(separator: ",") + "}"

            // Update the existing group rules
            try await supabaseClient
                .from("group_rule")
                .update([
                    "count_zone_exits": String(groupRule.count_zone_exits),
                    "max_exits_allowed": String(groupRule.max_exits_allowed),
                    "allowed_zone_categories": categoriesArray
                ])
                .eq("group_id", value: groupId)
                .execute()

            print("[Group Service] - Group rules updated successfully for group: \(groupId)")
        } catch let error as PostgrestError {
            print("Supabase error while updating group rules: \(error.localizedDescription)")
            throw error
        } catch {
            print("Unexpected error while updating group rules: \(error.localizedDescription)")
            throw error
        }
    }

    /// Helper function to debug decoding errors
    private func debugPrintDecodingError(_ error: DecodingError) {
        switch error {
        case let .typeMismatch(type, context):
            print("Type mismatch error: \(type), \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        case let .valueNotFound(type, context):
            print("Value not found: \(type), \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        case let .keyNotFound(key, context):
            print("Key not found: \(key), \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
            if let lastPath = context.codingPath.last {
                print("Missing key: \(lastPath.stringValue)")
            }
            // Additional debugging for key not found
            print("Debug context: \(context)")
        case let .dataCorrupted(context):
            print("Data corrupted: \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        @unknown default:
            print("Unknown decoding error: \(error)")
        }
    }
}
