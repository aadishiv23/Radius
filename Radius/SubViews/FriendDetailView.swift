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
    @State private var buttonScale: CGFloat = 1.0

    private func makeZoneOverlay() -> [MKCircle] {
        friend.zones.map { zone in
            MKCircle(center: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude), radius: zone.radius)
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
                    MapKitView(friend: friend)
                        .ignoresSafeArea()
                        .onAppear {
                            // Additional setup if needed
                        }
                    
            
                    // VStack {
                        Spacer()
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .circularButtonStyle()
                                /*.font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())*/
                        }
                        
                        .padding()
                    //}
                }
    }
    
    private  func recenterMap() {
        withAnimation(.easeInOut(duration: 0.5)) {
            region.center = CLLocationCoordinate2D(latitude: friend.latitude, longitude: friend.longitude)
            region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            buttonScale = 0.8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring()) {
                buttonScale = 1.0
            }
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


//Map(coordinateRegion: .constant(MKCoordinateRegion(
//    center: friend.coordinate,
//    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
//)), annotationItems: [friend]) { _ in
//    MapAnnotation(coordinate: friend.coordinate) {
//        Circle()
//            .fill(friend.color)
//            .frame(width: 20, height: 20)
//    }
//}
//.ignoresSafeArea()
