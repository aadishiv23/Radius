//
//  MapView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/5/24.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.33516, longitude: -121.891054), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
    
    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true)
            .ignoresSafeArea() // remove top and bottom white bar
    }
}

#Preview {
    MapView()
}
