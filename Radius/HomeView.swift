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
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var selectedFriend: FriendLocation?
    
    let friendsLocations: [FriendLocation] = [
        FriendLocation(name: "Alice", color: .red, coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)),
        FriendLocation(name: "Bob", color: .blue, coordinate: CLLocationCoordinate2D(latitude: 40.7158, longitude: -74.0080)),
        FriendLocation(name: "Charlie", color: .green, coordinate: CLLocationCoordinate2D(latitude: 40.7108, longitude: -74.0100)),
        FriendLocation(name: "David", color: .yellow, coordinate: CLLocationCoordinate2D(latitude: 40.7138, longitude: -74.0120))
    ]
    
    @State private var showRecenterButton = false
    private let initialCenter = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    private var checkDistanceTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
                        Map(coordinateRegion: $region, annotationItems: friendsLocations) { friendLocation in
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
                        .onReceive(checkDistanceTimer) { _ in
                            checkDistance()
                        }
                        
                        if showRecenterButton {
                            Button(action: {
                                region.center = initialCenter
                                region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                showRecenterButton = false
                            }) {
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

                    Divider()
                    
                    ForEach(friendsLocations, id: \.id) { friend in
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
                        Divider() // Optional: Add a divider between each friend in the list
                    }
                }
            }
            .navigationTitle("Home")
            .sheet(item: $selectedFriend) { friend in
                FriendDetailView(friend: friend)
            }
        }
    }

    private func checkDistance() {
        let currentLocation = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        let initialLocation = CLLocation(latitude: initialCenter.latitude, longitude: initialCenter.longitude)
        let distance = currentLocation.distance(from: initialLocation)
        showRecenterButton = distance > 500
    }
}

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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

