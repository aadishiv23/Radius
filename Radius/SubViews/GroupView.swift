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
            HStack() {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(group.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    ProgressView(value: Double(10), total: 100) // Example progress
                        .progressViewStyle(LinearProgressViewStyle(tint: .white.opacity(0.7)))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.4)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
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
