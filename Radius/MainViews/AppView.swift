//
//  AppView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/8/24.
//

import Foundation
import SwiftUI


import SwiftUI
import Supabase

struct AppView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var friendsDataManager: FriendsDataManager

    var body: some View {
        NavigationStack {
            if authViewModel.isAuthenticated {
                MainTabView()  // View for authenticated users
                    .onAppear {
                        Task {
                            await friendsDataManager.fetchCurrentUserProfile()
                            if let userId = friendsDataManager.currentUser?.id {
                                LocationManager.shared.startUpdatingLocation()
                            }
                        }
                    }
                    .onDisappear {
                        LocationManager.shared.stopUpdatingLocation()
                    }
            } else {
                AuthView()
            }
        }
    }
}


struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            InfoView()
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
            SupabaseProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}
