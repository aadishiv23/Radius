//
//  FriendDetailView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/25/24.
//

import Foundation
import SwiftUI
import MapKit

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

//
//struct FriendDetailView: View {
//    var friend: FriendLocation
//    @EnvironmentObject var friendData: FriendData
//    @Environment(\.presentationMode) var presentationMode
//    @State private var region: MKCoordinateRegion
//    @State private var showingZoneEditor = false
//    @State private var newZoneRadius: Double = 100.0  // Default radius value for new zones
//
//    init(friend: FriendLocation) {
//        self.friend = friend
//        _region = State(initialValue: MKCoordinateRegion(
//            center: friend.coordinate,
//            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
//        ))
//    }
//
//    var body: some View {
//        ZStack {
//            Map(coordinateRegion: $region, annotationItems: [friend]) { friendLocation in
//                MapAnnotation(coordinate: friendLocation.coordinate) {
//                    VStack {
//                        Circle()
//                            .fill(friendLocation.color)
//                            .frame(width: 20, height: 20)
//                        ForEach(friendLocation.zones) { zone in
//                            Circle()
//                                .stroke(Color.blue.opacity(0.5), lineWidth: 2)
//                                .frame(width: zone.radius * 2, height: zone.radius * 2) // Displaying the zone
//                        }
//                    }
//                }
//            }
//            .ignoresSafeArea()
//
//            VStack {
//                Spacer()
//                Button(action: {
//                    showingZoneEditor.toggle()
//                }) {
//                    Text(showingZoneEditor ? "Done" : "Edit Zones")
//                        .foregroundColor(.white)
//                        .padding()
//                        .background(Color.blue)
//                        .clipShape(RoundedRectangle(cornerRadius: 10))
//                }
//                .padding()
//            }
//
//            if showingZoneEditor {
//                VStack {
//                    Slider(value: $newZoneRadius, in: 50...500, step: 10)
//                        .padding()
//                    Button("Add Zone") {
//                        let newZone = Zone(coordinate: friend.coordinate, radius: newZoneRadius)
//                        if let index = friendData.friendsLocations.firstIndex(where: { $0.id == friend.id }) {
//                            friendData.friendsLocations[index].zones.append(newZone)
//                        }
//                        showingZoneEditor = false
//                    }
//                    Button("Cancel") {
//                        showingZoneEditor = false
//                    }
//                }
//                .padding()
//                .background(Color.white)
//                .cornerRadius(10)
//                .shadow(radius: 5)
//            }
//        }
//        .navigationBarItems(trailing: Button("Close") {
//            presentationMode.wrappedValue.dismiss()
//        })
//    }
//}

