//
//  MyProfileView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/11/24.
//

import Foundation
import SwiftUI

struct MyProfileView: View {
    @State private var editing = false
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @Environment(\.dismiss) var dismiss

    @State private var zoneExits: [ZoneExit] = []
    @State private var zones: [UUID: Zone] = [:]
    @State private var showAllZoneExits = false
    @State private var showDeleteConfirmation = false
    @State private var zoneToDelete: Zone?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                friendInfoSection
                    .visionGlass()

                zonesSection
                    .visionGlass()

                zoneExitsSection // New section for recent zone exits
                    .visionGlass()
            }
            .padding(.top, 40)
        }
        .navigationTitle("My Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    editing.toggle()
                }) {
                    Text(editing ? "Done" : "Edit")
                }
            }
        }
        .onAppear {
            Task {
                do {
                    // Fetch the recent zone exits
                    let fetchedZoneExits = try await friendsDataManager
                        .fdmFetchZoneExits(for: friendsDataManager.currentUser.id)
                    zoneExits = Array(fetchedZoneExits.prefix(5)) // Show only the top 5 most recent exits
                    let zoneIds = fetchedZoneExits.map(\.zone_id)
                    zones = try await friendsDataManager.fetchZonesDict(for: zoneIds)
                } catch {
                    print("Failed to load zone exits and associated zones: \(error)")
                }
            }
        }
        .background(
            NavigationLink(
                destination: AllZoneExitsView(friend: friendsDataManager.currentUser),
                isActive: $showAllZoneExits
            ) {
                EmptyView()
            }
        )
        .confirmationDialog(
            "Are you sure you want to delete \(zoneToDelete?.name ?? "this zone")?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let zone = zoneToDelete {
                    deleteZone(zone)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var friendInfoSection: some View {
        VStack(spacing: 10) {
            Text("Name: \(friendsDataManager.currentUser.full_name)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Username: \(friendsDataManager.currentUser.username)")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Coordinates: \(friendsDataManager.currentUser.latitude), \(friendsDataManager.currentUser.longitude)")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Number of Zones: \(friendsDataManager.currentUser.zones.count)")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }

    private var zonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Zones")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: ZoneGridView()) {
                    Image(systemName: "plus")
                        .foregroundColor(.blue)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(friendsDataManager.currentUser.zones) { zone in
                        ZStack(alignment: .topTrailing) {
                            PolaroidCard(zone: zone)

                            if editing {
                                Button(action: {
                                    showDeleteConfirmation(for: zone)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                        .offset(x: -10, y: 10)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .padding()
    }

    /// New section to display recent zone exits
    private var zoneExitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Zone Exits")
                    .font(.headline)
                Spacer()
                Button(action: {
                    showAllZoneExits = true
                }) {
                    Text("See More")
                        .foregroundColor(.blue)
                }
            }

            if zoneExits.isEmpty {
                Text("No zone exits available.")
                    .foregroundColor(.gray)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(zoneExits) { exit in
                            if let zone = zones[exit.zone_id] {
                                ZoneExitRow(zoneExit: exit, zone: zone)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
        }
        .padding()
    }

    private func showDeleteConfirmation(for zone: Zone) {
        zoneToDelete = zone
        showDeleteConfirmation = true
    }

    private func deleteZone(_ zone: Zone) {
        Task {
            try? await friendsDataManager.deleteZone(zoneId: zone.id)
            // Update the UI after deleting the zone
            await friendsDataManager.fetchCurrentUserProfile()
        }
    }
}

struct ZoneGridView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @State private var editing = false
    @State private var showDeleteConfirmation = false
    @State private var zoneToDelete: Zone?

    var body: some View {
        VStack {
            HStack {
                Text("My Zones")
                    .font(.headline)
                Spacer()
                Button(action: { editing.toggle() }) {
                    Text(editing ? "Done" : "Edit")
                }
            }
            .padding()

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                    ForEach(friendsDataManager.currentUser.zones) { zone in
                        ZStack(alignment: .topTrailing) {
                            PolaroidCard(zone: zone)

                            if editing {
                                Button(action: {
                                    showDeleteConfirmation(for: zone)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                        .padding(5)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Zones")
        .confirmationDialog(
            "Are you sure you want to delete \(zoneToDelete?.name ?? "this zone")?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let zone = zoneToDelete {
                    deleteZone(zone)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func showDeleteConfirmation(for zone: Zone) {
        zoneToDelete = zone
        showDeleteConfirmation = true
    }

    private func deleteZone(_ zone: Zone) {
        Task {
            do {
                // Call delete function in the data manager
                try await friendsDataManager.deleteZone(zoneId: zone.id)

                // Optional: Trigger a local UI update (this is redundant if the profile is refetched)
                if let index = friendsDataManager.currentUser.zones.firstIndex(where: { $0.id == zone.id }) {
                    friendsDataManager.currentUser.zones.remove(at: index)
                }
            } catch {
                print("Error deleting zone: \(error)")
            }
        }
    }
}
