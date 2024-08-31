//
//  DebugMenu.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/23/24.
//

import Foundation
import SwiftUI
import Combine

// MARK: - DebugMenuView
struct DebugMenuView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @StateObject private var zoneExitObserver = ZoneExitObserver()
    @State private var zoneExits: [ZoneExit] = []
    @State private var localZoneExits: [LocalZoneExit] = []
    @State private var isLoading = false
    @State private var zones: [Zone] = []
    @State private var isZonesSectionExpanded = false


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
                DisclosureGroup("Zones", isExpanded: $isZonesSectionExpanded) {
                    if isLoading {
                        ProgressView()
                    } else if zoneExits.isEmpty {
                        Text("No zone exits recorded")
                    } else {
                        ForEach(zoneExits, id: \.id) { exit in
                            VStack(alignment: .leading) {
                                Text("Zone ID: \(exit.zone_id)")
                                Text("Exit Time: \(formatDate(exit.exit_time))")
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("All Zones")) {
                DisclosureGroup("Zones", isExpanded: $isZonesSectionExpanded) {
                    if isLoading {
                        ProgressView()
                    } else if zones.isEmpty {
                        Text("No zones available")
                    } else {
                        ForEach(zones, id: \.id) { zone in
                            VStack(alignment: .leading) {
                                Text("Zone Id:  \(zone.id)")
                                Text("Zone Name: \(zone.name)")
                                Text("Latitude: \(zone.latitude)")
                                Text("Longitude: \(zone.longitude)")
                                Text("Radius: \(zone.radius)")
                                Text("Category: \(zone.category)")
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Debug Menu")
        .onAppear {
            fetchZoneExitsForCurrentUser()
            fetchAllZones()
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
            fetchZoneExitsForCurrentUser()
            fetchAllZones()
        }
    }

    private func fetchAllZones() {
        isLoading = true
        
        Task {
            do {
                let fetchedZones: [Zone] = try await supabase
                    .from("zones")
                    .select()
                    .execute()
                    .value
                
                DispatchQueue.main.async {
                    self.zones = fetchedZones
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                print("Failed to fetch zones: \(error)")
            }
        }
    }

    private func fetchZoneExitsForCurrentUser() {
        guard let currentUser = friendsDataManager.currentUser else { return }
        isLoading = true
        
        Task {
            do {
                let fetchedZoneExits = try await ZoneUpdateManager(supabaseClient: supabase)
                    .fetchZoneExits(for: currentUser.id)
                DispatchQueue.main.async {
                    self.zoneExits = fetchedZoneExits
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                print("Failed to fetch zone exits: \(error)")
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
