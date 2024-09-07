//
//  LocationSettingsView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/6/24.
//

import Foundation
import SwiftUI

struct LocationSettingsView: View {
    @ObservedObject var locationManager = LocationManager.shared
    
    var body: some View {
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
        .navigationBarTitle("Location Settings")
    }
}
