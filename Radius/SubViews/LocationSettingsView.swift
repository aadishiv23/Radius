//
//  LocationSettingsView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/6/24.
//

import Foundation
import SwiftUI
import CoreLocation

struct LocationSettingsView: View {
    @ObservedObject var locationManager = LocationManager.shared
    
    var body: some View {
        VStack {
            // Check location authorization status and show a message if denied
            if locationAuthorizationStatus == .denied || locationAuthorizationStatus == .restricted {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Location access is required for core app features, like tracking zones and providing updates.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: openAppSettings) {
                        Text("Allow Location Access")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            
            // The main form for location settings
            Form {
                Section(header: Text("Location Accuracy")) {
                    Picker("Accuracy Mode", selection: $locationManager.accuracyMode) {
                        Text("High Accuracy").tag(LocationAccuracyMode.highAccuracy)
                        Text("Balanced").tag(LocationAccuracyMode.balanced)
                        Text("Low Power").tag(LocationAccuracyMode.lowPower)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
        .navigationBarTitle("Location Settings")
    }
    
    // Computed property to get the current authorization status
    private var locationAuthorizationStatus: CLAuthorizationStatus {
        CLLocationManager.authorizationStatus()
    }
    
    // Helper to open app settings
    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsURL) else { return }
        UIApplication.shared.open(settingsURL)
    }
}
