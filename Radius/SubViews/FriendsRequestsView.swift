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
                FriendRequestRow(request: request) // Use custom row for each friend request
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
        .padding(.top, 50)
    }
}

// MARK: - Friend Request Row View

struct FriendRequestRow: View {
    let request: FriendRequest
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @State private var senderUsername: String? = nil // Store the requester's username

    var body: some View {
        HStack {
            // Display the sender's username (or fallback to sender_id)
            if let username = senderUsername {
                Text("Request from @\(username)")
                    .font(.headline)
            } else {
                Text("Request from \(request.sender_id)") // Fallback if username is not loaded yet
                    .font(.headline)
                    .onAppear {
                        Task {
                            await fetchSenderUsername(for: request.sender_id)
                        }
                    }
            }

            Spacer()

            // Accept Button
            Button(action: {
                Task {
                    await friendsDataManager.acceptFriendRequest(request)
                    friendsDataManager.removePendingRequest(request)
                }
            }) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 24))
            }
            .buttonStyle(PlainButtonStyle())

            // Decline Button
            Button(action: {
                Task {
                    await declineFriendRequest(request)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 24))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }

    /// Fetch the username of the sender based on sender_id
    private func fetchSenderUsername(for senderId: UUID) async {
        do {
            if let profile = try await friendsDataManager.fetchProfile(for: senderId) {
                senderUsername = profile.username
            }
        } catch {
            print("Failed to fetch sender username: \(error)")
        }
    }

    /// Decline friend request and remove it from pending list
    private func declineFriendRequest(_ request: FriendRequest) async {
        do {
            try await friendsDataManager.declineFriendRequest(request)
            friendsDataManager.removePendingRequest(request)
        } catch {
            print("Failed to decline friend request: \(error)")
        }
    }
}
