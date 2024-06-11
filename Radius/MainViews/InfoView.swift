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
    @EnvironmentObject var friendsDataManager: FriendsDataManager  // Access the shared data
    @State private var isPresentingCreateGroupView = false
    @State private var isPresentingJoinGroupView = false
    
    var body: some View {
        NavigationView {
            List(friendsDataManager.friends) { friend in
                NavigationLink(destination: FriendProfileView(friend: friend)) {
                    HStack {
                        Circle()
                            .fill(Color(friend.color))
                            .frame(width: 30, height: 30)
                        Text(friend.full_name)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Friends Info")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            // Navigate to Create Group View
                            isPresentingCreateGroupView = true
                        }) {
                            Label("Create Group", systemImage: "person.3.fill")
                        }
                        Button(action: {
                            // Navigate to Join Group View
                            isPresentingJoinGroupView = true
                        }) {
                            Label("Join Group", systemImage: "person.crop.circle.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $isPresentingCreateGroupView) {
                CreateGroupView(isPresented: $isPresentingCreateGroupView).environmentObject(friendsDataManager)
            }
            .fullScreenCover(isPresented: $isPresentingJoinGroupView) {
                JoinGroupView(isPresented: $isPresentingJoinGroupView).environmentObject(friendsDataManager)
            }
        }
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView()
    }
}

