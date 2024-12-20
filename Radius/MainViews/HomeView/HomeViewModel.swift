import Combine
import Foundation
import MapKit
import Supabase

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var friends: [Profile] = []
    @Published var currentUser: Profile?
    @Published var userGroups: [Group] = []
    @Published var pendingRequests: [FriendRequest] = []
    @Published var searchText = ""
    // @Published var userPoints: Int?
    @Published var isProfileIncomplete = false // Track if profile needs setup
    @Published var showRecenterButton = false
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.278378215221565, longitude: -83.74388859636869),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )


    // MARK: - Dependencies

    private let friendsRepository: FriendsRepository
    private let groupsRepository: GroupsRepository
    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    private var checkDistanceTimer: AnyCancellable? // Timer reference
    
    // MARK: - Initialization
    
    init(
        friendsRepository: FriendsRepository,
        groupsRepository: GroupsRepository = GroupsRepository.shared,
        locationManager: LocationManager = LocationManager.shared
    ) {
        self.friendsRepository = friendsRepository
        self.groupsRepository = groupsRepository
        self.locationManager = locationManager
        
        setupBindings()
        startLocationUpdates()
        startDistanceCheckTimer()
        Task {
            await refreshAllData()
            await checkUserProfile()
        }
    }
    
    deinit {
        checkDistanceTimer?.cancel()
    }
    
    // MARK: - Setup Bindings
    
    private func setupBindings() {
        // Example: Bind friends from repository to ViewModel
        friendsRepository.$friends
            .receive(on: DispatchQueue.main)
            .assign(to: \.friends, on: self)
            .store(in: &cancellables)
        
        // Similarly, bind groups and competitions
        groupsRepository.$groups
            .receive(on: DispatchQueue.main)
            .assign(to: \.userGroups, on: self)
            .store(in: &cancellables)
        
        locationManager.$userLocation
            .compactMap { $0?.coordinate }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinate in
                self?.updateMapRegion(with: coordinate)
            }
            .store(in: &cancellables)
    }
    
    private func startLocationUpdates() {
        locationManager.checkIfLocationServicesIsEnabled()
        locationManager.plsInitiateLocationUpdates()
    }
    
    private func startDistanceCheckTimer() {
        checkDistanceTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                self?.checkDistance()
            }
    }
    
    // MARK: - Data Fetching
    
    func refreshAllData() async {
        do {
            // Fetch current user profile
            currentUser = try await friendsRepository.fetchCurrentUser()
            guard let userId = currentUser?.id else {
                return
            }
            
            // Fetch Friends
            friends = try await friendsRepository.fetchFriends(for: userId)
            
            // Fetch Groups
            userGroups = try await groupsRepository.fetchGroups(for: userId)
            
        } catch let error as PostgrestError {
            print("Supabase error while refreshing data: \(error.localizedDescription)")
        } catch let error as URLError {
            if error.code == .timedOut {
                print("Network timeout: \(error.localizedDescription)")
            } else {
                print("URLError: \(error.localizedDescription)")
            }
        } catch {
            print("Unexpected error while refreshing data: \(error.localizedDescription)")
        }
    }
    
    func updateMapRegion(with coordinate: CLLocationCoordinate2D) {
        region.center = coordinate
    }
    
    func checkUserProfile() async {
            do {
                let currentUser = try await supabase.auth.session.user
                let profile: Profile = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: currentUser.id)
                    .single()
                    .execute()
                    .value

                if profile.full_name.isEmpty || profile.username.isEmpty {
                    isProfileIncomplete = true
                }
            } catch {
                debugPrint("Error checking user profile: \(error)")
            }
        }
    
    // MARK: - Map Logic
    
    func checkDistance() {
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
    
    func recenterMap() {
        if let userLocation = locationManager.userLocation {
            region.center = userLocation.coordinate
            region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            showRecenterButton = false
        }
    }

    
    
    // MARK: - Points Logic
    
//    func fetchUserPoints() {
//        // Fetch points logic (mocked here)
//        Task {
//           // userPoints = 500 // Mock value, replace with actual logic
//        }
//    }
    
}
