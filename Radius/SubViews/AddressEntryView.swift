//
//  AddressEntryView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/28/24.
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit

struct AddressEntryView: View {
    //@Binding var showView: Bool
    //@Binding var locationToAdd: CLLocationCoordinate2D?
    @Binding var isPresenting: Bool
    @Binding var userZones: [Zone]
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @StateObject var viewModel: AddressEntryViewModel = AddressEntryViewModel()
    @FocusState private var isFocusedTextField: Bool
    @State private var selectedAddress: AddressResult?
    @State private var zoneName: String = ""
    @State private var zoneRadius: Double = 100.0
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                TextField("Zone name", text: $zoneName)
                   .textFieldStyle(RoundedBorderTextFieldStyle())
                   .padding()
    
                TextField("Type address", text: $viewModel.searchableText)
                    .padding()
                    .autocorrectionDisabled()
                    .focused($isFocusedTextField)
                    .font(.title)
                    .onReceive(
                        viewModel.$searchableText.debounce(
                            for: .seconds(1),
                            scheduler: DispatchQueue.main
                        )
                    ) {
                        viewModel.searchAddress($0)
                    }
                    .background(Color.init(uiColor: .systemBackground))
                    .onAppear {
                        isFocusedTextField = true
                    }
                
                List(self.viewModel.results) { address in
                        AddressRow(address: address)
                            .listRowBackground(backgroundColor)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                
                if let selectedAddress = selectedAddress {
                    AddressEntryMapView(address: selectedAddress)
                        .frame(height: 200)
                        .padding()

                    Slider(value: $zoneRadius, in: 10...500, step: 5)
                        .padding()
                    
                    Text("Radius: \(zoneRadius, specifier: "%.1f") meters")
                        .padding()

                    Button("Save Zone") {
                        saveZone()
                    }
                }
                
            }
            .navigationTitle("Add Zone")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresenting = false
            })
        }
    }
    
    var backgroundColor: Color = Color.init(uiColor: .systemGray6)
    
    private func saveZone() {
        guard let address = selectedAddress,
              let currentUser = friendsDataManager.currentUser else { return }

        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address.subtitle) { placemarks, error in
            if let location = placemarks?.first?.location {
                let newZone = Zone(id: UUID(),
                                   name: zoneName,
                                   latitude: location.coordinate.latitude,
                                   longitude: location.coordinate.longitude,
                                   radius: zoneRadius,
                                   profile_id: currentUser.id)
                userZones.append(newZone)
                isPresenting = false
            }
        }
    }
}


//struct AddressRow: View {
//    
//    let address: AddressResult
//    
//    var body: some View {
//        NavigationLink {
//            AddressEntryMapView(address: address)
//        } label: {
//            VStack(alignment: .leading) {
//                Text(address.title)
//                Text(address.subtitle)
//                    .font(.caption)
//            }
//        }
//        .padding(.bottom, 2)
//    }
//}

struct AddressRow: View {
    let address: AddressResult
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(address.title)
            Text(address.subtitle)
                .font(.caption)
        }
        .padding(.bottom, 2)
    }
}

//struct AddressEntryMapView: View {
//    
//    @StateObject private var viewModel = AddressEntryMapViewModel()
//
//    private let address: AddressResult
//    
//    init(address: AddressResult) {
//        self.address = address
//    }
//    
//    var body: some View {
//        Map(
//            coordinateRegion: $viewModel.region,
//            annotationItems: viewModel.annotationItems,
//            annotationContent: { item in
//                MapMarker(coordinate: item.coordinate)
//            }
//        )
//        .onAppear {
//            self.viewModel.getPlace(from: address)
//        }
//        .edgesIgnoringSafeArea(.bottom)
//    }
//}

struct AddressEntryMapView: View {
    @StateObject private var viewModel = AddressEntryMapViewModel()
    private let address: AddressResult
    
    init(address: AddressResult) {
        self.address = address
    }
    
    var body: some View {
        Map(
            coordinateRegion: $viewModel.region,
            annotationItems: viewModel.annotationItems,
            annotationContent: { item in
                MapMarker(coordinate: item.coordinate)
            }
        )
        .onAppear {
            self.viewModel.getPlace(from: address)
        }
    }
}
