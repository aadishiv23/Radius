//
//  ProfilesRepository.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/11/24.
//

import Foundation
import Supabase

class ProfilesRepository: Observable {
    private var cache: [UUID: Profile] = [:]
    private var supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    /// Fetch profile for given userId from cache or supabase
    func fetchProfile(for userId: UUID) async throws -> Profile {
        if let cachedProfile = cache[userId] {
            return cachedProfile
        }
        
        let profile: Profile = try await supabaseClient
            .from("profile")
            .select("*")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        cache[userId] = profile
        
        return profile
    }
    
    /// Invalidate cache for a specific user
    func invalidateProfileCache(for userId: UUID) {
        cache.removeValue(forKey: userId)
    }
    
}
