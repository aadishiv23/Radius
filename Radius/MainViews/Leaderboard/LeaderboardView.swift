//
//  LeaderboardView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 8/23/24.
//

import Charts
import Foundation
import SwiftUI

/// Enum representing the available chart types for the leaderboard visualization
enum ChartType: String, CaseIterable {
    case bar = "Bar Chart"
    case line = "Line Chart"
}

/// Main view for displaying the leaderboard interface
/// Shows competition and group data in both chart and list formats
struct LeaderboardView: View {
    // MARK: - Properties
    @StateObject private var viewModel: LeaderboardViewModel
    @State private var selectedChartType: ChartType = .bar
    @State private var selectedGroup: Group?
    @State private var isSheetPresented = false
    
    // MARK: - Initialization
    init(friendsDataManager: FriendsDataManager, competitionManager: CompetitionManager) {
        _viewModel = StateObject(wrappedValue: LeaderboardViewModel(
            friendsDataManager: friendsDataManager,
            competitionManager: competitionManager
        ))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            mainContent
        }
        .onAppear {
            viewModel.fetchLeaderboardData()
            Task {
                await viewModel.friendsDataManager.fetchUserGroups()
            }
        }
    }
    
    // MARK: - Private Views
    
    /// Main content container with gradient background
    private var mainContent: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 20) {
                titleView
                buttonsPicker
                mainScrollView
            }
        }
    }
    
    /// Background gradient for the view
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.yellow.opacity(0.7)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    /// Title view for the leaderboard
    private var titleView: some View {
        Text("Leaderboard")
            .font(.system(.body, design: .rounded))
            .fontWeight(.heavy)
    }
    
    /// Main scrollable content area
    private var mainScrollView: some View {
        ZStack {
            Rectangle()
                .cornerRadius(15, corners: [.topLeft, .topRight])
                .foregroundColor(Color.white.opacity(0.7))
                .edgesIgnoringSafeArea(.bottom)
            
            ScrollView {
                VStack(spacing: 20) {
                    Spacer()

                    if isSheetPresented {
                        categoryContentView
                        Divider()
                        leaderboardChart
                        leaderboardList
                    } else {
                        ProgressView()
                    }
                }
                .padding()
            }
        }
        .padding(.top, 10)
    }
    
    /// Content view based on selected category (groups or competitions)
    private var categoryContentView: some View {
        VStack {
            if viewModel.selectedCategory == .groups {
                groupPickerView
            } else {
                competitionPicker
            }
        }
    }
    
    /// Group picker view with selection handling
    private var groupPickerView: some View {
        LVCustomGroupPicker(
            selectedGroup: $selectedGroup,
            groups: viewModel.friendsDataManager.userGroups
        )
        .onChange(of: selectedGroup) { newGroup in
            viewModel.selectedGroup = newGroup
            viewModel.fetchLeaderboardData()
        }
    }
    
    /// Buttons for selecting between groups and competitions
    private var buttonsPicker: some View {
        HStack(spacing: 16) {
            groupButton
            competitionButton
        }
        .padding(.horizontal)
    }
    
    /// Button for selecting groups view
    private var groupButton: some View {
        Button(action: {
            viewModel.selectedCategory = .groups
            isSheetPresented = true
        }) {
            CategoryButtonContent(
                imageName: "person.2.fill",
                title: "Groups",
                isSelected: viewModel.selectedCategory == .groups
            )
        }
    }
    
    /// Button for selecting competitions view
    private var competitionButton: some View {
        Button(action: {
            viewModel.selectedCategory = .competitions
            isSheetPresented = true
        }) {
            CategoryButtonContent(
                imageName: "trophy.fill",
                title: "Competitions",
                isSelected: viewModel.selectedCategory == .competitions
            )
        }
    }
    
    /// Competition picker with available competitions
    private var competitionPicker: some View {
        Picker("Select a Competition", selection: $viewModel.selectedCompetition) {
            Text("Select a Competition").tag(nil as GroupCompetition?)
            ForEach(viewModel.competitionManager.competitions, id: \.id) { competition in
                Text(competition.competition_name).tag(competition as GroupCompetition?)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
    
    /// Chart view with type selection and data visualization
    private var leaderboardChart: some View {
        VStack {
            chartTypePicker
            selectedChartView
        }
    }
    
    /// Picker for selecting chart type (bar or line)
    private var chartTypePicker: some View {
        Picker("Chart Type", selection: $selectedChartType) {
            ForEach(ChartType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    /// View that shows either bar or line chart based on selection
    private var selectedChartView: some View {
        VStack {
            if selectedChartType == .bar {
                barChartView
            } else {
                lineChartView
            }
        }
    }
    
    /// Bar chart visualization
    private var barChartView: some View {
        VStack {
            if !viewModel.members.isEmpty {
                Chart(viewModel.members.prefix(5)) { member in
                    BarMark(
                        x: .value("Name", member.name),
                        y: .value("Points", member.points)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(8)
                }
                .chartConfiguration()
            } else {
                loadingView
            }
        }
        .chartContainer()
    }
    
    /// Line chart visualization
    private var lineChartView: some View {
        VStack {
            if !viewModel.cumulativePoints.isEmpty {
                Chart(viewModel.cumulativePoints) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Points", dataPoint.points)
                    )
                    .foregroundStyle(by: .value("Member", dataPoint.memberName))
                    .interpolationMethod(.catmullRom)
                }
                .chartLegend(.visible)
                .chartConfiguration()
            } else {
                loadingView
            }
        }
        .chartContainer()
    }
    
    /// Loading view for charts
    private var loadingView: some View {
        ProgressView()
            .padding()
    }
    
    /// List of leaderboard entries
    private var leaderboardList: some View {
        VStack(spacing: 12) {
            ForEach(Array(sortedMembers.enumerated()), id: \.element.id) { index, member in
                LeaderboardListItem(
                    index: index,
                    member: member,
                    selectedChartType: $selectedChartType,
                    getCumulativePoints: getCumulativePoints
                )
            }
        }
        //.padding(.horizontal, 8) // Reduced horizontal padding
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    
    /// Gets cumulative points for a specific member
    private func getCumulativePoints(for memberName: String) -> Int? {
        viewModel.cumulativePoints
            .filter { $0.memberName == memberName }
            .max { $0.date < $1.date }?
            .points
    }
    
    /// Returns sorted members based on chart type
    private var sortedMembers: [LeaderboardMember] {
        if selectedChartType == .bar {
            return viewModel.members
        } else {
            return viewModel.members.sorted { member1, member2 in
                let points1 = getCumulativePoints(for: member1.name) ?? 0
                let points2 = getCumulativePoints(for: member2.name) ?? 0
                return points1 > points2
            }
        }
    }
}

// MARK: - Supporting Views

/// Content view for category buttons
private struct CategoryButtonContent: View {
    let imageName: String
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: imageName)
                .font(.title2)
                .foregroundColor(.white)
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .cornerRadius(15)
        .shadow(radius: 4)
        .scaleEffect(isSelected ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isSelected)
    }
}

// MARK: - Chart Modifiers

extension View {
    /// Common chart configuration
    func chartConfiguration() -> some View {
        self
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
    }
    
    /// Common chart container styling
    func chartContainer() -> some View {
        self
            .frame(height: 300)
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
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

struct LeaderboardListItem: View {
    let index: Int
    let member: LeaderboardMember
    @Binding var selectedChartType: ChartType
    let getCumulativePoints: (String) -> Int?
    
    var body: some View {
        HStack(spacing: 16) {
            // Fixed-width section for medal/rank
            HStack {
                if index < 3 {
                    Image(systemName: "medal.fill")
                        .font(.title3)
                        .foregroundColor(medalColor(for: index))
                } else {
                    Text("\(index + 1)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 30) // Fixed width for alignment
            
            // Name and group section
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.title3)
                    .fontWeight(.bold)
                
                if let groupName = member.groupName {
                    Text(groupName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Points section
            Text("\(pointsToDisplay) pts")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.blue.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    // Computed property for points display
    private var pointsToDisplay: Int {
        selectedChartType == .bar ?
            member.points :
            (getCumulativePoints(member.name) ?? 0)
    }
    
    private func medalColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .brown
        default: return .clear
        }
    }
}


//private var tabSelector: some View {
//    HStack(spacing: 12) {
//        LeaderboardTabButton(
//            title: "Groups",
//            icon: "person.2.fill",
//            isSelected: selectedTab == .groups
//        ) {
//            withAnimation(.spring(response: 0.3)) {
//                selectedTab = .groups
//                viewModel.selectedCategory = .groups
//            }
//        }
//
//        LeaderboardTabButton(
//            title: "Competitions",
//            icon: "trophy.fill",
//            isSelected: selectedTab == .competitions
//        ) {
//            withAnimation(.spring(response: 0.3)) {
//                selectedTab = .competitions
//                viewModel.selectedCategory = .competitions
//            }
//        }
//    }
//    .padding(.horizontal)
//}
//
//struct LeaderboardTabButton: View {
//    let title: String
//    let icon: String
//    let isSelected: Bool
//    let action: () -> Void
//
//    var body: some View {
//        Button(action: action) {
//            VStack(alignment: .leading, spacing: 4) {
//                Image(systemName: icon)
//                    .font(.title2)
//                Text(title)
//                    .font(.headline)
//            }
//            .frame(maxWidth: .infinity)
//            .padding()
//            .background(
//                RoundedRectangle(cornerRadius: 15, style: .continuous)
//                    .fill(isSelected ? .white.opacity(0.3) : .blue)
//            )
//            .foregroundStyle(.white)
//            .shadow(radius: 4)
//            .scaleEffect(isSelected ? 0.95 : 1)
//            .animation(.spring(response: 0.3), value: isSelected)
//        }
//    }
//}
//
//
