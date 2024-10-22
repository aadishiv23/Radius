//
//  LeaderboardView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 8/23/24.
//

import Charts
import Foundation
import SwiftUI

enum ChartType: String, CaseIterable {
    case bar = "Bar Chart"
    case line = "Line Chart"
}

struct LeaderboardView: View {
    @StateObject private var viewModel: LeaderboardViewModel
    @State private var selectedChartType: ChartType = .bar
    @State private var selectedGroup: Group?
    @State private var isSheetPresented = false

    init(friendsDataManager: FriendsDataManager, competitionManager: CompetitionManager) {
        _viewModel = StateObject(wrappedValue: LeaderboardViewModel(
            friendsDataManager: friendsDataManager,
            competitionManager: competitionManager
        ))
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.yellow.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Text("Leaderboard")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.heavy)

                    buttonsPicker
                    
                    VStack {
                        Image(systemName: "hammer")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Under Construction")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .applyRadiusGlassStyle()
                    
                    Spacer()
                }
            }
            .onAppear {
                viewModel.fetchLeaderboardData()
                Task {
                    await viewModel.friendsDataManager.fetchUserGroups()
                }
            }
            .sheet(isPresented: $isSheetPresented) {
                leaderboardDetailSheet
            }
        }
    }

    private var buttonsPicker: some View {
        HStack(spacing: 16) {
            Button(action: {
                viewModel.selectedCategory = .groups
                isSheetPresented = true
            }) {
                VStack(alignment: .leading) {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("Groups")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(15)
                .shadow(radius: 4)
                .scaleEffect(viewModel.selectedCategory == .groups ? 0.9 : 1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.4), value: viewModel.selectedCategory)
            }

            Button(action: {
                viewModel.selectedCategory = .competitions
                isSheetPresented = true
            }) {
                VStack(alignment: .leading) {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("Competitions")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(15)
                .shadow(radius: 4)
                .scaleEffect(viewModel.selectedCategory == .competitions ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.selectedCategory)
            }
        }
        .padding(.horizontal)
    }

    private var leaderboardDetailSheet: some View {
        VStack(spacing: 20) {
            if viewModel.selectedCategory == .groups {
                LVCustomGroupPicker(
                    selectedGroup: $selectedGroup,
                    groups: viewModel.friendsDataManager.userGroups
                )
                .onChange(of: selectedGroup) { newGroup in
                    viewModel.selectedGroup = newGroup
                    viewModel.fetchLeaderboardData()
                }
            } else {
                competitionPicker
            }

            Divider()

            leaderboardChart

            leaderboardList
        }
        .padding()
        .presentationDetents([.medium, .large]) // Adjusts the sheet size
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
        VStack {
            Picker("Chart Type", selection: $selectedChartType) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            if selectedChartType == .bar {
                // Bar Chart for today's points
                Chart(viewModel.members.prefix(5)) { member in
                    BarMark(
                        x: .value("Name", member.name),
                        y: .value("Points", member.points)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
                .frame(height: 200)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
            } else if selectedChartType == .line {
                // Line Chart for daily points over time
                if !viewModel.combinedDailyPoints.isEmpty {
                    Chart(viewModel.combinedDailyPoints) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Points", dataPoint.points)
                        )
                        .foregroundStyle(by: .value("Member", dataPoint.memberName))
                        .interpolationMethod(.catmullRom)
                    }
                    .chartLegend(.visible)
                    .chartXAxis {
                        AxisMarks(preset: .aligned, position: .bottom) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.month().day())
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 200)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                } else {
                    ProgressView("Loading daily points...")
                        .frame(height: 200)
                }
            }
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
        .background(Color.white)
    }

    private func medalColor(for index: Int) -> Color {
        switch index {
        case 0: .yellow // Gold
        case 1: .gray // Silver
        case 2: .brown // Bronze
        default: .clear
        }
    }
}


struct MemberDailyPoints: Identifiable {
    let id = UUID()
    let memberName: String
    let points: [DailyPoint]
}

/// Mock data structures
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

/// Mock data for groups and competitions
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

struct LVCustomGroupPicker: View {
    @Binding var selectedGroup: Group?
    let groups: [Group]

    var body: some View {
        Menu {
            ForEach(groups, id: \.id) { group in
                Button(action: {
                    selectedGroup = group
                }) {
                    HStack {
                        Text(group.name)
                        if selectedGroup == group {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(selectedGroup?.name ?? "Select a Group")
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.blue)
            }
            .padding()
            .frame(maxWidth: .infinity) // Makes the picker expand to fill the available space
            .background(Color.white.opacity(0.8))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        .padding(.horizontal)
    }
}
