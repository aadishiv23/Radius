//
//  DebugMenu.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/23/24.
//

import Foundation
import SwiftUI
import Combine

struct DebugMenuView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @StateObject private var zoneExitObserver = ZoneExitObserver()
    @State private var zoneExits: [ZoneExit] = []
    @State private var localZoneExits: [LocalZoneExit] = []
    @State private var isLoading = false
    @State private var zones: [Zone] = []
    
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

            Section(header: Text("Local Zone Exits")) {
                if localZoneExits.isEmpty {
                    Text("No local zone exits recorded")
                } else {
                    ForEach(localZoneExits.reversed(), id: \.id) { exit in
                        VStack(alignment: .leading) {
                            Text("Zone: \(exit.zoneName)")
                            Text("Exit Time: \(formatDate(exit.exitTime))")
                            Text("Latitude: \(exit.latitude)")
                            Text("Longitude: \(exit.longitude)")
                        }
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
            ///  let id: UUID
//            let name: String
//            let latitude: Double
//            let longitude: Double
//            let radius: Double
//            let profile_id: UUID
//
            Section(header: Text("User zones")) {
                if isLoading {
                    ProgressView()
                }
                else {
                    ForEach(zones, id: \.id) { zone in
                        VStack(alignment: .leading) {
                            Text("Zone ID: \(zone.id)")
                            Text("Zone Name: \(zone.name)")
                            Text("Zone latitude: \(zone.latitude)")
                            Text("Zone longitude: \(zone.longitude)")
                            Text("Zone Radius: \(zone.radius)")
                            Text("Assoc Profile ID: \(zone.profile_id)")
                        }
                        
                    }
                }
            }
        }
        .navigationTitle("Debug Menu")
        .onAppear {
            fetchZoneExits()
            zoneExitObserver.startObserving()
        }
        .onDisappear {
           zoneExitObserver.stopObserving()
        }
        .onReceive(zoneExitObserver.$localZoneExits) { newExits in
           self.localZoneExits = newExits
        }
        .refreshable {
            await friendsDataManager.fetchCurrentUserProfile()
            await friendsDataManager.fetchUserGroups()
            do {
                try await zones = friendsDataManager.fetchZones(for: friendsDataManager.currentUser.id)
            } catch {
                print("couldnt fetch zones: \(error)")
            }
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

class ZoneExitObserver: ObservableObject {
    @Published var localZoneExits: [LocalZoneExit] = []
    private var cancellables = Set<AnyCancellable>()
    
    func startObserving() {
        NotificationCenter.default.publisher(for: .zoneExited)
            .sink { [weak self] notification in
                if let zoneExit = notification.object as? LocalZoneExit {
                    DispatchQueue.main.async {
                        self?.localZoneExits.append(zoneExit)
                        // Keep only the last 10 exits
                        self?.localZoneExits = Array(self?.localZoneExits.suffix(10) ?? [])
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func stopObserving() {
        cancellables.removeAll()
    }
}
