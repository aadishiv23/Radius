//
//  AllZonesExitsView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/18/24.
//

import Foundation
import SwiftUI

struct AllZoneExitsView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    var friend: Profile

    @State private var allZoneExits: [ZoneExit] = []
    @State private var zones: [UUID: Zone] = [:]
    
    @State private var isFetching: Bool = false // tracks whether we are actively fetching exits
    @State private var page: Int = 0
    // Number of exits to fetch per 'page'
    private let pageSize = 20

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.yellow.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                Text("All Zone Exits")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                VStack(alignment: .leading, spacing: 10) {
                    if allZoneExits.isEmpty {
                        Text("No zone exits available.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(allZoneExits) { exit in
                            if let zone = zones[exit.zone_id] {
                                ZoneExitRow(zoneExit: exit, zone: zone)
                            }
                        }
                    }
                    if isFetching {
                        ProgressView()
                            .padding()
                    } else {
                        Button(action: loadNextPage) {
                            Text("Load More")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                }
                .padding()
                .visionGlass()
            }
        }
        .onAppear {
            loadNextPage()
        }
    }
    
    private func loadNextPage() {
        guard !isFetching else { return }
        isFetching = true
        
        Task {
            do {
                // Fetch next batch
                let fetchedZoneExits = try await friendsDataManager.fdmFetchZoneExits(for: friend.id)
                self.allZoneExits.append(contentsOf: fetchedZoneExits)
                
                // Fetch zones for the unique zone IDs
                let uniqueZoneIds = Array(Set(fetchedZoneExits.map { $0.zone_id }))
                let newZones = try await friendsDataManager.fetchZonesDict(for: uniqueZoneIds)
                self.zones.merge(newZones) { _, new in new}
            } catch {
                print("[AllZoneExitsView] Failed to load next page: \(error)")
            }
            isFetching = false
        }
    }
}
