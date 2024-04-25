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
    @EnvironmentObject var friendData: FriendData  // Access the shared data
    
    var body: some View {
        NavigationView {
            List(friendData.friendsLocations) { friend in
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

