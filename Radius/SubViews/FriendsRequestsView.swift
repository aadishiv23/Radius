//
//  File.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 8/20/24.
//

import Foundation
import SwiftUI

struct FriendRequestsView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @State private var newFriendUsername = ""
    
    var body: some View {
        VStack {
            Text("Friend Requests")
                .font(.title)
                .padding()
            
            List(friendsDataManager.pendingRequests) { request in
                HStack {
                    Text("Request from \(request.sender_id)")
                    Spacer()
                    Button("Accept") {
                        Task {
                            await friendsDataManager.acceptFriendRequest(request)
                        }
                    }
                }
            }
            
            Divider()
            
            TextField("Enter Username", text: $newFriendUsername)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .padding()
            
            Button("Send Request") {
                Task {
                    try await friendsDataManager.sendFriendRequest(to: newFriendUsername)
                }
            }
            .padding()
        }
        .onAppear {
            Task {
                await friendsDataManager.fetchPendingFriendRequests()
            }
        }
    }
}
