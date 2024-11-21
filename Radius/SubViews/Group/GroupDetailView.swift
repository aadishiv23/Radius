//
//  GroupDetailView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 11/7/24.
//

import Foundation
import SwiftUI

struct GroupDetailView: View {
    @StateObject private var viewModel: ViewModel
    var group: Group

    // State for tabs
    @State private var selectedTab = 0
    @State private var isShowingGroupRules = false

    // State for rules
    @State private var countZoneExit = false
    @State private var maxExitsAllowed = 1
    @State private var selectedCategories: Set<ZoneCategory> = []
    @State private var areRulesExpanded = false

    init(group: Group) {
        self.group = group
        _viewModel = StateObject(wrappedValue: ViewModel(group: group, groupsRepository: GroupsRepository.shared))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Card
                headerCard

                // Tab Picker
                Picker("View", selection: $selectedTab) {
                    Text("Members").tag(0)
                    Text("Rules").tag(1)
                    Text("Settings").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Tab Content
                tabContent
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.automatic)
        .onAppear {
            viewModel.fetchGroupMembers()
            viewModel.fetchCurrentRules()
        }
        .sheet(isPresented: $isShowingGroupRules) {
            GroupRulesSheet(group: group)
        }
        .onChange(of: viewModel.currentRules) { rules in
            if let rules {
                // Update form with existing rules
                countZoneExit = rules.count_zone_exits
                maxExitsAllowed = rules.max_exits_allowed
                selectedCategories = Set(rules.allowed_zone_categories)
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Password Row
            VStack(alignment: .leading) {
                Text("Password:")
                    .font(.system(.headline, design: .rounded))
                HStack {
                    Text(group.plain_password ?? "N/A")
                        .font(.system(.body, design: .rounded))
                    Spacer()
                    VStack {
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = group.plain_password
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }

                if let description = group.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Divider()

            // Group Stats Row
            HStack(spacing: 16) {
                statItem(count: viewModel.groupMembers.count, title: "Members")
                Divider().frame(height: 40)
                statItem(count: selectedCategories.count, title: "Zones")
                Divider().frame(height: 40)
                statItem(count: maxExitsAllowed, title: "Max Exits")
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
    }

    private func statItem(count: Int, title: String) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            membersList
        case 1:
            groupRulesContent
        case 2:
            settingsContent
        default:
            EmptyView()
        }
    }

    // MARK: - Members List

    private var membersList: some View {
        LazyVStack(spacing: 10) {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else if viewModel.groupMembers.isEmpty {
                emptyStateView(
                    systemImage: "person.2.slash",
                    title: "No Members",
                    message: "This group doesn't have any members yet."
                )
            } else {
                ForEach(viewModel.groupMembers, id: \.id) { member in
                    NavigationLink(destination: FriendProfileView(friend: member)) {
                        memberRow(member)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func memberRow(_ member: Profile) -> some View {
        HStack {
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(member.full_name.prefix(1))
                        .font(.title2.bold())
                        .foregroundColor(.white.opacity(0.4))
                )
                .overlay(Circle().stroke(Color.white, lineWidth: 2))

            VStack(alignment: .leading) {
                Text(member.full_name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("View Profile")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
    }

    // MARK: - Rules Content

    private var groupRulesContent: some View {
        VStack(spacing: 16) {
            // Toggle Button
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    areRulesExpanded.toggle()
                }
            }) {
                HStack {
                    Text(areRulesExpanded ? "Hide Rules" : "View Current Rules")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.up")
                        .rotationEffect(.degrees(areRulesExpanded ? 0 : 180))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: areRulesExpanded)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(12)
            }

            // Rules Form (Shown Only If Expanded)
            if areRulesExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    // Zone Exits Toggle
                    Toggle("Count Zone Exits", isOn: $countZoneExit)
                        .tint(.blue)

                    if countZoneExit {
                        // Max Exits Stepper
                        HStack {
                            Text("Max Exits:")
                            Spacer()
                            HStack {
                                Button(action: { if maxExitsAllowed > 1 {
                                    maxExitsAllowed -= 1
                                } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(maxExitsAllowed > 1 ? .blue : .gray)
                                }
                                .disabled(maxExitsAllowed <= 1)

                                Text("\(maxExitsAllowed)")
                                    .frame(minWidth: 40)
                                Button(action: { if maxExitsAllowed < 10 {
                                    maxExitsAllowed += 1
                                } }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(maxExitsAllowed < 10 ? .blue : .gray)
                                }
                                .disabled(maxExitsAllowed >= 10)
                            }
                            .foregroundColor(.blue)
                        }
                    }

                    // Allowed Zones Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Allowed Zones")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(ZoneCategory.allCases, id: \.self) { category in
                                categoryToggle(category)
                            }
                        }
                    }

                    // Update Rules Button
                    Button(action: {
                        viewModel.saveGroupRules(
                            countZoneExit: countZoneExit,
                            maxExitsAllowed: maxExitsAllowed,
                            allowedZoneCategories: Array(selectedCategories)
                        )
                    }) {
                        Text(viewModel.currentRules != nil ? "Update Rules" : "Create Rules")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .opacity(areRulesExpanded ? 1 : 0) // Fade in content
                .animation(.easeInOut(duration: 0.3), value: areRulesExpanded)
                .transition(
                    areRulesExpanded ? .move(edge: .top).combined(with: .opacity) : .opacity
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
    }

    private var rulesDetails: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Zone Exits Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: countZoneExit ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(countZoneExit ? .green : .secondary)
                    Text("Zone Exits Tracking")
                        .font(.headline)
                }

                if countZoneExit {
                    HStack(spacing: 4) {
                        Text("Maximum")
                        Text("\(maxExitsAllowed)")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Text("exits allowed")
                    }
                    .padding(.leading)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Allowed Zones Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Allowed Zone Categories")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(selectedCategories), id: \.self) { category in
                        categoryToggle(category)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private func categoryToggle(_ category: ZoneCategory) -> some View {
        let isSelected = selectedCategories.contains(category)
        return Button(action: {
            if isSelected {
                selectedCategories.remove(category)
            } else {
                selectedCategories.insert(category)
            }
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                Text(category.rawValue.capitalized)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(8)
        }
    }

    // MARK: - Settings Content

    private var settingsContent: some View {
        VStack(spacing: 16) {
            settingsButton(title: "Share Group", icon: "square.and.arrow.up") {
                // TODO: Share functionality
            }

            settingsButton(title: "Invite Friend(s)", icon: "person.2.badge.plus.fill", color: .green) {
                // TODO: Invite Friend(s) functionality
            }

            settingsButton(title: "Kick Friend(s)", icon: "door.left.hand.open", color: .red) {
                // TODO: Kick Friend(s) functionality
            }

            settingsButton(title: "Leave Group", icon: "rectangle.portrait.and.arrow.right", color: .red) {
                // TODO: Leave group functionality
            }
        }
        .padding(.horizontal)
    }

    private func settingsButton(
        title: String,
        icon: String,
        color: Color = .blue,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding()
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(12)
        }
    }

    // MARK: - Helper Views

    private func emptyStateView(systemImage: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func generateHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

/// Create a new view for displaying group rules
struct GroupRulesSheet: View {
    let group: Group
    @Environment(\.dismiss) private var dismiss
    @State private var groupRules: GroupRule?
    @State private var isLoading = true
    @State private var error: Error?

    private let groupRepo = GroupsRepository.shared

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                } else if let error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Error loading rules")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            fetchRules()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let rules = groupRules {
                    rulesContent(rules)
                } else {
                    emptyRulesView
                }
            }
            .navigationTitle("Group Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            fetchRules()
        }
    }

    private func fetchRules() {
        isLoading = true
        error = nil

        Task {
            do {
                groupRules = try await groupRepo.fetchGroupRules(groupId: group.id.uuidString)
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }

    private func rulesContent(_ rules: GroupRule) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Zone Exits Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: rules.count_zone_exits ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(rules.count_zone_exits ? .green : .secondary)
                        Text("Zone Exits Tracking")
                            .font(.headline)
                    }

                    if rules.count_zone_exits {
                        HStack(spacing: 4) {
                            Text("Maximum")
                            Text("\(rules.max_exits_allowed)")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Text("exits allowed")
                        }
                        .padding(.leading)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Allowed Zones Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Allowed Zone Categories")
                        .font(.headline)

                    ForEach(rules.allowed_zone_categories, id: \.self) { category in
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.blue)
                            Text(category.rawValue.capitalized)
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
    }

    private var emptyRulesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Rules Set")
                .font(.headline)
            Text("This group doesn't have any rules configured yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
