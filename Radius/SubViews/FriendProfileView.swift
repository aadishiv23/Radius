//
//  FriendProfileView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/25/24.
//

import Foundation
import SwiftUI

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
//            NavigationLink(destination: ZoneEditorView()) {
//                HStack {
//                    VStack {
//                        Text("Name: \(friend.name)")
//                            .font(.title)
//                        Text("Edit")
//                            .font(.subheadline)
//                    }
//                    Spacer()
//                    Text("See More")
//                        .font(.caption)
//                }
//            }
        }
        .padding()
        .navigationTitle(friend.name)
    }
}
