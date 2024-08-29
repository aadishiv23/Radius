//
//  InfoView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/24/24.
//

import Foundation
import SwiftUI
import MapKit

// InfoView that lists all friends and navigates to their detail view
struct InfoView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager  // Access the shared data
    @State private var isPresentingCreateGroupView = false
    @State private var isPresentingJoinGroupView = false
    @State private var isPresentingCompetitionManagerView = false
    @State private var isShownDemo: Bool = false
    @State private var animateGradient = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {  // Add spacing between sections
                    
                    // Friends Section
                    Section(header: headerView(title: "Friends")) {
                        ForEach(friendsDataManager.friends) { friend in
                            NavigationLink(destination: FriendProfileView(friend: friend)) {
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
                            .padding(.horizontal)
                        }
                    }

                    // Groups Section
                    Section(header: headerView(title: "Groups")) {
                        if friendsDataManager.userGroups.isEmpty {
                            VStack {
                                Image(systemName: "person.3.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("It's lonely here, create a group!")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            ForEach(friendsDataManager.userGroups, id: \.id) { group in
                                GroupView(group: group)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.top) // Add padding to the top
            }
            .navigationTitle("Friends Info")
            .refreshable {
                await refreshData()
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.white.opacity(0.5), Color.yellow.opacity(0.5)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            // Navigate to Create Group View
                            isPresentingCreateGroupView = true
                        }) {
                            Label("Create Group", systemImage: "person.3.fill")
                        }
                        Button(action: {
                            // Navigate to Join Group View
                            isPresentingJoinGroupView = true
                        }) {
                            Label("Join Group", systemImage: "person.crop.circle.badge.plus")
                        }
                        
                        Button(action: {
                            // Navigate to Competition Manager View
                            isPresentingCompetitionManagerView = true
                        }) {
                            Label("Manage Competitions", systemImage: "flag.2.crossed")
                        }
                    } label: {
                        Image(systemName: "plus")
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
            .onAppear {
                Task {
                    await friendsDataManager.fetchFriendsAndGroups()
                }
                
                Task {
                    if let userId = friendsDataManager.currentUser?.id {
                        await friendsDataManager.fetchFriends(for: userId)
                        print("Current user is: \(userId)")
                    } else {
                        print("Current user id is nil")
                    }
                }
                for friendsLocation in friendsDataManager.friends {
                    print(friendsLocation.full_name)
                }
            }
        }
    }
    
    private func refreshData() async {
        guard let userId = friendsDataManager.currentUser?.id else { return }
        await friendsDataManager.fetchFriends(for: userId)
    }

    // Custom Header View
    private func headerView(title: String) -> some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(10)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)  // Softer shadow for subtle elevation
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.2), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                ), lineWidth: 1)
        )
        .padding(.horizontal)
    }

}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView()
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
