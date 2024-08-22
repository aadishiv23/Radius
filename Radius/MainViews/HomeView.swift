//
//  HomeView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/24/24.
//

import SwiftUI
import MapKit
import Combine

struct HomeView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager  // Assuming this contains your friendsLocations
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var locationManager = LocationManager.shared
    
    @State private var region =  MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var selectedFriend: Profile?
    @State private var showRecenterButton = false
    @State private var showFullScreenMap = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var isPresentingZoneEditor = false
    @State private var isPresentingGroupView = false
    @State private var isPresentingDebugMenu = false
    @State private var isPresentingFriendRequests = false
    
    @State private var userZones: [Zone] = []
    private let initialCenter = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    private var checkDistanceTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    @State private var animateGradient = false
    @State private var showZoneExitActionSheet = false

    
//    @StateObject private var mapRegionObserver: MapRegionObserver
//
//    init() {
//        _mapRegionObserver = StateObject(wrappedValue: MapRegionObserver(initialCenter: initialCenter))
//    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    mapSection
                    Divider()
                    friendListSection
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.white.opacity(0.5), Color.yellow.opacity(0.5)]),
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
                            isPresentingZoneEditor = true
                        } label: {
                            Label("Add Zones", systemImage: "mappin.and.ellipse")
                        }

                        Button {
                            isPresentingGroupView = true
                        } label: {
                            Label("Add Group", systemImage: "person.3")
                        }
                        
                        Button {
                            isPresentingDebugMenu = true
                        } label: {
                            Label("Debug Menu", systemImage: "ladybug")
                        }
                        
                        Button {
                            isPresentingFriendRequests = true
                        } label: {
                            Label("Friend Requests", systemImage: "person.crop.circle.badge.plus")
                        }
                        
                        Button {
                            showZoneExitActionSheet = true
                        } label: {
                            Label("Manual Zone Exit", systemImage: "exclamationmark.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
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
                            try await friendsDataManager.addZones(to: friendsDataManager.currentUser.id, zones: userZones)
                        }
                    }
            }
            .sheet(item: $selectedFriend) { friend in
                FriendDetailView(friend: friend)
            }
            .sheet(isPresented: $isPresentingGroupView) {
                AddGroupView()
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
            locationManager.checkIfLocationServicesIsEnabled()
            locationManager.plsInitiateLocationUpdates()
            region = MKCoordinateRegion(center:
                CLLocationCoordinate2D(latitude: friendsDataManager.currentUser?.latitude ?? 40.7128,
                   longitude: friendsDataManager.currentUser?.longitude ?? -74.0060),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
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
        guard let profileId = friendsDataManager.currentUser?.id else { return }
        Task {
            await locationManager.zoneUpdateManager.handleZoneExits(for: profileId, zoneIds: [zone.id], at: Date())
        }
    }
    
    private func refreshData() async {
        guard let userId = friendsDataManager.currentUser?.id else { return }
        await friendsDataManager.fetchFriends(for: userId)
        await friendsDataManager.fetchUserGroups()
    }
    
    private var mapSection: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: friendsDataManager.friends.filter { $0.id != friendsDataManager.currentUser?.id }) { friendLocation in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: friendLocation.latitude, longitude: friendLocation.longitude)) {
                    Circle()
                        .fill(Color(hex: friendLocation.color) ?? .blue)
                        .frame(width: 20, height: 20)
                        .onTapGesture {
                            selectedFriend = friendLocation
                        }
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
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .circularButtonStyle()
                }
                .padding(.trailing, 20)
                .padding(.top, 20)
            }
        }
        .sheet(isPresented: $showFullScreenMap) {
            FullScreenMapView(region: $region, selectedFriend: $selectedFriend, isPresented: $showFullScreenMap)
                .environmentObject(friendsDataManager)
        }
    }
    
    private var friendListSection: some View {
       VStack(alignment: .leading, spacing: 16) {
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
       .padding(.top)
   }
    
    @ViewBuilder
    func friendRow(_ friend: Profile) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(hex: friend.color) ?? .white)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(friend.full_name.prefix(1))
                        .font(.title2.bold())
                        .foregroundColor(.purple.opacity(0.4))
                )
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
        .background(Color(UIColor.systemBackground).opacity(0.8))
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
        }
    }
    
    private var noFriendsRow: some View {
        HStack(spacing: 16) {
            Image(systemName: "face.smiling.inverse")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("😢 Boohoo! You have no friends. Add some now!")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground).opacity(0.8))
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
        let currentLocation = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        let initialLocation = CLLocation(latitude: initialCenter.latitude, longitude: initialCenter.longitude)
        let distance = currentLocation.distance(from: initialLocation)
        showRecenterButton = distance > 500
    }
    
    private func recenterMap() {
        region.center = initialCenter
        region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        showRecenterButton = false
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}




// nic code to controll swiping navigation view back even when .navigationbar is hidden
extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
}
