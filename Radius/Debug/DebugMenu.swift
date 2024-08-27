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
            // ... (other sections remain the same)

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

            Section(header: Text("Supabase Zone Exits")) {
                if isLoading {
                    ProgressView()
                } else if zoneExits.isEmpty {
                    Text("No Supabase zone exits found")
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

            // ... (other sections remain the same)
        }
        .navigationTitle("Debug Menu")
        .onAppear {
            Task {
                await fetchZoneExits()
            }
            zoneExitObserver.startObserving()
        }
        .onDisappear {
            zoneExitObserver.stopObserving()
        }
        .onReceive(zoneExitObserver.$localZoneExits) { newExits in
            self.localZoneExits = newExits
        }
        .refreshable {
            await refreshData()
        }
    }

    private func refreshData() async {
        await friendsDataManager.fetchCurrentUserProfile()
        await friendsDataManager.fetchUserGroups()
        do {
            zones = try await friendsDataManager.fetchZones(for: friendsDataManager.currentUser?.id ?? UUID())
        } catch {
            print("Couldn't fetch zones: \(error)")
        }
        await fetchZoneExits()
    }

    private func fetchZoneExits() async {
        isLoading = true
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
