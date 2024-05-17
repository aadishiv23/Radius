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
    var friend: Profile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Name: \(friend.full_name)")
                .font(.title)
            Text("Coordinates: \(friend.latitude), \(friend.longitude)")
                .font(.subheadline)
            Spacer()
//            if friend.name == "user" {
//                ZoneEditorView(isPresenting: , userZones: <#T##Binding<[Zone]>#>)
//            }
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
        .navigationTitle(friend.full_name)
    }
}
