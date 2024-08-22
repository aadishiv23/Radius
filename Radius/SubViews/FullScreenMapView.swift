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
    @Binding var isPresented: Bool  // Binding to control sheet presentation

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: friendDataManager.friends) { friendLocation in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: friendLocation.latitude, longitude: friendLocation.longitude)) {
                    Circle()
                        .fill(Color(hex: friendLocation.color) ?? .blue)
                        .frame(width: 20, height: 20)
                        .onTapGesture {
                            DispatchQueue.main.async {
                                selectedFriend = friendLocation
                            }
                        }
                }
            }
            .ignoresSafeArea()

            Button(action: {
                isPresented = false  // Dismiss the sheet
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .padding()
            .zIndex(1)  // Ensure the button is on top
        }
    }
}
