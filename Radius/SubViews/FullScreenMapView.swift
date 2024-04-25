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
