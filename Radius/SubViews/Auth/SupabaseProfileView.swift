//
//  SupabaseProfileView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/8/24.
//

import Foundation
import SwiftUI
import Supabase

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
                    profileForm
                    
                    userInfoSection
                        .visionGlass()
                    
                    zonesSection // Reuse the zonesSection for the current user's zones
                        .visionGlass()


                    updateProfileButton
                    
                    myProfileButton
                    
                    Divider()
                    
                    signOutButton
                    
                    Divider()
                    
                    Text("v1.0")
                }
                .padding()
            }
            .background(backgroundGradient)
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
            await getInitialProfile()
            // await friendsDataManager.fetchCurrentUserProfile()

        }
    }
    
    private var profileHStack: some View {
        HStack(alignment: .top, spacing: 20) {
            profileHeader // On the left
                .frame(maxWidth: 100) // Constrain the width of profileHeader
            profileForm // On the right
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
          
          Text("@\(username)") // Only username is displayed
              .font(.headline)
              .foregroundColor(.secondary)
      }
      .frame(maxWidth: 100) // Constrain the width for profileHeader
  }
  
  private var profileForm: some View {
       VStack(spacing: 15) {
          ProfileTextField(title: "Username", text: $username, icon: "person")
          ProfileTextField(title: "Full Name", text: $fullName, icon: "person.text.rectangle")
       }
       .padding()
       .background(Color(UIColor.secondarySystemBackground))
       .cornerRadius(15)
       .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
   }
    
    private var userInfoSection: some View {
        VStack(spacing: 10) {
            Text("Name: \(friendsDataManager.currentUser.full_name)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Username: \(friendsDataManager.currentUser.username)")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Coordinates: \(friendsDataManager.currentUser.latitude), \(friendsDataManager.currentUser.longitude)")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Number of Zones: \(friendsDataManager.currentUser.zones.count)")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
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
                    ForEach(friendsDataManager.currentUser.zones) { zone in
                        ZStack(alignment: .topTrailing) {
                            PolaroidCard(zone: zone)
                        }
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .padding()
    }
    
    private var updateProfileButton: some View {
        Button(action: updateProfileButtonTapped) {
            HStack {
                Text("Update Profile")
                    .fontWeight(.semibold)
                if isLoading {
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
        .disabled(isLoading)
    }
    
    private var myProfileButton: some View {  // New Button for MyProfileView
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
            isLoading = true
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
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            TextField(title, text: $text)
                .textContentType(title == "Full Name" ? .name : .username)
                .autocapitalization(title == "Full Name" ? .words : .none)
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
