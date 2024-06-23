//
//  DebugMenu.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/23/24.
//

import Foundation
import SwiftUI

struct DebugMenuView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @State private var zoneExits: [ZoneExit] = []
    @State private var isLoading = false
    
    var body: some View {
        List {
            Section(header: Text("Current User")) {
                if let currentUser = friendsDataManager.currentUser {
                    Text("Name: \(currentUser.full_name)")
                    Text("Username: \(currentUser.username)")
                    Text("Latitude: \(currentUser.latitude)")
                    Text("Longitude: \(currentUser.longitude)")
                } else {
                    Text("No current user data")
                }
            }

            Section(header: Text("Friends")) {
                ForEach(friendsDataManager.friends, id: \.id) { friend in
                    VStack(alignment: .leading) {
                        Text("Name: \(friend.full_name)")
                        Text("Username: \(friend.username)")
                        Text("Latitude: \(friend.latitude)")
                        Text("Longitude: \(friend.longitude)")
                        Text("Zones: \(friend.zones.count)")
                    }
                }
            }

            Section(header: Text("User Groups")) {
                ForEach(friendsDataManager.userGroups, id: \.id) { group in
                    VStack(alignment: .leading) {
                        Text("Name: \(group.name)")
                        Text("Description: \(group.description ?? "N/A")")
                    }
                }
            }

            Section(header: Text("Zone Exits")) {
                if isLoading {
                    ProgressView()
                } else {
                    ForEach(zoneExits, id: \.zone_id) { exit in
                        VStack(alignment: .leading) {
                            Text("Profile ID: \(exit.profile_id)")
                            Text("Zone ID: \(exit.zone_id)")
                            Text("Exit Time: \(exit.exit_time)")
                        }
                    }
                }
            }
        }
        .navigationTitle("Debug Menu")
        .onAppear {
            fetchZoneExits()
        }
        .refreshable {
            await friendsDataManager.fetchCurrentUserProfile()
            await friendsDataManager.fetchUserGroups()
            fetchZoneExits()
        }
    }
    
    private func fetchZoneExits() {
        isLoading = true
        Task {
            do {
                let exits: [ZoneExit] = try await supabase
                    .from("zone_exits")
                    .select("*")
                    .order("exit_time", ascending: false)
                    .limit(10)
                    .execute()
                    .value

                DispatchQueue.main.async {
                    self.zoneExits = exits
                    self.isLoading = false
                }
            } catch {
                print("Failed to fetch zone exits: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}
