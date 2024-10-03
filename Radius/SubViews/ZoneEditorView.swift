//
//  ZoneEntryView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/28/24.
//

import MapKit
import SwiftUI

struct CustomView: View {

    @Binding var value: Double
    let minValue: Double
    let maxValue: Double

    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Text("\(minValue, specifier: "%.0f")m")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(maxValue, specifier: "%.0f")m")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 8)

                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(Color.gray.opacity(0.3))
                        .frame(height: 20)
                        .cornerRadius(10)

                    Rectangle()
                        .foregroundColor(.accentColor)
                        .frame(
                            width: geometry.size.width * CGFloat((value - minValue) / (maxValue - minValue)),
                            height: 20
                        )
                        .cornerRadius(10)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let newValue = minValue + (maxValue - minValue) *
                                Double(gesture.location.x / geometry.size.width)
                            value = min(max(minValue, newValue), maxValue)
                        }
                )
                .animation(.easeInOut, value: value)
            }
        }
        .frame(height: 60)
    }
}

struct ZoneEditorView: View {
    @Binding var isPresenting: Bool
    @Binding var userZones: [Zone]
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @State private var newZoneLocation: CLLocationCoordinate2D?
    @State private var zoneRadius = 100.0
    @State private var showAddressEntry = false
    @State private var mapRegion = MKCoordinateRegion.defaultRegion
    @State private var zoneName = ""
    @State private var selectedCategory: ZoneCategory = .other
    @FocusState private var isTextFieldFocused: Bool
    @State private var isSliderFocused = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Address Entry Button
                    Button(action: {
                        showAddressEntry = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Enter Address")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Zone Name TextField
                    VStack(alignment: .leading) {
                        Text("Zone Name")
                            .font(.headline)
                        TextField("Enter zone name", text: $zoneName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .focused($isTextFieldFocused)
                    }
                    .padding(.horizontal)

                    // Zone Category Picker
                    VStack(alignment: .leading) {
                        Text("Category")
                            .font(.headline)
                        Picker("Zone Category", selection: $selectedCategory) {
                            ForEach(ZoneCategory.allCases, id: \.self) { category in
                                Text(category.rawValue.capitalized).tag(category)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 5)
                    }
                    .padding(.horizontal)

                    // MapView with Rounded Corners
                    MapView(region: $mapRegion, location: $newZoneLocation, radius: $zoneRadius)
                        .frame(height: 300)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .padding(.horizontal)

                    // Custom Slider with Bounds
                    VStack {
                        CustomView(value: $zoneRadius, minValue: 0, maxValue: 500)
                            .scaleEffect(isSliderFocused ? 1.1 : 1.0)
                            .padding(.horizontal)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        isSliderFocused = true
                                    }
                                    .onEnded { _ in
                                        isSliderFocused = false
                                    }
                            )

                        Text("Radius: \(zoneRadius, specifier: "%.1f") meters")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                    }

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Add Zone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel Button on the Leading
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresenting = false
                    }
                }

                // Save Button on the Trailing
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveZone()
                    }
                    .disabled(newZoneLocation == nil || zoneName.trimmingCharacters(in: .whitespaces).isEmpty)
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
                mapRegion = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                newZoneLocation = userLocation.coordinate
            }
        }
    }

    private func saveZone() {
        if let location = newZoneLocation, let currentUser = friendsDataManager.currentUser {
            let newZone = Zone(
                id: UUID(),
                name: zoneName.trimmingCharacters(in: .whitespaces),
                latitude: location.latitude,
                longitude: location.longitude,
                radius: zoneRadius,
                profile_id: currentUser.id,
                category: selectedCategory
            )
            userZones.append(newZone)
            isPresenting = false
        }
    }
}

/// Default region could be set to the user's current location or a predefined location.
extension MKCoordinateRegion {
    static var defaultRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
}

