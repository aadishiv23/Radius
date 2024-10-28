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

    /// Helper function to debug decoding errors
    private func debugPrintDecodingError(_ error: DecodingError) {
        switch error {
        case .typeMismatch(let type, let context):
            print("Type mismatch error: \(type), \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        case .valueNotFound(let type, let context):
            print("Value not found: \(type), \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        case .keyNotFound(let key, let context):
            print("Key not found: \(key), \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
            if let lastPath = context.codingPath.last {
                print("Missing key: \(lastPath.stringValue)")
            }
            // Additional debugging for key not found
            print("Debug context: \(context)")
        case .dataCorrupted(let context):
            print("Data corrupted: \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        @unknown default:
            print("Unknown decoding error: \(error)")
        }
    }
}
