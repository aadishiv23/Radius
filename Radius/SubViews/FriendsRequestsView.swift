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
    @State private var showConfirmation = false
    @State private var confirmationMessage = ""
    
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
                    do {
                        try await friendsDataManager.sendFriendRequest(to: newFriendUsername)
                        showConfirmationMessage(for: newFriendUsername)
                    } catch {
                        // Handle any errors, such as failed request sending
                        print("Failed to send friend request: \(error)")
                    }
                }
            }
            .padding()
            
            if showConfirmation {
                confirmationPopup
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showConfirmation)
            }
        }
        .onAppear {
            Task {
                await friendsDataManager.fetchPendingFriendRequests()
            }
        }
    }
    
    private func showConfirmationMessage(for username: String) {
        confirmationMessage = "Friend request sent to @\(username)"
        showConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showConfirmation = false
            }
        }
    }
    
    private var confirmationPopup: some View {
        HStack {
            Image(systemName: "paperplane.circle.fill")
                .foregroundColor(.white)
            Text(confirmationMessage)
                .foregroundColor(.white)
                .bold()
        }
        .padding()
        .background(Color.green)
        .clipShape(Capsule())
        .padding(.top, 50)  // Adjust the padding to position the popup correctly
    }
}
