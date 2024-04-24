//
//  HomeView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/24/24.
//

import SwiftUI
import MapKit
import Combine

struct HomeView: View {
    @EnvironmentObject var friendData: FriendData  // Assuming this contains your friendsLocations
    @StateObject private var locationViewModel = LocationViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var selectedFriend: FriendLocation?
    @State private var showRecenterButton = false
    @State private var showFullScreenMap = false
    private let initialCenter = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    private var checkDistanceTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
//    @StateObject private var mapRegionObserver: MapRegionObserver
//
//    init() {
//        _mapRegionObserver = StateObject(wrappedValue: MapRegionObserver(initialCenter: initialCenter))
//    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    mapSection
                    Divider()
                    friendListSection
                }
            }
            .navigationTitle("Home")
            .sheet(item: $selectedFriend) { friend in
                FriendDetailView(friend: friend)
            }
            .onReceive(checkDistanceTimer) { _ in
                checkDistance()
            }
        }
        .onAppear {
            locationViewModel.checkIfLocationServicesIsEnabled()
            locationViewModel.plsInitiateLocationUpdates()
        }
    }
    
    private var mapSection: some View {
        ZStack(alignment: .top/*Alignment(horizontal: .leading, vertical: .top)*/) {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: friendData.friendsLocations) { friendLocation in
                MapAnnotation(coordinate: friendLocation.coordinate) {
                    Circle()
                        .fill(friendLocation.color)
                        .frame(width: 20, height: 20)
                        .onTapGesture {
                            selectedFriend = friendLocation
                        }
                }
            }
            .frame(height: 300)
            .cornerRadius(15)
            .padding()
            .background(Color.gray.opacity(0.2))
            
            HStack {
                Button(action: {
                    showFullScreenMap.toggle()
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .padding()
                        .background(Color.white.opacity(0.7))
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
                .padding(.leading, 20)
                .padding(.top, 20)
                
                Spacer()
                
                if showRecenterButton {
                    Button(action: recenterMap) {
                        Image(systemName: "arrow.circlepath")
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
            }
        }
        .sheet(isPresented: $showFullScreenMap) {
            // Present the FullScreenMapView here
            FullScreenMapView(region: $region, selectedFriend: $selectedFriend)
                    .environmentObject(friendData)
        }
    }
    
    private var friendListSection: some View {
        VStack {  // This will also ensure all paths return a consistent type
            ForEach(friendData.friendsLocations, id: \.id) { friend in
                friendRow(friend)
            }
            if let userLocation = locationViewModel.userLocation {
                friendRow(FriendLocation(name: "You", color: .purple, coordinate: CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)))
            }
        }
    }
    
    @ViewBuilder
    func friendRow(_ friend: FriendLocation) -> some View {
        HStack {
            Circle()
                .fill(friend.color)
                .frame(width: 30, height: 30)
            VStack(alignment: .leading) {
                Text(friend.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("\(friend.coordinate.latitude), \(friend.coordinate.longitude)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.horizontal)
        .padding(.vertical, 4)
        .onTapGesture {
            selectedFriend = friend
        }
    }
    
    private func checkDistance() {
        let currentLocation = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        let initialLocation = CLLocation(latitude: initialCenter.latitude, longitude: initialCenter.longitude)
        let distance = currentLocation.distance(from: initialLocation)
        showRecenterButton = distance > 500
    }
    
    private func recenterMap() {
        region.center = initialCenter
        region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        showRecenterButton = false
    }
}

//private func checkDistance() {
//    let currentLocation = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
//    let initialLocation = CLLocation(latitude: initialCenter.latitude, longitude: initialCenter.longitude)
//    let distance = currentLocation.distance(from: initialLocation)
//    showRecenterButton = distance > 500
//}
//}

//
//struct ContentView: View {
//    @State private var region = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
//        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
//    )
//
//    @State private var selectedFriend: FriendLocation?
//
//    let friendsLocations: [FriendLocation] = [
//        FriendLocation(name: "Alice", color: .red, coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)),
//        FriendLocation(name: "Bob", color: .blue, coordinate: CLLocationCoordinate2D(latitude: 40.7158, longitude: -74.0080)),
//        FriendLocation(name: "Charlie", color: .green, coordinate: CLLocationCoordinate2D(latitude: 40.7108, longitude: -74.0100)),
//        FriendLocation(name: "David", color: .yellow, coordinate: CLLocationCoordinate2D(latitude: 40.7138, longitude: -74.0120))
//    ]
//
//    var body: some View {
//        VStack {
//            Map(coordinateRegion: $region, annotationItems: friendsLocations) { friendLocation in
//                MapAnnotation(coordinate: friendLocation.coordinate) {
//                    Circle()
//                        .fill(friendLocation.color)
//                        .frame(width: 20, height: 20)
//                        .onTapGesture {
//                            selectedFriend = friendLocation
//                        }
//                }
//            }
//            .frame(height: 300)
//            .cornerRadius(15)
//            .padding()
//
//            List(friendsLocations, id: \.id) { friend in
//                HStack {
//                    Circle()
//                        .fill(friend.color)
//                        .frame(width: 15, height: 15)
//                    VStack(alignment: .leading) {
//                        Text(friend.name)
//                            .foregroundColor(.primary)
//                        Text("\(friend.coordinate.latitude), \(friend.coordinate.longitude)")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    }
//                }
//                .padding(.vertical, 4)
//                .onTapGesture {
//                    selectedFriend = friend
//                }
//            }
//        }
//        .sheet(item: $selectedFriend) { friend in
//            FriendDetailView(friend: friend)
//        }
//    }
//}

struct FriendLocation: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let coordinate: CLLocationCoordinate2D
}



struct FriendDetailView: View {
    var friend: FriendLocation
    @Environment(\.presentationMode) var presentationMode
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(coordinateRegion: .constant(MKCoordinateRegion(
                center: friend.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )), annotationItems: [friend]) { _ in
                MapAnnotation(coordinate: friend.coordinate) {
                    Circle()
                        .fill(friend.color)
                        .frame(width: 20, height: 20)
                }
            }
            .ignoresSafeArea()
            
            
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.black)
            }
            .padding()
        }
    }
}

struct FullScreenMapView: View {
    @Binding var region: MKCoordinateRegion
    @EnvironmentObject var friendData: FriendData
    @Binding var selectedFriend: FriendLocation?

    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: friendData.friendsLocations) { friendLocation in
            MapAnnotation(coordinate: friendLocation.coordinate) {
                Circle()
                    .fill(friendLocation.color)
                    .frame(width: 20, height: 20)
                    .onTapGesture {
                        selectedFriend = friendLocation
                    }
            }
        }
        .ignoresSafeArea()
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
