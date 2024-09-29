//
//  LeaderboardView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 8/23/24.
//

import Charts
import Foundation
import SwiftUI

import Charts
import SwiftUI

struct LeaderboardView: View {
    @StateObject private var viewModel: LeaderboardViewModel

    init(friendsDataManager: FriendsDataManager, competitionManager: CompetitionManager) {
        _viewModel = StateObject(wrappedValue: LeaderboardViewModel(friendsDataManager: friendsDataManager, competitionManager: competitionManager))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Segmented Picker
                Picker("Category", selection: $viewModel.selectedCategory) {
                    ForEach(LeaderboardCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // Dropdown for Group/Competition selection
                if viewModel.selectedCategory == .groups {
                    groupPicker
                } else {
                    competitionPicker
                }

                // Chart
                leaderboardChart
                    .frame(height: 200)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)

                // Leaderboard List
                leaderboardList
            }
        }
        .navigationTitle("Leaderboard")
        .onAppear {
            viewModel.fetchLeaderboardData()
            Task {
                await viewModel.friendsDataManager.fetchUserGroups()  // Fetch user groups directly
            }
        }
    }

    private var groupPicker: some View {
        Picker("Select a Group", selection: $viewModel.selectedGroup) {
            Text("Select a Group").tag(nil as Group?)
            ForEach(viewModel.friendsDataManager.userGroups, id: \.id) { group in
                Text(group.name).tag(group as Group?)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .onChange(of: viewModel.selectedGroup) { newGroup in
            if let group = newGroup {
                viewModel.fetchLeaderboardData()  // Ensure fetching happens immediately after selection
            }
        }
    }

    private var competitionPicker: some View {
        Picker("Select a Competition", selection: $viewModel.selectedCompetition) {
            Text("Select a Competition").tag(nil as GroupCompetition?)
            ForEach(viewModel.competitionManager.competitions, id: \.id) { competition in
                Text(competition.competition_name).tag(competition as GroupCompetition?)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .onAppear {
                print("Competitions: \(viewModel.competitionManager.competitions)")
            }
    }

    private var leaderboardChart: some View {
        Chart(viewModel.members.prefix(5)) { member in
            BarMark(
                x: .value("Name", member.name),
                y: .value("Points", member.points)
            )
            .foregroundStyle(Color.blue.gradient)
        }
    }

    private var leaderboardList: some View {
        List {
            ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                HStack {
                    Text("\(index + 1)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(width: 30)

                    if index < 3 {
                        Image(systemName: "medal.fill")
                            .foregroundColor(medalColor(for: index))
                    }

                    VStack(alignment: .leading) {
                        Text(member.name)
                            .font(.headline)
                        if viewModel.selectedCategory == .competitions {
                            Text(member.groupName ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Text("\(member.points) pts")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
            }
        }
    }

    private func medalColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow // Gold
        case 1: return .gray // Silver
        case 2: return .brown // Bronze
        default: return .clear
        }
    }
}

// extension LeaderboardView {
//    private func fetchLeaderboardData() async {
//        do {
//            switch selectedCategory {
//            case .groups:
//                if let group = selectedGroup {
//                    let profiles = try await friendsDataManager.fetchGroupMembersProfiles(groupId: group.id)
//                    members = profiles.map { profile in
//                        // Fetch daily points for each profile
//                        let points = try await competitionManager.fetchDailyPoints(for: profile.id, groupId: group.id)
//                        return LeaderboardMember(id: profile.id, name: profile.full_name, points: points)
//                    }
//                }
//            case .competitions:
//                if let competition = selectedCompetition {
//                    let groupCompetitors = try await competitionManager.fetchCompetitors(for: competition.id)
//                    members = groupCompetitors.map { competitor in
//                        let points = try await competitionManager.fetchCompetitionPoints(for: competitor.profile_id, competitionId: competition.id)
//                        return LeaderboardMember(id: competitor.profile_id, name: competitor.name, groupName: competitor.group_name, points: points)
//                    }
//                }
//            }
//            members.sort { $0.points > $1.points }
//        } catch {
//            print("Failed to fetch leaderboard data: \(error)")
//        }
//    }
//
// }

// Mock data structures
struct MockGroup: Identifiable, Hashable {
    let id: UUID
    let name: String
}

struct MockGroupCompetition: Identifiable, Hashable {
    let id: UUID
    let competition_name: String
}

struct LeaderboardMember: Identifiable, Hashable {
    let id: UUID
    let name: String
    var groupName: String?
    let points: Int
}

// Mock data for groups and competitions
let mockGroups: [MockGroup] = [
    MockGroup(id: UUID(), name: "Group 1"),
    MockGroup(id: UUID(), name: "Group 2"),
    MockGroup(id: UUID(), name: "Group 3")
]

let mockCompetitions: [MockGroupCompetition] = [
    MockGroupCompetition(id: UUID(), competition_name: "Competition 1"),
    MockGroupCompetition(id: UUID(), competition_name: "Competition 2"),
    MockGroupCompetition(id: UUID(), competition_name: "Competition 3")
]

// Preview
// struct LeaderboardView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            LeaderboardView()
//        }
//    }
// }

// struct LeaderboardView: View {
//    @StateObject var friendsDataManager = FriendsDataManager(supabaseClient: supabase)
//    @State private var selectedGroup: Group? = nil
//    @State private var members: [Profile] = []
//
//    var body: some View {
//        VStack {
//            // Group Picker
//            Picker("Select a Group", selection: $selectedGroup) {
//                ForEach(friendsDataManager.userGroups, id: \.id) { group in
//                    Text(group.name).tag(group as Group?)
//                }
//            }
//            .pickerStyle(MenuPickerStyle())
//            .padding()
//
//            // Podium for Top 3 Members
//            if members.count >= 1 {
//                podiumView
//            }
//
//            // List for 4th and Beyond
//            if members.count >= 3 {
//                List {
//                    ForEach(0..<members.count, id: \.self) { index in
//                        memberRow(member: members[index], rank: index + 1)
//                    }
//                }
//            }
//        }
//        .navigationTitle("Leaderboard")
//        .onAppear {
//            Task {
//                await friendsDataManager.fetchUserGroups()
//                if let firstGroup = friendsDataManager.userGroups.first {
//                    selectedGroup = firstGroup
//                }
//            }
//        }
//        .onChange(of: selectedGroup) { newGroup in
//            if let group = newGroup {
//                Task {
//                    members = (try? await friendsDataManager.fetchGroupMembersProfiles(groupId: group.id)) ?? []
//                    print("Members fetched: \(members)")  // Debug output
//                }
//            }
//        }
//    }
//
//    private var podiumView: some View {
//        HStack {
//            // 2nd Place
//            if members.count > 1 {
//                podiumColumn(member: members[1], rank: 2)
//                    .frame(height: 150)
//            }
//
//            // 1st Place
//            podiumColumn(member: members[0], rank: 1)
//                .frame(height: 200)
//
//            // 3rd Place
//            if members.count > 2 {
//                podiumColumn(member: members[2], rank: 3)
//                    .frame(height: 100)
//            }
//        }
//        .padding()
//    }
//
//    private func podiumColumn(member: Profile, rank: Int) -> some View {
//        VStack {
//            Text("\(rank)")
//                .font(.title)
//                .foregroundColor(.white)
//                .frame(width: 50, height: 50)
//                .background(Circle().fill(Color.blue))
//
//            Text(member.full_name)
//                .font(.headline)
//                .padding(.top, 8)
//        }
//        .frame(maxWidth: .infinity)
//        .background(Color.gray.opacity(0.2))
//        .cornerRadius(12)
//    }
//
//    private func memberRow(member: Profile, rank: Int) -> some View {
//        HStack {
//            Text("\(rank). \(member.full_name)")
//                .font(.headline)
//            Spacer()
//        }
//        .padding(.vertical, 8)
//    }
// }
