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
    
    var body: some View {
        NavigationLink(destination: GroupDetailView(group: group)) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.white)
                    .padding()
                Text(group.name)
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.green.opacity(0.3)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(10)
            .shadow(radius: 5)
        }
        .padding(.horizontal)
    }
}

struct GroupDetailView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    var group: Group
    @State private var groupMembers: [Profile] = []
    @State private var isLoading: Bool = true
    
    var body: some View {
        mainContent
            .navigationTitle(group.name)
            .onAppear {
                fetchGroupMembers()
            }
    }
    
    @ViewBuilder private var mainContent: some View {
        List {
            if isLoading {
                ProgressView("Loading...")
            } else if groupMembers.isEmpty {
                Text("No members found")
                    .foregroundColor(.secondary)
            } else {
                existingGroupMemberView
            }
        }
    }
    
    @ViewBuilder private var existingGroupMemberView: some View {
        groupMembersList
    }
    
    @ViewBuilder private var groupMembersList: some View {
        ForEach(groupMembers, id: \.id) { member in
            NavigationLink(destination: FriendProfileView(friend: member)) {
                HStack {
                    Circle()
                        .fill(Color.blue)  // Assuming 'color' is a string property in Profile
                        .frame(width: 30, height: 30)
                    Text(member.full_name)
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
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
