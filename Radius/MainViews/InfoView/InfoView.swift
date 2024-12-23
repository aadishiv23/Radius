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

    @EnvironmentObject var friendsDataManager: FriendsDataManager

    init(
        friendsRepository: FriendsRepository,
        groupsRepository: GroupsRepository = GroupsRepository.shared,
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
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        // Horizontal Action Scroll List
                        ActionScrollList(actions: [
                            (imageName: "person.3.fill", text: "Create Group", action: {
                                isPresentingCreateGroupView = true
                            }),
                            (
                                imageName: "person.crop.circle.badge.plus",
                                text: "Join Group",
                                action: {
                                    isPresentingJoinGroupView = true
                                }
                            ),
                            (imageName: "flag.2.crossed", text: "Competitions", action: {
                                isPresentingCompetitionManagerView = true
                            })
                        ])

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
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.top)
                }
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
            .onAppear {
                Task {
                    do {
                        try await viewModel.refreshAllData()
                    } catch {
                        print("Error during onAppear: \(error.localizedDescription)")
                    }
                }
            }
            .fullScreenCover(isPresented: $isPresentingCompetitionManagerView) {
                CompetitionManagerView().environmentObject(friendsDataManager)
            }
            .fullScreenCover(isPresented: $isPresentingCreateGroupView) {
                CreateGroupView(isPresented: $isPresentingCreateGroupView).environmentObject(friendsDataManager)
            }
            .fullScreenCover(isPresented: $isPresentingJoinGroupView) {
                JoinGroupView(isPresented: $isPresentingJoinGroupView).environmentObject(friendsDataManager)
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
                withAnimation(.spring) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.up")
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 0 : 180))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isExpanded)
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
                    .transition(
                        AnyTransition
                            .move(edge: .top)
                            .combined(with: .opacity)
                            .animation(.easeInOut(duration: 0.7))
                            .combined(with: .opacity.animation(.easeOut(duration: 0.2)))
                    )
                    .animation(.easeInOut(duration: 1.0), value: isExpanded)
                    .padding(.top, 5)
                    .frame(maxWidth: .infinity) // Ensure the content takes full width
            }
        }
        .padding(.horizontal)
    }
}
