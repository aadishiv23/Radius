//
//  HomeView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/24/24.
//

import Combine
import MapKit
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager // Assuming this contains your friendsLocations
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: HomeViewModel
    @ObservedObject private var locationManager = LocationManager.shared

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.278378215221565, longitude: -83.74388859636869),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @State private var selectedFriend: Profile?
    @State private var showRecenterButton = false
    @State private var showFullScreenMap = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var isPresentingZoneEditor = false
    @State private var isPresentingDebugMenu = false
    @State private var isPresentingFriendRequests = false

    @State private var userZones: [Zone] = []
    private var checkDistanceTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    @State private var animateGradient = false
    @State private var showZoneExitActionSheet = false
    @State private var userPoints: Int? = nil // To hold the user's points

    // Updated State Variables
    @State private var showFABMenu = false
    @State private var addZoneButtonOffset = CGSize.zero
    @State private var friendRequestButtonOffset = CGSize.zero
    @State private var addZoneButtonScale: CGFloat = 0.0
    @State private var friendRequestButtonScale: CGFloat = 0.0

    /// Initialization with repositories
    init(
        friendsRepository: FriendsRepository,
        groupsRepository: GroupsRepository
    ) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            friendsRepository: friendsRepository,
            groupsRepository: groupsRepository
        ))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    mapSection
                    Divider()
                    friendListSection
                }
            }
            .onAppear {
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
                // Plus button with a dropdown menu

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

                // Points pill to show next to the plus button
//                ToolbarItem(placement: .topBarTrailing) {
//                    PointsPillView(points: userPoints)  // Reuse the PointsPillView created earlier
//                }
            }
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            // Main FAB
                            Button(action: {
                                // Haptic Feedback
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()

                                showFABMenu.toggle()

                                if showFABMenu {
                                    // Animate buttons appearing
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.05)) {
                                        addZoneButtonOffset = CGSize(width: 0, height: -80)
                                        addZoneButtonScale = 1.0
                                    }
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                                        friendRequestButtonOffset = CGSize(width: 0, height: -160)
                                        friendRequestButtonScale = 1.0
                                    }
                                } else {
                                    // Animate buttons disappearing with a jump up before falling
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.45)) {
                                        // Move up slightly (negative offset increases)
                                        friendRequestButtonOffset = CGSize(width: 0, height: -180)
                                        friendRequestButtonScale = 0.0
                                    }
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.45).delay(0.1)) {
                                        // Move up slightly
                                        addZoneButtonOffset = CGSize(width: 0, height: -100)
                                        addZoneButtonScale = 0.0
                                    }
                                    // Then animate buttons falling into FAB
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                                        friendRequestButtonOffset = .zero
                                        addZoneButtonOffset = .zero
                                    }
                                }
                            }) {
                                Image(systemName: "plus")
                                    .rotationEffect(Angle(degrees: showFABMenu ? 135 : 0))
                                    .foregroundColor(.white)
                                    .font(.system(size: 24, weight: .bold))
                                    .frame(width: 60, height: 60)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }

                            // Add Zone Button
                            Button(action: {
                                isPresentingZoneEditor = true
                            }) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(24)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Circle()
                                                    .fill(Color.blue.opacity(0.4))
                                            )
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                                    )
                                    .shadow(radius: 5)
                            }
                            .offset(addZoneButtonOffset)
                            .scaleEffect(addZoneButtonScale)

                            // Friend Request Button
                            Button(action: {
                                isPresentingFriendRequests = true
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
                                                    .fill(Color.blue.opacity(0.4))
                                            )
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                                    )
                                    .shadow(radius: 5)
                            }
                            .offset(friendRequestButtonOffset)
                            .scaleEffect(friendRequestButtonScale)
                        }
                        .padding()
                    }
                }
            )
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

            .onReceive(checkDistanceTimer) { _ in
                checkDistance()
            }
        }
        .refreshable {
            await refreshData()
        }
        .onAppear {
            fetchUserPoints()
            locationManager.checkIfLocationServicesIsEnabled()
            locationManager.plsInitiateLocationUpdates()
            if let userLocation = locationManager.userLocation?.coordinate {
                region.center = userLocation
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

    private func handleManualZoneExit(for zone: Zone) {
        // guard let profileId = friendsDataManager.currentUser?.id else { return }
        // Task {
        //    await locationManager.zoneUpdateManager.handleZoneExits(for: profileId, zoneIds: [zone.id], at: Date())
        // }
        print("silly boy add thsi back")
    }

    private func refreshData() async {
        guard let userId = friendsDataManager.currentUser?.id else {
            return
        }
        await friendsDataManager.fetchFriends(for: userId)
        await friendsDataManager.fetchUserGroups()
    }

    private var mapSection: some View {
        ZStack(alignment: .top) {
            Map(
                coordinateRegion: $region,
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
                if showRecenterButton {
                    Button(action: recenterMap) {
                        Image(systemName: "arrow.circlepath")
                            .circularButtonStyle()
                            .scaleEffect(buttonScale)
                            .animation(.easeInOut(duration: 0.5), value: buttonScale)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                }

                Spacer()

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
        .fullScreenCover(isPresented: $showFullScreenMap) {
            FullScreenMapView()
        }
    }

    private var friendListSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Me Section
            Section(header: Text("Me").font(.headline).padding(.leading)) {
                if let currentUser = friendsDataManager.currentUser {
                    friendRow(currentUser)
                }
            }

            Divider()

            // Friends Section
            Section(header: Text("Friends").font(.headline).padding(.leading)) {
                let friends = friendsDataManager.friends.filter { $0.id != friendsDataManager.currentUser?.id }
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
            generator.impactOccurred() // Add haptic feedback
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
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private func checkDistance() {
        guard let currentLocation = locationManager.userLocation else {
            return
        }
        let initialLocation = CLLocation(
            latitude: currentLocation.coordinate.latitude,
            longitude: currentLocation.coordinate.longitude
        )
        let distance = initialLocation.distance(from: initialLocation)
        showRecenterButton = distance > 500
    }

    private func recenterMap() {
        if let userLocation = locationManager.userLocation {
            region.center = userLocation.coordinate
            region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            showRecenterButton = false
        }
    }

    private func fetchUserPoints() {
        // Fetch points logic (mocked here)
        Task {
            // Example logic to fetch user points, replace with actual data fetching
            // userPoints = try await fetchPointsForCurrentUser()
            userPoints = 500 // Mock value, replace with actual logic
        }
    }
}

// MARK: - UINavigationController + UIGestureRecognizerDelegate

// struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView()
//    }
// }

/// nic code to controll swiping navigation view back even when .navigationbar is hidden
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
}

struct GlassyButtonStyle: ButtonStyle {
    var backgroundColor = Color.blue
    var foregroundColor: Color = .white
    var systemImage: String

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Glassy Background
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

            // Button Image
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(foregroundColor)
                .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
                .animation(.spring(), value: configuration.isPressed)
        }
        .frame(width: 60, height: 60)
    }
}
