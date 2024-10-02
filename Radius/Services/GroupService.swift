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
                .select("*")
                .eq("profile_id", value: userId.uuidString)
                .execute()
                .value

            let groupIDs = groupMembers.map(\.group_id.uuidString)

            return try await supabaseClient
                .from("groups")
                .select("*")
                .in("id", values: groupIDs)
                .execute()
                .value

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
        } catch {
            print("Unexpected error while fetching user groups: \(error.localizedDescription)")
            throw error
        }
    }
}
