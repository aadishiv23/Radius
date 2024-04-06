//
//  MapView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/5/24.
//

import SwiftUI
import MapKit

struct ContentView: View {
    var body: some View {
        VStack {
            NavigationView {
                MapCardView()
            }
            
            /*List {
                HStack {
                    Image(systemName: "person")
                    Text("Person 1")
                    
                    Spacer()
                    
                    Text("1")
                }
                
                HStack {
                    Image(systemName: "person")
                    Text("Person 2")
                    
                    Spacer()
                    
                    Text("2")
                }
                
                HStack {
                    Image(systemName: "person")
                    Text("Person 3")
                    
                    Spacer()
                    
                    Text("3")
                }
            }*/
        }
    }
    /*@State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.33516, longitude: -121.891054), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
    
    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true)
            .ignoresSafeArea() // remove top and bottom white bar
    }*/
}

struct MapCardView: View {
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
}


#Preview {
    ContentView()
}
