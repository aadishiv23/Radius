//
//  FullScreenMapView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/25/24.
//

import Foundation
import SwiftUI
import MapKit


struct FullScreenMapView: View {
    @Binding var region: MKCoordinateRegion
    @EnvironmentObject var friendDataManager: FriendsDataManager
    @Binding var selectedFriend: Profile?

    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: friendDataManager.friends) { friendLocation in
            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: friendLocation.latitude, longitude: friendLocation.longitude)) {
                Circle()
                    .fill(Color(friendLocation.color))
                    .frame(width: 20, height: 20)
                    .onTapGesture {
                        selectedFriend = friendLocation
                    }
            }
        }
        .ignoresSafeArea()
    }
}
