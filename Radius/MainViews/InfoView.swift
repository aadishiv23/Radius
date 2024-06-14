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
    @State private var isShownDemo: Bool = false
    @State private var animateGradient = false

    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Friends")) {
                    ForEach(friendsDataManager.friends) { friend in
                        NavigationLink(destination: FriendProfileView(friend: friend)) {
                            HStack {
                                Circle()
                                    .fill(Color(friend.color))
                                    .frame(width: 30, height: 30)
                                Text(friend.full_name)
                                    .foregroundColor(.primary)
                            }
                        }
//                        .listRowBackground(
//                            LinearGradient(
//                                gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.white.opacity(0.5), Color.yellow.opacity(0.5)]),
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                            .edgesIgnoringSafeArea(.all)
//                            .hueRotation(.degrees(animateGradient ? 45 : 0))
//                            .onAppear {
//                                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
//                                    animateGradient.toggle()
//                                }
//                            }
//                        )
                    }
                }

                Section(header: Text("Groups")) {
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
                        }
                    }
                }
                
                Section(header: Text("Demos")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Spacer()
                            Text("Hello Fetch iOS")
                                .font(Font.largeTitle.bold())
                                .offset(x: 0, y: isShownDemo ? 0 : 75)
                                .opacity(isShownDemo ? 1 : 0)
                                .padding(4)
                                .foregroundColor(.orange)
                                .animation(Animation.easeOut.delay(isShownDemo ? 0.1 : 0.2))
                            
                            Text("WWDC24")
                                .font(Font.largeTitle.bold())
                                .offset(x: 0, y: isShownDemo ? 0 : 75)
                                .opacity(isShownDemo ? 1 : 0)
                                .padding(4)
                                .foregroundColor(.red)
                                .animation(Animation.easeOut.delay(0.15))
                            
                            Text("Animate Everything")
                                .font(Font.largeTitle.bold())
                                .offset(x: 0, y: isShownDemo ? 0 : 75)
                                .opacity(isShownDemo ? 1 : 0)
                                .padding(4)
                                .foregroundColor(.blue)
                                .animation(Animation.easeOut.delay(isShownDemo ? 0.2 : 0.1))
                            
                            Spacer()
                            Button(action: {
                                isShownDemo.toggle()
                            }) {
                                Text(isShownDemo ? "Hide" : "Show")
                            }
                        }
                        Spacer()
                    }.padding(16)
                }
                
                Section(header: Text("card demo")) {
                    NavigationLink("card demo1", destination: CardGradientView())
                    NavigationLink("card demo2", destination: CardGradientViewV2())
                }
            }
            .navigationTitle("Friends Info")
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.white.opacity(0.5), Color.yellow.opacity(0.5)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                .hueRotation(.degrees(animateGradient ? 45 : 0))
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
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
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $isPresentingCreateGroupView) {
                CreateGroupView(isPresented: $isPresentingCreateGroupView).environmentObject(friendsDataManager)
            }
            .fullScreenCover(isPresented: $isPresentingJoinGroupView) {
                JoinGroupView(isPresented: $isPresentingJoinGroupView).environmentObject(friendsDataManager)
            }
            .onAppear {
                Task {
                    await friendsDataManager.fetchUserGroups()
                }
            }
        }
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView()
    }
}

