//
//  AppView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/8/24.
//

import Supabase
import SwiftUI

struct AppView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @EnvironmentObject var locationManager: LocationManager

    @StateObject private var friendsRepository =
        FriendsRepository(friendService: FriendService(supabaseClient: supabase))
    @StateObject private var groupsRepository = GroupsRepository.shared
    @StateObject private var zonesRepository = ZonesRepository(zoneService: ZoneService(supabaseClient: supabase))
    @StateObject private var competitionsRepository =
        CompetitionsRepository(supabaseClient: supabase) // Initialize CompetitionsRepository

    @Environment(\.scenePhase) var scenePhase

    @State private var showTutorial = false

    var body: some View {
        NavigationStack {
            if authViewModel.isAuthenticated {
                if authViewModel.needsProfileSetup {
                    ProfileSetupView(showTutorial: $showTutorial)
                } else if showTutorial {
                    TutorialView(showTutorial: $showTutorial)
                } else {
                    MainTabView() // View for authenticated users
                        .onAppear {
                            Task {
                                await friendsDataManager.fetchCurrentUserProfile()
                                if let userId = friendsDataManager.currentUser?.id {
                                    locationManager.plsInitiateLocationUpdates()
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
                        .environmentObject(friendsDataManager)
                        .environmentObject(friendsRepository)
                        .environmentObject(groupsRepository)
                        .environmentObject(zonesRepository)
                        .environmentObject(competitionsRepository) // Provide CompetitionsRepository as
                        // EnvironmentObject
                        .environmentObject(locationManager)
                        .onChange(of: scenePhase) { phase in
                            switch phase {
                            case .active:
                                print("App became active")
                                locationManager.retryFailedZoneExits()
                            case .background:
                                print("App entered background")
                                locationManager.applicationDidEnterBackground()
                            case .inactive:
                                print("App became inactive")
                            @unknown default:
                                print("Unknown scene phase")
                            }
                        }
                }
            } else {
                SignInView(isSignUp: .constant(false))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MainTabView: View {
    @EnvironmentObject var friendsRepository: FriendsRepository
    @EnvironmentObject var groupsRepository: GroupsRepository
    @EnvironmentObject var competitionsRepository: CompetitionsRepository
    @EnvironmentObject var friendsDataManager: FriendsDataManager

    var body: some View {
        TabView {
            if let userId = friendsDataManager.currentUser?.id {
                HomeView(
                    friendsRepository: friendsRepository,
                    groupsRepository: groupsRepository
                )
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            } else {
                Text("Loading...")
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
            }

            // Ensure that currentUser is available
            if let userId = friendsDataManager.currentUser?.id {
                InfoView(
                    friendsRepository: friendsRepository,
                    groupsRepository: groupsRepository,
                    competitionsRepository: competitionsRepository,
                    userId: userId
                )
                .tabItem {
                    Label("Social", systemImage: "figure.socialdance")
                }
            } else {
                // Handle the case where userId is not available
                Text("Loading...")
                    .tabItem {
                        Label("Social", systemImage: "figure.socialdance")
                    }
            }

            LeaderboardView(
                friendsDataManager: friendsDataManager,
                competitionManager: CompetitionManager(supabaseClient: supabase)
            )
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
