//
//  HomeView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/24/24.
//

import Combine
import MapKit
import SwiftUI


// MARK: - FriendListCell

struct FriendListCell: View {
    let friend: Profile

    var body: some View {
        VStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.accentColor)
                .padding(1)
                .overlay(
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 1)
                )

            Text(friend.full_name)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(width: 80)
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: HomeViewModel

    @State private var selectedFriend: Profile?
    @State private var showFullScreenMap = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var isPresentingZoneEditor = false
    @State private var isPresentingDebugMenu = false
    @State private var isPresentingFriendRequests = false
    @State private var showFogOfWarMap = false

    @State private var userZones: [Zone] = []
    @State private var showZoneExitActionSheet = false
    @Namespace private var zoomNamespace

    /// Initialization with repositories
    init(
        friendsRepository: FriendsRepository,
        groupsRepository: GroupsRepository = GroupsRepository.shared
    ) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            friendsRepository: friendsRepository,
            groupsRepository: groupsRepository
        ))
    }

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack {
                        mapSection
                        Divider()
                        actionScrollList
                        Divider()
                        friendListSection
                    }
                }
            }
            .onAppear {
                NotificationManager.shared.requestAuthorization()
                Task {
                    await viewModel.refreshAllData()
                }
            }
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
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            isPresentingDebugMenu = true
                        } label: {
                            Label("Debug Menu", systemImage: "ladybug")
                        }

                        Button {
                            showZoneExitActionSheet = true
                        } label: {
                            Label("Manual Zone Exit", systemImage: "exclamationmark.circle")
                        }
                    } label: {
                        Image(systemName: "ladybug")
                    }
                }
            }
            .actionSheet(isPresented: $showZoneExitActionSheet) {
                ActionSheet(
                    title: Text("Select Zone to Trigger Exit"),
                    buttons: friendsDataManager.currentUser.zones.map { zone in
                        .default(Text(zone.name)) {
                            handleManualZoneExit(for: zone)
                        }
                    } + [.cancel()]
                )
            }
            .sheet(isPresented: $isPresentingZoneEditor) {
                ZoneEditorView(isPresenting: $isPresentingZoneEditor, userZones: $userZones)
                    .onDisappear {
                        Task {
                            try await friendsDataManager.addZones(
                                to: friendsDataManager.currentUser.id,
                                zones: userZones
                            )
                        }
                    }
            }
            .sheet(item: $selectedFriend) { friend in
                FriendDetailView(friend: friend)
            }
            .sheet(isPresented: $isPresentingDebugMenu) {
                NavigationView {
                    PasswordProtectedDebugMenuView()
                }
            }
            .sheet(isPresented: $isPresentingFriendRequests) {
                FriendRequestsView()
                    .environmentObject(friendsDataManager)
            }
            .sheet(isPresented: $viewModel.isProfileIncomplete) {
                HomeProfileSetupView(isProfileIncomplete: $viewModel.isProfileIncomplete)
            }
            .fullScreenCover(isPresented: $showFogOfWarMap) {
                FogOfWarContainerView()
            }
        }
        .refreshable {
            await viewModel.refreshAllData()
        }
    }

    private func handleManualZoneExit(for zone: Zone) {
        // guard let profileId = friendsDataManager.currentUser?.id else { return }
        // Task {
        //    await locationManager.zoneUpdateManager.handleZoneExits(for: profileId, zoneIds: [zone.id], at: Date())
        // }
        print("silly boy add thsi back")
    }

    private var mapSection: some View {
        ZStack(alignment: .top) {
            Map(
                coordinateRegion: $viewModel.region,
                showsUserLocation: true,
                annotationItems: friendsDataManager.friends.filter { $0.id != friendsDataManager.currentUser?.id }
            ) { friendLocation in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: friendLocation.latitude,
                    longitude: friendLocation.longitude
                )) {
                    FriendAnnotationView(friend: friendLocation)
                }
            }
            .frame(height: 300)
            .cornerRadius(15)
            .padding()

            HStack {
                if viewModel.showRecenterButton {
                    Button(action: viewModel.recenterMap) {
                        Image(systemName: "arrow.circlepath")
                            .circularButtonStyle()
                            .scaleEffect(buttonScale)
                            .animation(.easeInOut(duration: 0.5), value: buttonScale)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                }

                Spacer()

                if #available(iOS 18, *) {
                    Button(action: {
                        showFullScreenMap.toggle()
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .circularButtonStyle()
                            .matchedTransitionSource(id: "zoom", in: zoomNamespace)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                } else {
                    Button(action: {
                        showFullScreenMap.toggle()
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .circularButtonStyle()
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
            }
        }
        .fullScreenCover(isPresented: $showFullScreenMap) {
            if #available(iOS 18, *) {
                FullScreenMapView()
                    .navigationTransition(.zoom(sourceID: "zoom", in: zoomNamespace))
                    .environmentObject(friendsDataManager)
            } else {
                FullScreenMapView()
                    .environmentObject(friendsDataManager)
            }
        }
    }

    // MARK: - Friend List Section

    private var friendListSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            // "Me" Section
            Section(header: Text("Me").font(.headline).padding(.leading)) {
                if let currentUser = friendsDataManager.currentUser {
                    friendRow(currentUser)
                }
            }

            Divider()

            // "Friends" Section
            Section(header: Text("Friends").font(.headline).padding(.leading)) {
                let friends = viewModel.friends.filter { $0.id != friendsDataManager.currentUser?.id }
                if friends.isEmpty {
                    noFriendsRow
                } else {
                    ForEach(friends, id: \.id) { friend in
                        friendRow(friend)
                    }
                }
            }
        }
        .padding(.top, 5)
    }

    @ViewBuilder
    func friendRow(_ friend: Profile) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(friend.full_name.prefix(1))
                        .font(.title2.bold())
                        .foregroundColor(.purple.opacity(0.4))
                )
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.full_name)
                    .font(.headline)
                    .foregroundColor(.primary)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.secondary)
                    Text("\(friend.latitude), \(friend.longitude)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
        .padding(.vertical, 4)
        .onTapGesture {
            selectedFriend = friend
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }

    private var noFriendsRow: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "face.smiling.inverse")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.7))
                )
                .overlay(Circle().stroke(Color.white, lineWidth: 2))

            Text("😢 You have no friends, add by clicking '+'!")
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }

    private var actionScrollList: some View {
        ActionScrollList(actions: [
            (imageName: "mappin.and.ellipse", text: "Add Zone", action: {
                isPresentingZoneEditor = true
            }),
            (imageName: "person.crop.circle.badge.plus", text: "Friend Requests", action: {
                isPresentingFriendRequests = true
            }),
            (imageName: "globe", text: "World", action: {
                showFogOfWarMap = true
            }),
            (imageName: "ladybug", text: "Debug Menu", action: {
                isPresentingDebugMenu = true
            })
        ])
    }
}

// MARK: - GlassyButtonStyle

struct GlassyButtonStyle: ButtonStyle {
    var backgroundColor = Color.blue
    var foregroundColor: Color = .white
    var systemImage: String

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            backgroundColor.opacity(0.7),
                            backgroundColor.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)

            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(foregroundColor)
                .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
                .animation(.spring(), value: configuration.isPressed)
        }
        .frame(width: 60, height: 60)
    }
}

// MARK: - HomeProfileSetupView

struct HomeProfileSetupView: View {
    @Binding var isProfileIncomplete: Bool
    @State private var fullName = ""
    @State private var username = ""
    @State private var isLoading = false
    @State private var usernameError: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Complete Your Profile")
                    .font(.title)
                    .fontWeight(.bold)

                TextField("Full Name", text: $fullName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                VStack(alignment: .leading) {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onChange(of: username) { _ in
                            validateUsername()
                        }

                    if let error = usernameError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Button(action: saveProfile) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .disabled(fullName.isEmpty || username.isEmpty || isLoading)

                Spacer()
            }
            .padding()
        }
    }

    private func validateUsername() {
        Task {
            do {
                let response = try await supabase
                    .from("profiles")
                    .select("username", count: .exact)
                    .eq("username", value: username)
                    .execute()

                if let count = response.count, count > 0 {
                    usernameError = "Username is already taken"
                } else {
                    usernameError = nil
                }
            } catch {
                usernameError = "Error validating username"
            }
        }
    }

    private func saveProfile() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let currentUser = try await supabase.auth.session.user
                try await supabase
                    .from("profiles")
                    .update([
                        "full_name": fullName,
                        "username": username
                    ])
                    .eq("id", value: currentUser.id)
                    .execute()

                isProfileIncomplete = false
            } catch {
                debugPrint("Error saving profile: \(error)")
            }
        }
    }
}
