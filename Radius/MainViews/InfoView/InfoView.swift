//
//  InfoView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/24/24.
//

import Foundation
import MapKit
import SwiftUI

// InfoView that lists all friends and navigates to their detail view

struct InfoView: View {
    @StateObject var viewModel: InfoViewModel
    @State private var isPresentingCreateGroupView = false
    @State private var isPresentingJoinGroupView = false
    @State private var isPresentingCompetitionManagerView = false

    @State private var showFABMenu = false
    @State private var createGroupButtonOffset = CGSize.zero
    @State private var joinGroupButtonOffset = CGSize.zero
    @State private var manageCompetitionsButtonOffset = CGSize.zero
    @State private var createGroupButtonScale: CGFloat = 0.0
    @State private var joinGroupButtonScale: CGFloat = 0.0
    @State private var manageCompetitionsButtonScale: CGFloat = 0.0

    // Constants for button positions
    private let buttonRadius: CGFloat = 100
    private let sqrt2over2: CGFloat = 0.7071

    /// Final offsets for each button
    private var createGroupFinalOffset: CGSize {
        CGSize(width: -buttonRadius, height: 0)
    }

    private var joinGroupFinalOffset: CGSize {
        CGSize(width: -buttonRadius * sqrt2over2, height: -buttonRadius * sqrt2over2)
    }

    private var manageCompetitionsFinalOffset: CGSize {
        CGSize(width: 0, height: -buttonRadius)
    }

    @EnvironmentObject var friendsDataManager: FriendsDataManager
    // Other EnvironmentObjects...

    init(
        friendsRepository: FriendsRepository,
        groupsRepository: GroupsRepository,
        competitionsRepository: CompetitionsRepository,
        userId: UUID
    ) {
        _viewModel = StateObject(wrappedValue: InfoViewModel(
            friendsRepository: friendsRepository,
            groupsRepository: groupsRepository,
            competitionsRepository: competitionsRepository,
            userId: userId
        ))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Friends Section
                    CollapsibleSection(title: "Friends") {
                        if $viewModel.filteredFriends.isEmpty, !viewModel.searchText.isEmpty {
                            noResultsView(for: "Friends")
                        } else {
                            ForEach(viewModel.filteredFriends) { friend in
                                NavigationLink(destination: FriendProfileView(friend: friend)) {
                                    FriendRowView(friend: friend)
                                }
                            }
                        }
                    }

                    // Groups Section
                    CollapsibleSection(title: "Groups") {
                        if viewModel.filteredGroups.isEmpty, !viewModel.searchText.isEmpty {
                            noResultsView(for: "Groups")
                        } else if viewModel.filteredGroups.isEmpty {
                            emptyGroupsView()
                        } else {
                            ForEach(viewModel.filteredGroups, id: \.id) { group in
                                GroupView(group: group)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    // Competitions Section
                    CollapsibleSection(title: "Competitions") {
                        if viewModel.filteredCompetitions.isEmpty, !viewModel.searchText.isEmpty {
                            noResultsView(for: "Competitions")
                        } else if viewModel.filteredCompetitions.isEmpty {
                            emptyCompetitionsView()
                        } else {
                            LazyVStack {
                                ForEach(viewModel.filteredCompetitions) { competition in
                                    CompetitionCard(competition: competition)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Social")
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search Friends, Groups, Competitions"
            )
            .refreshable {
                do {
                    try await viewModel.refreshAllData()
                } catch {
                    print("Error during refreshable: \(error.localizedDescription)")
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.5),
                        Color.white.opacity(0.5),
                        Color.yellow.opacity(0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
            )
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    Menu {
//                        Button(action: {
//                            // Navigate to Create Group View
//                            isPresentingCreateGroupView = true
//                        }) {
//                            Label("Create Group", systemImage: "person.3.fill")
//                        }
//                        Button(action: {
//                            // Navigate to Join Group View
//                            isPresentingJoinGroupView = true
//                        }) {
//                            Label("Join Group", systemImage: "person.crop.circle.badge.plus")
//                        }
//
//                        Button(action: {
//                            // Navigate to Competition Manager View
//                            isPresentingCompetitionManagerView = true
//                        }) {
//                            Label("Manage Competitions", systemImage: "flag.2.crossed")
//                        }
//                    } label: {
//                        Image(systemName: "plus")
//                    }
//                }
//            }
            .overlay(
                VStack {
                    Spacer()
                    // Main FAB and action buttons
                    HStack {
                        // Main FAB
                        Spacer()

                        ZStack {
                            Button(action: {
                                // Haptic Feedback
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                
                                showFABMenu.toggle()
                                
                                if showFABMenu {
                                    // Animate buttons appearing
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                        createGroupButtonOffset = createGroupFinalOffset
                                        createGroupButtonScale = 1.0
                                    }
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.05)) {
                                        joinGroupButtonOffset = joinGroupFinalOffset
                                        joinGroupButtonScale = 1.0
                                    }
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                                        manageCompetitionsButtonOffset = manageCompetitionsFinalOffset
                                        manageCompetitionsButtonScale = 1.0
                                    }
                                } else {
                                    // Animate buttons disappearing
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.45)) {
                                        manageCompetitionsButtonOffset = .zero
                                        manageCompetitionsButtonScale = 0.0
                                    }
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.45).delay(0.05)) {
                                        joinGroupButtonOffset = .zero
                                        joinGroupButtonScale = 0.0
                                    }
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.45).delay(0.1)) {
                                        createGroupButtonOffset = .zero
                                        createGroupButtonScale = 0.0
                                    }
                                }
                            }) {
                                Image(systemName: "person.3.sequence.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24, weight: .bold))
                                    .frame(width: 60, height: 60)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            
                            // Create Group Button
                            Button(action: {
                                isPresentingCreateGroupView = true
                            }) {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(24)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Circle()
                                                    .fill(Color.green.opacity(0.4))
                                            )
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                                    )
                                    .shadow(radius: 5)
                            }
                            .offset(createGroupButtonOffset)
                            .scaleEffect(createGroupButtonScale)
                            
                            // Join Group Button
                            Button(action: {
                                isPresentingJoinGroupView = true
                            }) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(24)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Circle()
                                                    .fill(Color.orange.opacity(0.4))
                                            )
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                                    )
                                    .shadow(radius: 5)
                            }
                            .offset(joinGroupButtonOffset)
                            .scaleEffect(joinGroupButtonScale)
                            
                            // Manage Competitions Button
                            Button(action: {
                                isPresentingCompetitionManagerView = true
                            }) {
                                Image(systemName: "flag.2.crossed")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(24)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Circle()
                                                    .fill(Color.purple.opacity(0.4))
                                            )
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                                    )
                                    .shadow(radius: 5)
                            }
                            .offset(manageCompetitionsButtonOffset)
                            .scaleEffect(manageCompetitionsButtonScale)
                        }
                    }
                    .padding()
                }
            )

            .fullScreenCover(isPresented: $isPresentingCompetitionManagerView) {
                CompetitionManagerView().environmentObject(friendsDataManager)
            }
            .fullScreenCover(isPresented: $isPresentingCreateGroupView) {
                CreateGroupView(isPresented: $isPresentingCreateGroupView).environmentObject(friendsDataManager)
            }
            .fullScreenCover(isPresented: $isPresentingJoinGroupView) {
                JoinGroupView(isPresented: $isPresentingJoinGroupView).environmentObject(friendsDataManager)
            }
            .onAppear {
                Task {
                    do {
                        try await viewModel.refreshAllData()
                    } catch {
                        print("Error during onAppear: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    /// Helper Views
    private func noResultsView(for category: String) -> some View {
        VStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No matching \(category.lowercased()) found")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Try adjusting your search criteria.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(10)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func FriendRowView(friend: Profile) -> some View {
        HStack {
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(friend.full_name.prefix(1))
                        .font(.title2.bold())
                        .foregroundColor(.purple.opacity(0.4))
                )
                .overlay(Circle().stroke(Color.white, lineWidth: 2))

            VStack(alignment: .leading) {
                Text(friend.full_name)
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

    private func emptyGroupsView() -> some View {
        VStack {
            Image(systemName: "person.3.fill")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("It's lonely here, create a group!")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private func emptyCompetitionsView() -> some View {
        VStack {
            Image(systemName: "flag.2.crossed.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No active competitions")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Join or create a competition to get started!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(10)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// struct InfoView_Previews: PreviewProvider {
//    static var previews: some View {
//        InfoView(, viewModel: Infov)
//    }
// }

struct CompetitionCard: View {
    let competition: GroupCompetition

    var body: some View {
        NavigationLink(destination: CompetitionDetailView(competition: competition)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "flag.2.crossed.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    Text(competition.competition_name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Text(formattedDate(competition.competition_date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Max Points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(competition.max_points)")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    Spacer()

                    Button(action: {
                        // Action to view competition details
                    }) {
                        Text("View Details")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.4)]),
                // Adjusted for better contrast
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.white.opacity(0.5), .clear]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

//                Section(header: Text("Demos")) {
//                    HStack {
//                        VStack(alignment: .leading) {
//                            Spacer()
//                            Text("Hello Fetch iOS")
//                                .font(Font.largeTitle.bold())
//                                .offset(x: 0, y: isShownDemo ? 0 : 75)
//                                .opacity(isShownDemo ? 1 : 0)
//                                .padding(4)
//                                .foregroundColor(.orange)
//                                .animation(Animation.easeOut.delay(isShownDemo ? 0.1 : 0.2))
//
//                            Text("WWDC24")
//                                .font(Font.largeTitle.bold())
//                                .offset(x: 0, y: isShownDemo ? 0 : 75)
//                                .opacity(isShownDemo ? 1 : 0)
//                                .padding(4)
//                                .foregroundColor(.red)
//                                .animation(Animation.easeOut.delay(0.15))
//
//                            Text("Animate Everything")
//                                .font(Font.largeTitle.bold())
//                                .offset(x: 0, y: isShownDemo ? 0 : 75)
//                                .opacity(isShownDemo ? 1 : 0)
//                                .padding(4)
//                                .foregroundColor(.blue)
//                                .animation(Animation.easeOut.delay(isShownDemo ? 0.2 : 0.1))
//
//                            Spacer()
//                            Button(action: {
//                                isShownDemo.toggle()
//                            }) {
//                                Text(isShownDemo ? "Hide" : "Show")
//                            }
//                        }
//                        Spacer()
//                    }.padding(16)
//                }

//                Section(header: Text("card demo")) {
//                    NavigationLink("card demo1", destination: CardGradientView())
//                    NavigationLink("card demo2", destination: CardGradientViewV2())
//                }

struct CollapsibleSection<Content: View>: View {
    let title: String
    @State private var isExpanded = true
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack {
            Button(action: {
                withAnimation(.none) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(10)
                )
                .frame(maxWidth: .infinity) // Ensure the header button takes full width
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                content
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 1.0), value: isExpanded)
                    .padding(.top, 5)
                    .frame(maxWidth: .infinity) // Ensure the content takes full width
            }
        }
        .padding(.horizontal)
    }
}

