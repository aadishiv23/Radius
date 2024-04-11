//
//  MapView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/5/24.
//

import SwiftUI
import MapKit
import Foundation
import CoreLocationUI



/*struct MapCardView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    @State private var navigateToFullScreenMap = false
    
    var body: some View {
        VStack {
            NavigationLink(destination: FullScreenMapView(region: $region), isActive: $navigateToFullScreenMap) {
                EmptyView()
            }
            Map(coordinateRegion: $region)
                .frame(height: 300)
                .cornerRadius(25)
                .shadow(radius: 10)
                .padding()
                .onTapGesture {
                    navigateToFullScreenMap = true
                }
        }
    }
}

struct FullScreenMapView: View {
    @Binding var region: MKCoordinateRegion
    
    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true)
            .ignoresSafeArea()
    }
}*/

struct ContentView: View {
    
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $viewModel.region, showsUserLocation: true)
                .ignoresSafeArea()
                .tint(.purple)
                        
            LocationButton(.currentLocation) {
                viewModel.requestAllowOnceLocationPermission()
            }
            .foregroundStyle(.white)
            .cornerRadius(8)
            .labelStyle(.titleAndIcon)
            .symbolVariant(.fill)
            .padding(.bottom, 10)
        }
        .onAppear {
            viewModel.checkLocationAuthorizationStatus()
        }
    }
}

final class ContentViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40, longitude: 120),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )
    
    let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func checkLocationAuthorizationStatus() {
            locationManager.requestAlwaysAuthorization()
        }
    
    
    func requestAllowOnceLocationPermission() {
        // locationManager.requestLocation()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.first else { return }
        
        
        // update ui so make sure back on main thread
        DispatchQueue.main.async {
            self.region = MKCoordinateRegion(center: latestLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print(error.localizedDescription)
    }
    
    
}

#Preview {
    ContentView()
}
