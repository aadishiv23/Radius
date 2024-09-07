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
    @State private var username = ""
    @State private var fullName = ""
    @State private var website = ""
    @State private var isLoading = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 20) {
                        profileHeader
                        
                        profileForm
                        
                        updateProfileButton
                        
                        Divider()
                        
                        signOutButton
                        
                        Divider()
                        
                        Text("v1.0")
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: LocationSettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)

        }
        .task {
            await getInitialProfile()
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(gradient: Gradient(colors: [
            Color.blue.opacity(0.1),
            Color.purple.opacity(0.1)
        ]), startPoint: .topLeading, endPoint: .bottomTrailing)
        .ignoresSafeArea()
    }
    
    private var profileHeader: some View {
        VStack {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .background(Circle().fill(Color.white).shadow(radius: 5))
                .padding(.bottom)
            
            Text(fullName)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("@\(username)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
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
