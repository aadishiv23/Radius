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
    @State private var fullName = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            TextField("Full Name", text: $fullName)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            
            TextField("Username", text: $username)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            
            Button("Save Profile") {
                saveProfile()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            
            if isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Setup Profile")
    }

    private func saveProfile() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let currentUser = try await supabase.auth.session.user
                try await supabase
                    .from("profiles")
                    .update(
                        UpdateProfileParams(username: username, fullName: fullName)
                    )
                    .eq("id", value: currentUser.id)
                    .execute()
                
                await friendsDataManager.fetchCurrentUserProfile()
                authViewModel.needsProfileSetup = false
            } catch {
                // Handle error
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

// Preview for ProfileSetupViewPreview
struct ProfileSetupViewPreview_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSetupViewPreview()
    }
}
