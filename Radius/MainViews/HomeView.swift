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
    @EnvironmentObject var friendsDataManager: FriendsDataManager  // Assuming this contains your friendsLocations
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var locationViewModel = LocationViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var selectedFriend: FriendLocation?
    @State private var showRecenterButton = false
    @State private var showFullScreenMap = false
    @State private var buttonScale: CGFloat = 1.0
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
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    
                }, label: {
                    Image(systemName: "plus")
                })
            }
        })
        .onAppear {
            locationViewModel.checkIfLocationServicesIsEnabled()
            locationViewModel.plsInitiateLocationUpdates()
            for friendsLocation in friendsDataManager.friends {
                print(friendsLocation.name)
            }
        }
    }
    
    private var mapSection: some View {
        ZStack(alignment: .top/*Alignment(horizontal: .leading, vertical: .top)*/) {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: friendsDataManager.friends) { friendLocation in
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
                if showRecenterButton {
                    Button(action: recenterMap) {
                        Image(systemName: "arrow.circlepath")
                            .circularButtonStyle()
                            .scaleEffect(buttonScale)
                            .animation(.easeInOut(duration: 0.5), value: buttonScale)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                }
               
                
                Spacer()
                
                Button(action: {
                    showFullScreenMap.toggle()
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .circularButtonStyle()
                }
                .padding(.trailing, 20)
                .padding(.top, 20)
            }
        }
        .sheet(isPresented: $showFullScreenMap) {
            // Present the FullScreenMapView here
            FullScreenMapView(region: $region, selectedFriend: $selectedFriend)
                    .environmentObject(friendsDataManager)
        }
    }
    
    private var friendListSection: some View {
        VStack {  // This will also ensure all paths return a consistent type
            ForEach(friendsDataManager.friends, id: \.id) { friend in
                friendRow(friend)
            }
            if let userLocation = locationViewModel.userLocation {
                friendRow(FriendLocation(name: "You", color: .purple, coordinate: CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude), zones: []))
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
        .background(colorScheme == .dark ? .black : .white)
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








struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

