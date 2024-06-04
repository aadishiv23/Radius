//
//  AddressEntryView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/28/24.
//

import Foundation
import SwiftUI
import CoreLocation

struct AddressEntryView: View {
    @Binding var showView: Bool
    @Binding var locationToAdd: CLLocationCoordinate2D?
    @State private var address: String = ""

    
    var body: some View {
        Form {
            Section(header: Text("Enter Address")) {
                TextField("Address", text: $address)
                Button("Confirm") {
                    geocodeAddress(address)
                }
            }
        }
        .navigationTitle("Add Zone")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Map Editor") {
                    showView = false
                }
            }
        }
    }
    
    private func geocodeAddress(_ address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let placemark = placemarks?.first, let location = placemark.location {
                self.locationToAdd = location.coordinate
                self.showView = false
            }
            else {
                print("Address geocoding failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}


