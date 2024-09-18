//
//  SupabaseProfileView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/8/24.
//

import Foundation
import Supabase
import SwiftUI

struct SupabaseProfileView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager

    @State private var username = ""
    @State private var fullName = ""
    @State private var website = ""
    @State private var isLoading = false
    @State private var currentUserZones: [Zone] = []
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    self.profileForm
                    
                    self.userInfoSection
                        .visionGlass()
                    
                    self.zonesSection // Reuse the zonesSection for the current user's zones
                        .visionGlass()

                    self.updateProfileButton
                    
                    self.myProfileButton
                    
                    Divider()
                    
                    self.signOutButton
                    
                    Divider()
                    
                    Text("v1.0")
                }
                .padding()
            }
            .background(self.backgroundGradient)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: LocationSettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .task {
            await self.getInitialProfile()
            // await friendsDataManager.fetchCurrentUserProfile()
        }
    }
    
    private var profileHStack: some View {
        HStack(alignment: .top, spacing: 20) {
            self.profileHeader // On the left
                .frame(maxWidth: 100) // Constrain the width of profileHeader
            self.profileForm // On the right
                .frame(maxWidth: .infinity)
                .layoutPriority(1) // Give profileForm higher priority to take up space
        }
        .padding()
    }
    
    private var gearButton: some View {
        NavigationLink(destination: LocationSettingsView()) {
            Image(systemName: "gearshape.fill")
                .foregroundColor(.primary)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(gradient: Gradient(colors: [
            Color.blue.opacity(0.2),
            Color.yellow.opacity(0.2)
        ]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
    
    private var profileHeader: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)
                .background(Circle().fill(Color.white).shadow(radius: 5))
          
            Text("@\(self.username)") // Only username is displayed
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: 100) // Constrain the width for profileHeader
    }
  
    private var profileForm: some View {
        VStack(spacing: 15) {
            ProfileTextField(title: "Username", text: self.$username, icon: "person")
            ProfileTextField(title: "Full Name", text: self.$fullName, icon: "person.text.rectangle")
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var userInfoSection: some View {
        VStack(spacing: 10) {
            if let currentUser = friendsDataManager.currentUser {
                Text("Name: \(currentUser.full_name.isEmpty ? "Unknown" : currentUser.full_name)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Username: \(currentUser.username.isEmpty ? "Unavailable" : currentUser.username)")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Coordinates: \(currentUser.latitude != 0 ? "\(currentUser.latitude), \(currentUser.longitude)" : "No coordinates available")")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Number of Zones: \(currentUser.zones.isEmpty ? "No zones available" : "\(currentUser.zones.count)")")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Display a loading message or placeholder content while currentUser is being fetched
                Text("Loading user information...")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }

    private var zonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Zones")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: ZoneGridView()) {
                    Image(systemName: "plus")
                        .foregroundColor(.blue)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    if let currentUser = friendsDataManager.currentUser {
                        ForEach(currentUser.zones) { zone in
                            ZStack(alignment: .topTrailing) {
                                PolaroidCard(zone: zone)
                            }
                        }
                    } else {
                        ProgressView()
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .padding()
    }
    
    private var updateProfileButton: some View {
        Button(action: self.updateProfileButtonTapped) {
            HStack {
                Text("Update Profile")
                    .fontWeight(.semibold)
                if self.isLoading {
                    Spacer()
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(self.isLoading)
    }
    
    private var myProfileButton: some View { // New Button for MyProfileView
        NavigationLink(destination: MyProfileView()) {
            Text("My Profile")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    private var signOutButton: some View {
        Button(action: {
            Task {
                try? await supabase.auth.signOut()
            }
        }) {
            Text("Sign Out")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
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
           
            self.username = profile.username
            self.fullName = profile.full_name

        } catch {
            debugPrint(error)
        }
    }
       
    func updateProfileButtonTapped() {
        Task {
            self.isLoading = true
            defer { isLoading = false }
            do {
                let currentUser = try await supabase.auth.session.user
                
                try await supabase
                    .from("profiles")
                    .update(
                        UpdateProfileParams(username: self.username, fullName: self.fullName)
                    )
                    .eq("id", value: currentUser.id)
                    .execute()
            } catch {
                debugPrint(error)
            }
        }
    }
}

struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: self.icon)
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            TextField(self.title, text: self.$text)
                .textContentType(self.title == "Full Name" ? .name : .username)
                .autocapitalization(self.title == "Full Name" ? .words : .none)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
