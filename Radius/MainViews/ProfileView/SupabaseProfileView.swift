//
//  SupabaseProfileView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/8/24.
//  Refactored on 1/6/24.
//

import Supabase
import SwiftUI

// MARK: - Main View

/// A view representing the user's profile fetched from Supabase.
struct SupabaseProfileView: View {

    // MARK: - Properties

    @StateObject private var viewModel = SupabaseProfileViewModel()
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var friendsDataManager: FriendsDataManager

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                backgroundGradient

                ScrollView {
                    VStack(spacing: 24) {
                        SupabaseProfileHeaderView(fullName: viewModel.fullName, username: viewModel.username)

                        if viewModel.isEditing {
                            SupabaseProfileEditForm(
                                username: $viewModel.username,
                                fullName: $viewModel.fullName,
                                usernameError: $viewModel.usernameError,
                                isCheckingUsername: $viewModel.isCheckingUsername,
                                isLoading: $viewModel.isLoading,
                                validateUsername: viewModel.validateUsername,
                                updateProfile: { Task { await viewModel.updateProfile() } },
                                cancelEdit: { viewModel.isEditing = false }
                            )
                        } else {
                            editButton
                        }

                        if friendsDataManager.currentUser != nil {
                            SupabaseProfileStatsView(user: friendsDataManager.currentUser)

                            SupabaseProfileZonesSection(currentUser: friendsDataManager.currentUser)
                        }

                        SupabaseProfileActionButtons(
                            isLoading: $viewModel.isLoading,
                            updateProfile: { Task { await viewModel.updateProfile() } },
                            signOut: { Task { try? await supabase.auth.signOut() } },
                            deleteAccount: {}
                        )

                        versionInfo
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .task {
                await viewModel.getInitialProfile()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: LocationSettingsView()) {
                        Image(systemName: "gear.badge")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }

    // MARK: - Private Subviews

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.5),
                Color.white.opacity(0.5),
                Color.yellow.opacity(0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea(.all)
    }

    private var editButton: some View {
        Button(action: { viewModel.isEditing = true }) {
            Text("Edit Profile")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }

    private var versionInfo: some View {
        Text("Version 1.01")
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
    }
}
