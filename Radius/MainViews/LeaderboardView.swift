//
//  LeaderboardView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 8/23/24.
//

import Foundation
import SwiftUI

struct LeaderboardView: View {
    @StateObject var friendsDataManager = FriendsDataManager(supabaseClient: supabase)
    @State private var selectedGroup: Group? = nil
    @State private var members: [Profile] = []
    
    var body: some View {
        VStack {
            // Group Picker
            Picker("Select a Group", selection: $selectedGroup) {
                ForEach(friendsDataManager.userGroups, id: \.id) { group in
                    Text(group.name).tag(group as Group?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            
            // Podium for Top 3 Members
            if members.count >= 1 {
                podiumView
            }
            
            // List for 4th and Beyond
            if members.count >= 3 {
                List {
                    ForEach(0..<members.count, id: \.self) { index in
                        memberRow(member: members[index], rank: index + 1)
                    }
                }
            }
        }
        .navigationTitle("Leaderboard")
        .onAppear {
            Task {
                await friendsDataManager.fetchUserGroups()
                if let firstGroup = friendsDataManager.userGroups.first {
                    selectedGroup = firstGroup
                }
            }
        }
        .onChange(of: selectedGroup) { newGroup in
            if let group = newGroup {
                Task {
                    members = (try? await friendsDataManager.fetchGroupMembersProfiles(groupId: group.id)) ?? []
                    print("Members fetched: \(members)")  // Debug output
                }
            }
        }
    }
    
    private var podiumView: some View {
        HStack {
            // 2nd Place
            if members.count > 1 {
                podiumColumn(member: members[1], rank: 2)
                    .frame(height: 150)
            }
            
            // 1st Place
            podiumColumn(member: members[0], rank: 1)
                .frame(height: 200)
            
            // 3rd Place
            if members.count > 2 {
                podiumColumn(member: members[2], rank: 3)
                    .frame(height: 100)
            }
        }
        .padding()
    }
    
    private func podiumColumn(member: Profile, rank: Int) -> some View {
        VStack {
            Text("\(rank)")
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(Color.blue))
            
            Text(member.full_name)
                .font(.headline)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    private func memberRow(member: Profile, rank: Int) -> some View {
        HStack {
            Text("\(rank). \(member.full_name)")
                .font(.headline)
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

