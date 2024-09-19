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
                }
                .padding()
                .visionGlass()
            }
        }
        .onAppear {
            Task {
                do {
                    // Fetch all zone exits
                    let fetchedZoneExits = try await friendsDataManager.fdmFetchZoneExits(for: friend.id)
                    self.allZoneExits = fetchedZoneExits
                    let zoneIds = fetchedZoneExits.map { $0.zone_id }
                    self.zones = try await friendsDataManager.fetchZonesDict(for: zoneIds)
                } catch {
                    print("Failed to load zone exits and associated zones: \(error)")
                }
            }
        }
    }
}
