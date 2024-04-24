//
//  InfoView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/24/24.
//

import Foundation
import SwiftUI
import MapKit

// InfoView that lists all friends and navigates to their detail view
struct InfoView: View {
    let friendsLocations: [FriendLocation] = [
        FriendLocation(name: "Alice", color: .red, coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)),
        FriendLocation(name: "Bob", color: .blue, coordinate: CLLocationCoordinate2D(latitude: 40.7158, longitude: -74.0080)),
        FriendLocation(name: "Charlie", color: .green, coordinate: CLLocationCoordinate2D(latitude: 40.7108, longitude: -74.0100)),
        FriendLocation(name: "David", color: .yellow, coordinate: CLLocationCoordinate2D(latitude: 40.7138, longitude: -74.0120))
    ]
    
    var body: some View {
        NavigationView {
            List(friendsLocations) { friend in
                NavigationLink(destination: FriendProfileView(friend: friend)) {
                    HStack {
                        Circle()
                            .fill(friend.color)
                            .frame(width: 30, height: 30)
                        Text(friend.name)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Friends Info")
        }
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView()
    }
}

// Define a simple profile view for displaying friend details
struct FriendProfileView: View {
    var friend: FriendLocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Name: \(friend.name)")
                .font(.title)
            Text("Coordinates: \(friend.coordinate.latitude), \(friend.coordinate.longitude)")
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .navigationTitle(friend.name)
    }
}
