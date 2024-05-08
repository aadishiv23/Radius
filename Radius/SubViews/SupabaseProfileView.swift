//
//  SupabaseProfileView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/8/24.
//

import Foundation
import SwiftUI

struct SupabaseProfileView: View {
    @State var username = ""
    @State var fullName = ""
    @State var website = ""
    
    @State var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                    TextField("Website", text: $website)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                }
                
                Section {
                    Button("Update Profile") {
                        updateProfileButtonTapped()
                    }
                    .bold()
                    
                    if isLoading {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sign Out", role: .destructive) {
                        Task {
                            try? await supabase.auth.signOut()
                        }
                    }
                }
            })
        }
        .task {
            await getInitialProfile()
        }
    }
    
    func getInitialProfile() async {
        do {
            let currentUser = try await supabase.auth.session.user
            
            let profile: Profile = try await supabase.database
                .from("profiles")
                .select()
                .eq("id", value: currentUser.id)
                .single()
                .execute()
                .value
            
            self.username = profile.username ?? ""
            self.fullName = profile.fullName ?? ""
            self.website = profile.website ?? ""

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
                
                try await supabase.database
                    .from("profiles")
                    .update(
                        UpdateProfileParams(username: username, fullName: fullName, website: website)
                    )
                    .eq("id", value: currentUser.id)
                    .execute()
            } catch {
                debugPrint(error)
            }
        }
    }
}
