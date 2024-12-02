//
//  ProfileSetupView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 8/31/24.
//

import Foundation
import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @State private var username = ""
    @State private var isLoading = false
    @State private var usernameError: String? = nil
    @State private var isCheckingUsername = false
    @Binding var showTutorial: Bool
    
    // Debounce timer for username validation
    @State private var usernameCheckTimer: Timer?
    
    var isFormValid: Bool {
        !username.isEmpty && usernameError == nil && !isCheckingUsername
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Header
            VStack(spacing: 8) {
                Text("Set Up Your Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("Choose a username to complete your profile and get started.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Text fields
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Choose a username", text: $username)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .textInputAutocapitalization(.never) // Remove forced capitalization
                        .onChange(of: username) { newValue in
                            validateUsername()
                        }
                    
                    if isCheckingUsername {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Checking username availability...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else if let error = usernameError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
            }
            
            // Save Button
            Button(action: saveProfile) {
                Text("Save Profile")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .disabled(!isFormValid)
            
            if isLoading {
                ProgressView()
                    .padding(.top, 20)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.15))
        .navigationTitle("Profile Setup")
    }
    
    private func validateUsername() {
        // Cancel any existing timer
        usernameCheckTimer?.invalidate()
        
        // Clear previous error if username is empty
        if username.isEmpty {
            usernameError = nil
            return
        }
        
        // Start checking indicator
        isCheckingUsername = true
        
        // Create new timer with 0.5 second delay
        usernameCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            Task {
                do {
                    let response = try await supabase
                        .from("profiles")
                        .select("username", count: .exact)
                        .eq("username", value: username.lowercased())
                        .execute()
                    
                    await MainActor.run {
                        isCheckingUsername = false
                        if let count = response.count, count > 0 {
                            usernameError = "Username is already taken"
                        } else {
                            usernameError = nil
                        }
                    }
                } catch {
                    await MainActor.run {
                        isCheckingUsername = false
                        usernameError = "Error checking username"
                        debugPrint(error)
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        guard isFormValid else { return }

        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let currentUser = try await supabase.auth.session.user
                try await supabase
                    .from("profiles")
                    .update(UpdateProfileParams(username: username.lowercased()))
                    .eq("id", value: currentUser.id)
                    .execute()

                await friendsDataManager.fetchCurrentUserProfile()
                authViewModel.needsProfileSetup = false
                showTutorial = true
            } catch {
                debugPrint(error)
            }
        }
    }
}


struct ProfileSetupViewPreview: View {
    @State private var username = "SampleUser"
    @State private var fullName = "Sample Name"
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Your Profile Details")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
                .visionGlass()

            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name")
                    .font(.headline)
                    .fontWeight(.bold)

                TextField("Enter your full name", text: $fullName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            // Username Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Username")
                    .font(.headline)
                    .fontWeight(.bold)

                TextField("Choose a username", text: $username)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Spacer() // Push the save button to the bottom

            // Save Profile Button
            Button("Save Profile") {
                saveProfile()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 20) // Add padding at the bottom
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.yellow.opacity(0.5)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
        )
        .cornerRadius(15)
        .padding()
    }

    private func saveProfile() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            print("Profile saved: \(fullName), \(username)")
        }
    }
}

/// Preview for ProfileSetupViewPreview
struct ProfileSetupViewPreview_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSetupViewPreview()
    }
}
