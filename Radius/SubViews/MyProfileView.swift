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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                friendInfoSection
                    .visionGlass()
                
                zonesSection
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
                                    removeZone(zone)
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
    
    private func removeZone(_ zone: Zone) {
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
                                    removeZone(zone)
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
    }
    
    private func removeZone(_ zone: Zone) {
        Task {
            try? await friendsDataManager.deleteZone(zoneId: zone.id)
            await friendsDataManager.fetchCurrentUserProfile()
        }
    }
}
