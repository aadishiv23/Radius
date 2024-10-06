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

    init(friendsDataManager: FriendsDataManager, competitionManager: CompetitionManager) {
        _viewModel = StateObject(wrappedValue: LeaderboardViewModel(
            friendsDataManager: friendsDataManager,
            competitionManager: competitionManager
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Segmented Picker for Category
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

                // Charts (Bar and Line)
                leaderboardChart

                // Leaderboard List
                leaderboardList
            }
            .navigationTitle("Leaderboard")
            .onAppear {
                viewModel.fetchLeaderboardData()
                Task {
                    await viewModel.friendsDataManager.fetchUserGroups()
                }
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
            if let _ = newGroup {
                viewModel.fetchLeaderboardData() // Ensure fetching happens immediately after selection
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
                        .interpolationMethod(.catmullRom) // Smooth lines
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
