//
//  HomeView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/24/24.
//

import SwiftUI
import MapKit

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
    
    var body: some View {
        ScrollView {
            VStack {
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
                
                ForEach(friendsLocations, id: \.id) { friend in
                    HStack {
                        Circle()
                            .fill(friend.color)
                            .frame(width: 15, height: 15)
                        VStack(alignment: .leading) {
                            Text(friend.name)
                                .foregroundColor(.primary)
                            Text("\(friend.coordinate.latitude), \(friend.coordinate.longitude)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .onTapGesture {
                        selectedFriend = friend
                    }
                    Divider()
                }
            }
        }
        .sheet(item: $selectedFriend) { friend in
            FriendDetailView(friend: friend)
        }
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
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(coordinateRegion: .constant(MKCoordinateRegion(
                center: friend.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )), annotationItems: [friend]) { _ in
                MapAnnotation(coordinate: friend.coordinate) {
                    Circle()
                        .fill(friend.color)
                        .frame(width: 30, height: 30)
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

