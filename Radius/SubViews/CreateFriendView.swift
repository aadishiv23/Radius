//
//  CreateFriendView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/6/24.
//

import Foundation
import SwiftUI
import CoreLocation

struct CreateFriendView: View {
    @EnvironmentObject var friendDataManager: FriendsDataManager
    @Environment(\.presentationMode) var presentationMode

    @State private var friendName: String
    @State private var friendColor: String = "#FFFFF"
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @State private var zones: [Zone] = []
    @State private var isPresentingZoneEditor = false

    
    @State private var zoneName: String = ""
    @State private var zoneRadius: String = ""
    @State private var zoneLatitude: String = ""
    @State private var zoneLongitude: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $friendName)
                    TextField("Color", text: $friendColor)
                    TextField("Latitude", text: $latitude)
                        .keyboardType(.decimalPad)
                    TextField("Longitude", text: $longitude)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Friend Details")
                }
                
                
                Section {
                    ForEach(zones, id: \.id) { zone in
                        Text("\(zone.name): \(zone.radius) meters around (\(zone.latitude), \(zone.longitude))")
                    }
                    Button("Add Zone") {
                        isPresentingZoneEditor.toggle()
                    }
                    .sheet(isPresented: $isPresentingZoneEditor) {
                        ZoneEditorView(isPresenting: $isPresentingZoneEditor, userZones: $zones)
                            .environmentObject(friendDataManager)
                    }
                } header: {
                    Text("Zones")
                }
                
            }
        }
    }
    
}
