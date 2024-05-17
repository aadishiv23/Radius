//
//  ZoneEntryView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/28/24.
//


import SwiftUI
import MapKit

struct ZoneEditorView: View {
    @Binding var isPresenting: Bool
    @Binding var userZones: [Zone]
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @State private var newZoneLocation: CLLocationCoordinate2D?
    @State private var newZoneRadius: Double = 100.0
    @State private var showAddressEntry: Bool = false
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion.defaultRegion
    
    var body: some View {
        NavigationView {
            VStack {
                if showAddressEntry {
                    AddressEntryView(showView: $showAddressEntry, locationToAdd: $newZoneLocation)
                } else {
                    MapView(region: $mapRegion, location: $newZoneLocation, radius: $newZoneRadius)
                }
                
                Slider(value: $newZoneRadius, in: 10...500, step: 5)
                    .padding()

                Button("Save Zone") {
                if let location = newZoneLocation, let currentUserFriendLocation = friendsDataManager.currentUser {
                    let newZone = Zone(id: UUID(), name: "New Zone", latitude: location.latitude, longitude: location.longitude, radius: newZoneRadius, profile_id: currentUserFriendLocation.id)
                        self.userZones.append(newZone)
                        self.isPresenting = false
                    }
                }
                .disabled(newZoneLocation == nil)
            }
            .navigationTitle("Add Zone")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresenting = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Address") {
                        showAddressEntry.toggle()
                    }
                }
            }
        }
    }
}

// Default region could be set to the user's current location or a predefined location.
extension MKCoordinateRegion {
    static var defaultRegion: MKCoordinateRegion {
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    }
}


//struct ZoneEditorView: View {
//    @Environment(\.presentationMode) var presentationMode
//    @Binding var userLocation: UserLocation
//    @State var newZoneCenter: CLLocationCoordinate2D?
//    @State var newZoneRadius: Double = 100.0
//    @State var showingAddressEntryView = false
//    
//    var body: some View {
//        NavigationStack {
//            if let newZone = newZoneCenter {
//                // Map(center) custom mapview
//                // for now temp
//                Text("hello")
//            }
//            else {
//                Text("Please select a location by dropping a pin or entering an address")
//            }
//            
//            Button("Drop Pin") {
//                // Code to drop pin on map
//            }
//            .padding()
//            
//            Button("Enter Address") {
//                showingAddressEntryView.toggle()
//            }
//            .padding()
//            .sheet(isPresented: $showingAddressEntryView) {
//                AddressEntryView(showView: $showingAddressEntryView) { coordinate in
//                    newZoneCenter = coordinate
//                }
//            }
//            
//            Button("Save Zone") {
//                guard let center = newZoneCenter else { return }
//                let newZone = Zone(coordinate: center, radius: newZoneRadius)
//                userLocation.zones.append(newZone)
//                presentationMode.wrappedValue.dismiss()
//            }
//            .disabled(newZoneCenter == nil)
//            .padding()
//        }
//        .navigationBarTitle("Edit Zone", displayMode: .inline)
//        .navigationBarItems(trailing: Button("Done") {
//            presentationMode.wrappedValue.dismiss()
//        })
//    }
//}
