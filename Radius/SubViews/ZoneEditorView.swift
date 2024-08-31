//
//  ZoneEntryView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/28/24.
//


import SwiftUI
import MapKit

struct CustomView: View {

    @Binding var value: Double
    let minValue: Double
    let maxValue: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(.gray)
                Rectangle()
                    .foregroundColor(.accentColor)
                    .frame(width: geometry.size.width * CGFloat((value - minValue) / (maxValue - minValue)))
            }
            .cornerRadius(12)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged({ value in
                    let newValue = minValue + (maxValue - minValue) * Double(value.location.x / geometry.size.width)
                    self.value = min(max(minValue, newValue), maxValue)
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
    @State private var selectedCategory: ZoneCategory = .other
    @FocusState private var isTextFieldFocused: Bool
    @State private var isSliderFocused: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Button(action: {
                        showAddressEntry = true
                    }) {
                        Text("Enter Address")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding()

                    TextField("Zone name", text: $zoneName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .focused($isTextFieldFocused)

                    Picker("Zone Category", selection: $selectedCategory) {
                        ForEach(ZoneCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()

                    MapView(region: $mapRegion, location: $newZoneLocation, radius: $zoneRadius)
                        .frame(height: 300)
                        .padding()

                    CustomView(value: $zoneRadius, minValue: 0, maxValue: 500)
                        .scaleEffect(isSliderFocused ? 1.2 : 1.0)
                        .padding()
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged({ _ in
                                isSliderFocused = true
                            })
                            .onEnded({ _ in
                                isSliderFocused = false
                            }))

                    Text("Radius: \(zoneRadius, specifier: "%.1f") meters")
                        .padding()
                        .contentTransition(.numericText())
                        .animation(.easeInOut, value: zoneRadius)

                    Button(action: {
                        saveZone()
                    }) {
                        Text("Save Zone")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
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
            let newZone = Zone(id: UUID(), name: zoneName, latitude: location.latitude, longitude: location.longitude, radius: zoneRadius, profile_id: currentUser.id, category: selectedCategory)
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
