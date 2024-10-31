//
//  DebugMenu.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/23/24.
//

import Combine
import CoreLocation
import Foundation
import SwiftUI

// MARK: - DebugMenuView

struct DebugMenuView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    ///    @StateObject private var zoneExitObserver = ZoneExitObserver()
    @State private var zoneExits: [ZoneExit] = []
    // @State private var localZoneExits: [LocalZoneExit] = []
    @State private var isLoading = false
    @State private var zones: [Zone] = []
    @State private var isZonesSectionExpanded = false
    @State private var isZonesExitsSectionExpanded = false
    @State private var monitoredZones: [(UUID, Bool)] = []
    @State private var isLoadingMonitoredZones = false
    @State private var selectedZoneForDeletion: UUID?

    @State private var monitorEvents: [CLMonitor.Event] = []
    @State private var monitorRecords: [(zoneId: UUID, record: CLMonitor.Record)] = []
    @State private var isLoadingMonitorData = false
    @State private var isLoadingMonitorRecordData = false

    // Alert state for showing whether the function executed successfully
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        List {
            Section(header: Text("Zone Management")) {
                Button("Execute Zone Exit & Handle Daily Zone Exits") {
                    executeZoneExitAndHandleDaily()
                }
            }

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
//            Section(header: Text("Local Zone Exits")) {
//                if localZoneExits.isEmpty {
//                    Text("No local zone exits recorded")
//                } else {
//                    ForEach(localZoneExits.reversed(), id: \.id) { exit in
//                        VStack(alignment: .leading) {
//                            Text("Zone: \(exit.zoneName)")
//                            Text("Exit Time: \(formatDate(exit.exitTime))")
//                            Text("Latitude: \(exit.latitude)")
//                            Text("Longitude: \(exit.longitude)")
//                        }
//                    }
//                }
//            }

            Section(header: Text("Monitored Zones")) {
                if isLoadingMonitoredZones {
                    ProgressView()
                } else if monitoredZones.isEmpty {
                    Text("No zones are being monitored")
                } else {
                    ForEach(monitoredZones, id: \.0) { zone in
                        VStack(alignment: .leading) {
                            Text("Zone ID: \(zone.0.uuidString)")
                            Text("Status: \(zone.1 ? "Monitored" : "Not Monitored")")
                            Button(action: {
                                selectedZoneForDeletion = zone.0
                            }) {
                                Text("Remove from Monitoring")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section(header: Text("Zone Exits")) {
                DisclosureGroup("Zones", isExpanded: $isZonesExitsSectionExpanded) {
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

            Section(header: Text("Monitored Zones")) {
                if isLoadingMonitoredZones {
                    ProgressView()
                } else if monitoredZones.isEmpty {
                    Text("No zones being monitored")
                } else {
                    ForEach(monitoredZones, id: \.0) { zone in
                        VStack(alignment: .leading) {
                            Text("Zone ID: \(zone.0.uuidString)")
                            Text("Status: \(zone.1 ? "Monitored" : "Not Monitored")")
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section(header: Text("Monitor Events")) {
                if isLoadingMonitorData {
                    ProgressView()
                } else if monitorEvents.isEmpty {
                    Text("No monitor events recorded")
                } else {
                    ForEach(monitorEvents, id: \.identifier) { event in
                        VStack(alignment: .leading) {
                            Text("Identifier: \(event.identifier)")
                            Text("State: \(event.state == .satisfied ? "Satisfied" : "Unsatisfied")")
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

//            Section(header: Text("Monitor Records")) {
//                if isLoadingMonitorData {
//                    ProgressView()
//                } else if monitorRecords.isEmpty {
//                    Text("No monitor records found")
//                } else {
//                    ForEach(monitorRecords, id: \.zoneId) { recordPair in
//                        VStack(alignment: .leading) {
//                            Text("Zone ID: \(recordPair.zoneId.uuidString)")  // Access zoneId correctly from the
//                            tuple
//                            Text("Record State: \(recordPair.record.state == .satisfied ? "Satisfied" :
//                            "Unsatisfied")")
//                        }
//                        .padding(.vertical, 4)
//                    }
//                }
//            }
        }
        .navigationTitle("Debug Menu")
        .onAppear {
            fetchZoneExitsForCurrentUser()
            fetchAllZones()
            fetchMonitoredZones()
            fetchMonitorEvents()
            fetchMonitorRecords()
        }
        .refreshable {
            await friendsDataManager.fetchCurrentUserProfile()
            fetchZoneExitsForCurrentUser()
            fetchAllZones()
            fetchMonitoredZones()
            fetchMonitorEvents()
            fetchMonitorRecords()
        }
        // Present an alert based on the outcome of function execution
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Execution Result"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: .constant(selectedZoneForDeletion != nil)) {
            Alert(
                title: Text("Confirm Removal"),
                message: Text("Are you sure you want to remove this zone from monitoring?"),
                primaryButton: .destructive(Text("Remove")) {
                    if let zoneId = selectedZoneForDeletion {
                        removeZoneFromMonitoring(zoneId)
                    }
                },
                secondaryButton: .cancel {
                    selectedZoneForDeletion = nil
                }
            )
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
                    zones = fetchedZones
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                }
                print("Failed to fetch zones: \(error)")
            }
        }
    }

    private func fetchZoneExitsForCurrentUser() {
        guard let currentUser = friendsDataManager.currentUser else {
            return
        }
        isLoading = true

        Task {
            do {
                let fetchedZoneExits = try await ZoneUpdateManager(supabaseClient: supabase)
                    .fetchZoneExits(for: currentUser.id)
                DispatchQueue.main.async {
                    zoneExits = fetchedZoneExits
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                }
                print("Failed to fetch zone exits: \(error)")
            }
        }
    }

    private func fetchMonitoredZones() {
        isLoadingMonitoredZones = true

        Task {
            let monitoredZonesResult = await LocationManager.shared.getMonitoredZones()
            DispatchQueue.main.async {
                monitoredZones = monitoredZonesResult
                isLoadingMonitoredZones = false
            }
        }
    }


    private func removeZoneFromMonitoring(_ zoneId: UUID) {
        Task {
            await LocationManager.shared.removeMonitoredZone(byId: zoneId)
            fetchMonitoredZones() // Refresh the list after removal
            selectedZoneForDeletion = nil
        }
    }

    private func fetchMonitorEvents() {
        isLoadingMonitorData = true

        Task {
            let fetchedEvents = try await LocationManager.shared.getMonitorEvents()

            DispatchQueue.main.async {
                monitorEvents = fetchedEvents
                isLoadingMonitorData = false
            }
        }
    }

    private func fetchMonitorRecords() {
        isLoadingMonitorRecordData = true

        Task {
            let fetchedRecords = await LocationManager.shared.getMonitorRecords()

            DispatchQueue.main.async {
                monitorRecords = fetchedRecords // Make sure this is [(UUID, CLMonitor.Record)]
                isLoadingMonitorRecordData = false
            }
        }
    }

    /// Function that executes the zone exit and handles daily zone exits
    private func executeZoneExitAndHandleDaily() {
        Task {
            do {
                // Use the constant zoneId you mentioned earlier
                guard let currentUser = friendsDataManager.currentUser else {
                    alertMessage = "No current user available."
                    showAlert = true
                    return
                }

                let currentProfileId = currentUser.id
                let constantZoneId = UUID(uuidString: "82e295db-7477-4de7-bb9d-bbb2fb430a3d")!

                // Execute zone exit
                try await ZoneUpdateManager(supabaseClient: supabase)
                    .uploadZoneExit(for: currentProfileId, zoneIds: [constantZoneId], at: Date())

                // Handle daily zone exits
                try await ZoneUpdateManager(supabaseClient: supabase)
                    .handleDailyZoneExits(for: currentProfileId, zoneIds: [constantZoneId], at: Date())

                // Success: Update the alert message
                DispatchQueue.main.async {
                    alertMessage = "Successfully executed both zone exit and daily zone exit functions."
                    showAlert = true
                }

            } catch {
                // Failure: Show an error message in the alert
                DispatchQueue.main.async {
                    alertMessage =
                        "Failed to execute zone exit or handle daily zone exits: \(error.localizedDescription)"
                    showAlert = true
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

// class ZoneExitObserver: ObservableObject {
//    @Published var localZoneExits: [LocalZoneExit] = []
//    private var cancellables = Set<AnyCancellable>()
//
//    func startObserving() {
//        NotificationCenter.default.publisher(for: .zoneExited)
//            .sink { [weak self] notification in
//                if let zoneExit = notification.object as? LocalZoneExit {
//                    DispatchQueue.main.async {
//                        self?.localZoneExits.append(zoneExit)
//                        // Keep only the last 10 exits
//                        self?.localZoneExits = Array(self?.localZoneExits.suffix(10) ?? [])
//                    }
//                }
//            }
//            .store(in: &cancellables)
//    }
//
//    func stopObserving() {
//        cancellables.removeAll()
//    }
// }
