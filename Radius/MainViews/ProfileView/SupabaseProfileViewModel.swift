//
//  SupabaseProfileViewModel.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on [Current Date]
//

import Supabase
import SwiftUI

// MARK: - ViewModel

/// Handles logic for fetching, updating, and validating profile data.
class SupabaseProfileViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var username: String = ""
    @Published var fullName: String = ""
    @Published var isEditing: Bool = false
    @Published var usernameError: String? = nil
    @Published var isCheckingUsername: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentUserZones: [Zone] = []

    // MARK: - Private Properties

    private var usernameCheckTimer: Timer?

    // MARK: - Methods

    /// Fetches the initial profile from Supabase.
    func getInitialProfile() async {
        do {
            let currentUser = try await supabase.auth.session.user
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: currentUser.id)
                .single()
                .execute()
                .value

            await MainActor.run {
                self.username = profile.username
                self.fullName = profile.full_name
            }
        } catch {
            print("Error fetching profile: \(error.localizedDescription)")
        }
    }

    /// Validates username availability.
    func validateUsername() {
        usernameCheckTimer?.invalidate()
        guard !username.isEmpty else {
            usernameError = nil
            return
        }

        isCheckingUsername = true
        usernameCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            Task {
                do {
                    let response = try await supabase
                        .from("profiles")
                        .select("username", count: .exact)
                        .eq("username", value: self.username.lowercased())
                        .execute()

                    await MainActor.run {
                        self.isCheckingUsername = false
                        self.usernameError = response.count ?? 0 > 0 ? "Username is already taken" : nil
                    }
                } catch {
                    await MainActor.run {
                        self.isCheckingUsername = false
                        self.usernameError = "Error checking username"
                    }
                }
            }
        }
    }

    /// Updates the user's profile in Supabase.
    func updateProfile() async {
        guard !username.isEmpty, !fullName.isEmpty, usernameError == nil else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let currentUser = try await supabase.auth.session.user
            try await supabase
                .from("profiles")
                .update(UpdateProfileParamsWithFullName(username: username.lowercased(), fullName: fullName))
                .eq("id", value: currentUser.id)
                .execute()

            isEditing = false
        } catch {
            print("Error updating profile: \(error.localizedDescription)")
        }
    }
}
