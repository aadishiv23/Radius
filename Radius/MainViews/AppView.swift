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

    @ObservedObject private var friendsRepository = FriendsRepository(friendService: FriendService(supabaseClient: supabase))
    @ObservedObject private var groupsRepository = GroupsRepository(groupService: GroupService(supabaseClient: supabase))
    @ObservedObject private var zonesRepository = ZonesRepository(zoneService: ZoneService(supabaseClient: supabase))

    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        NavigationStack {
            if authViewModel.isAuthenticated {
                if authViewModel.needsProfileSetup {
                    ProfileSetupView()
                } else {
                    MainTabView()  // View for authenticated users
                        .onAppear {
                            Task {
                                await friendsDataManager.fetchCurrentUserProfile()
                                if let userId = friendsDataManager.currentUser?.id {
                                    LocationManager.shared.plsInitiateLocationUpdates()
                                }
                            }
                        }
                        .onChange(of: scenePhase) { newPhase in
                            if newPhase == .active {
                                friendsDataManager.startRealtimeLocationUpdates()
                            } else {
                                Task {
                                    await friendsDataManager.stopRealtimeLocationUpdates()
                                }
                            }
                        }
                        .environmentObject(friendsRepository)
                        .environmentObject(groupsRepository)
                        .environmentObject(zonesRepository)
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
            LeaderboardView()
                .tabItem {
                    Label("Leaderboard", systemImage: "list.number")
                }
            SupabaseProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}
