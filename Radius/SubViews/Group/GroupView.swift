//
//  GroupView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/11/24.
//

import Foundation
import SwiftUI

struct GroupView: View {
    var group: Group
    @State private var isCopied = false // Track when the password has been copied

    var body: some View {
        NavigationLink(destination: GroupDetailView(group: group)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    Text(group.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Password")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(group.plain_password ?? "N/A")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    Spacer()

                    Button(action: {
                        UIPasteboard.general.string = group.plain_password
                        showCopiedStatus() // Show "Copied!" when the password is copied
                    }) {
                        Text(isCopied ? "Copied!" : "Copy Password")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isCopied ? Color.green : Color.blue)
                            .cornerRadius(8)
                    }
                }

                HStack {
                    Text(group.description ?? "No description available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .blueCardStyle()
        }
    }

    // MARK: - Function to Show Copied Status

    private func showCopiedStatus() {
        isCopied = true

        // Automatically reset the button after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isCopied = false
        }
    }
}

struct GroupDetailView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    var group: Group
    @State private var groupMembers: [Profile] = []
    @State private var isLoading: Bool = true

    var body: some View {
        VStack(spacing: 20) {
            groupInfoSection // Displays group details and number of members

            List {
                if isLoading {
                    ProgressView("Loading...")
                } else if groupMembers.isEmpty {
                    Text("No members found")
                        .foregroundColor(.secondary)
                } else {
                    groupMembersList
                }
            }
        }
        .navigationTitle(group.name)
        .onAppear {
            fetchGroupMembers()
        }
    }

    // MARK: - Group Info Section

    private var groupInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Group Name: \(group.name)")
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                VStack(alignment: .leading) {
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(group.plain_password ?? "N/A")
                        .font(.headline)
                }
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = group.plain_password
                }) {
                    Text("Copy Password")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }

            Text("Description: \(group.description ?? "No description available")")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Number of People: \(groupMembers.count)")
                .font(.headline)
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
    }

    // MARK: - Group Members List

    @ViewBuilder private var groupMembersList: some View {
        ForEach(groupMembers, id: \.id) { member in
            NavigationLink(destination: FriendProfileView(friend: member)) {
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 30, height: 30)
                    Text(member.full_name)
                        .foregroundColor(.primary)
                }
            }
        }
    }

    // MARK: - Fetch Group Members

    private func fetchGroupMembers() {
        Task {
            do {
                groupMembers = try await friendsDataManager.fetchGroupMembersProfiles(groupId: group.id)
                isLoading = false
            } catch {
                print("Error fetching group members: \(error)")
                isLoading = false
            }
        }
    }
}

extension GroupDetailView {
    @MainActor
    final class ViewModel: ObservableObject {
        
    }
}
