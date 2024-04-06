//
//  MapView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/5/24.
//

import SwiftUI
import MapKit

final class MapViewModel: ObservableObject {
    
    var locationManager: CLLocationManager? // Optional, as user can turn off location service for their whole phone - have to make sure its on
    
    func checkIfLocationServiceEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        }
        else {
            print("Show user alert and ask to turn on")
        }
    }
    
    func checkLocationAuthorization() {
        // sue location manager in this scope
        guard let locationManager = locationManager else { return }
        
        // check for cases
        
        switch locationManager.authorizationStatus {
        
            case .notDetermined: // Ask for permission
                locationManager.requestAlwaysAuthorization()
            case .restricted:
                print("Your locatoin suage is likely restricted due to parental control") // sometimes location restricted due to personal
            case .denied:
                print("You have denied the usage of locatoin. Please go into locations and fix")
            case .authorizedAlways, .authorizedWhenInUse:
                break
            @unknown default:
                break
        }
        
        
    }
    
    
    
}

struct ContentView: View {
    /*var body: some View {
        VStack {
            NavigationView {
                MapCardView()
            }
        }
    }*/
    @StateObject private var viewModel = MapViewModel()
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.33516, longitude: -121.891054), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
    
    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true)
            .ignoresSafeArea() // remove top and bottom white bar
    }
}

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


#Preview {
    ContentView()
}
