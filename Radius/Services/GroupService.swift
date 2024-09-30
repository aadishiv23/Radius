//
//  GroupService.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/12/24.
//

import Foundation
import Supabase
import CryptoKit

class GroupService {
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    // Create Group
    func createGroup(name: String, description: String?, password: String) async throws {
        let hashedPassword = SHA256.hash(data: Data(password.utf8)).compactMap { String(format: "%02x", $0) }.joined()
        try await supabaseClient
            .from("groups")
            .insert([
                "name": name,
                "description": description ?? "",
                "password": hashedPassword,
                "plain_password": password 
            ])
            .execute()
    }
    
    // Fetch User Groups
   func fetchUserGroups(for userId: UUID) async throws -> [Group] {
       let groupMembers: [GroupMemberWoBS] = try await supabaseClient
           .from("group_members")
           .select("*")
           .eq("profile_id", value: userId.uuidString)
           .execute()
           .value

       let groupIDs = groupMembers.map { $0.group_id.uuidString }
       return try await supabaseClient
           .from("groups")
           .select("*")
           .in("id", values: groupIDs)
           .execute()
           .value
   }
}
