//
//  FullScreenMapView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/25/24.
//
import SwiftUI
import MapKit

struct FullScreenMapView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: friendsDataManager.friends.filter { $0.id != friendsDataManager.currentUser?.id } ) { friend in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: friend.latitude, longitude: friend.longitude)) {
                    FriendAnnotationView(friend: friend)
                }
            }
            .ignoresSafeArea()
            .onAppear {
                if let location = locationManager.userLocation?.coordinate {
                    region.center = location

                } else {
                    // Fallback to a default location if userLocation is not available
                    region.center = CLLocationCoordinate2D(latitude: 42.278378215221565, longitude: -83.74388859636869)
                }
            }

            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .padding()
        }
    }
}

struct FriendAnnotationView: View {
    let friend: Profile

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 40, height: 40)
            
            Circle()
                .fill(Color.gray)
                .frame(width: 34, height: 34)
            
            Text(String(friend.full_name.prefix(1)))
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .bold))
        }
        .shadow(radius: 3)
    }
}


/*
 import SwiftUI
 import MapKit

 struct FullScreenMapView: View {
     @EnvironmentObject var friendsDataManager: FriendsDataManager
     @Environment(\.dismiss) private var dismiss
     @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)

     var body: some View {
         ZStack(alignment: .topTrailing) {
             Map(position: $position) {
                 UserAnnotation()
                 ForEach(friendsDataManager.friends) { friend in
                     Annotation(
                         coordinate: CLLocationCoordinate2D(latitude: friend.latitude, longitude: friend.longitude),
                         content: {
                             FriendAnnotationView(friend: friend)
                         },
                         label: {
                             Text(friend.full_name)
                         }
                     )
                 }
             }
             .mapControls {
                 MapUserLocationButton()
                 MapCompass()
                 MapScaleView()
             }
             .ignoresSafeArea()

             Button(action: {
                 dismiss()
             }) {
                 Image(systemName: "xmark")
                     .foregroundColor(.primary)
                     .padding()
                     .background(Color(.systemBackground))
                     .clipShape(Circle())
                     .shadow(radius: 2)
             }
             .padding()
         }
     }
 }

 struct FriendAnnotationView: View {
     let friend: Profile

     var body: some View {
         ZStack {
             Circle()
                 .fill(Color.white)
                 .frame(width: 40, height: 40)
             
             Circle()
                 .fill(Color.gray)
                 .frame(width: 34, height: 34)
             
             Text(String(friend.full_name.prefix(1)))
                 .foregroundColor(.white)
                 .font(.system(size: 20, weight: .bold))
         }
         .shadow(radius: 3)
     }
 }
 
 */
