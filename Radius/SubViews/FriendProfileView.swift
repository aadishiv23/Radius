//
//  FriendProfileView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/25/24.
//

import Foundation
import SwiftUI

// Define a simple profile view for displaying friend details
struct FriendProfileView: View {
    var friend: Profile
    @State private var editingZoneId: UUID? = nil
    @State private var zoneName: String = ""
    @EnvironmentObject var friendsDataManager: FriendsDataManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Name: \(friend.full_name)")
                .font(.title)
            Text("Coordinates: \(friend.latitude), \(friend.longitude)")
                .font(.subheadline)
            ForEach(friend.zones) { zone in
                VStack {
                    if editingZoneId == zone.id {
                        TextField("Zone name", text: $zoneName)
                            .onSubmit {
                                Task {
                                    do {
                                        try await friendsDataManager.renameZone(zoneId: zone.id, newName: zoneName)
                                        // Refresh friend profile data here or use an observable object to trigger a view update.
                                        editingZoneId = nil // Exit editing mode after saving.
                                    } catch {
                                        print("Failed to rename zone")
                                    }
                                }
                            }
                            .onAppear {
                                zoneName = zone.name
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                    } else {
                        Text(zone.name)
                            .onTapGesture {
                                editingZoneId = zone.id
                                zoneName = zone.name
                            }
                    }
                    Text(String(zone.latitude))
                    Text(String(zone.longitude))
                    Text(String(zone.radius))
                }
                .background(Rectangle().foregroundStyle(.blue).opacity(0.3))
            }
            Spacer()
        }
        .padding()
        .navigationTitle(friend.full_name)
    }
}

