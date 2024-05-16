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
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            if authViewModel.isAuthenticated {
                MainTabView()  // View for authenticated users
            } else {
                AuthView()  // View for authentication
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
