//
//  ZoneEntryView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/28/24.
//


import SwiftUI
import MapKit

struct CustomView: View {

    @Binding var percentage: Double // or some value binded
    @State private var heightMultiplier: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            // TODO: - there might be a need for horizontal and vertical alignments
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(.gray)
                Rectangle()
                    .foregroundColor(.accentColor)
                    .frame(width: geometry.size.width * CGFloat(self.percentage / 100))
            }
            .cornerRadius(12)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged({ value in
                    // TODO: - maybe use other logic here
                    let newHeightMultiplier = min(max(1, heightMultiplier + (value.translation.height / geometry.size.height)), 2) // Limiting height to double the original
                    let newPercentage = min(max(0, Double(value.location.x / geometry.size.width * 100)), 100)
                    self.percentage = newPercentage
                    self.heightMultiplier = newHeightMultiplier
                }))
        }
    }
}

struct ZoneEditorView: View {
    @Binding var isPresenting: Bool
    @Binding var userZones: [Zone]
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @State private var newZoneLocation: CLLocationCoordinate2D?
    @State private var zoneRadius: Double = 100.0
    @State private var showAddressEntry: Bool = false
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion.defaultRegion
    @State private var zoneName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    TextField("Zone name", text: $zoneName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .focused($isTextFieldFocused)
                    
                    MapView(region: $mapRegion, location: $newZoneLocation, radius: $zoneRadius)
                        .frame(height: 300)
                        .padding()

                    //Slider(value: $zoneRadius, in: 10...500, step: 5)
                    CustomView(percentage: $zoneRadius)
                        .padding()
                    
                    Text("Radius: \(zoneRadius, specifier: "%.1f") meters")
                        .padding()
                        .contentTransition(.numericText())
                        //.contentTransition(.numericTransition())
                        .animation(.easeInOut, value: zoneRadius)
                    
                    Button("Enter Address") {
                        showAddressEntry = true
                    }
                    .padding()
                    
                    Button("Save Zone") {
                        saveZone()
                    }
                    .disabled(newZoneLocation == nil || zoneName.isEmpty)
                    .padding()
                }
                .navigationTitle("Add Zone")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresenting = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddressEntry) {
            AddressEntryView(
                isPresenting: $showAddressEntry,
                newZoneLocation: $newZoneLocation,
                zoneName: $zoneName,
                zoneRadius: $zoneRadius
            )
        }
        .onAppear {
            if let userLocation = LocationManager.shared.userLocation {
                mapRegion = MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                newZoneLocation = userLocation.coordinate
            }
        }
    }
    
    private func saveZone() {
        if let location = newZoneLocation, let currentUser = friendsDataManager.currentUser {
            let newZone = Zone(id: UUID(), name: zoneName, latitude: location.latitude, longitude: location.longitude, radius: zoneRadius, profile_id: currentUser.id)
            self.userZones.append(newZone)
            self.isPresenting = false
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
