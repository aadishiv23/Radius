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
    @State private var friendName: String
    @State private var friendColor: String = "#FFFFF"
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @State private var zones: [Zone] = []
    
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
                    TextField("Longitude", text: $longitude)
                } header: {
                    Text("Friend Details")
                }
                
                
                Section {
                    ForEach(zones, id: \.id) { zone in
                        Text("\(zone.name): \(zone.radius) meters around (\(zone.coordinate.latitude), \(zone.coordinate.longitude))")
                    }
                    Button("Add Zone") {
                        
                    }
                } header: {
                    Text("Zones")
                }
                
            }
        }
    }
    
}
