//
//  FullScreenMapView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/25/24.
//

import MapKit
import SwiftUI

struct FullScreenMapView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedFriend: Profile? // Tracks the selected friend
    @State private var isFriendSelectionExpanded: Bool = false // New state variable

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Map View
            Map(
                coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: friendsDataManager.friends.filter { $0.id != friendsDataManager.currentUser?.id }
            ) { friend in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: friend.latitude,
                    longitude: friend.longitude
                )) {
                    FriendAnnotationView(friend: friend)
                        .onTapGesture {
                            selectFriend(friend)
                        }
                }
            }
            .ignoresSafeArea()
            .onAppear {
                if let location = locationManager.userLocation?.coordinate {
                    region.center = location
                } else {
                    // Fallback to a default location if userLocation is not available
                    region.center = CLLocationCoordinate2D(latitude: 42.278378, longitude: -83.743889)
                }
            }

            // Close Button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .padding()

            // Friend Selection Section
            VStack(spacing: 0) {
                if isFriendSelectionExpanded {
                    // Expanded FriendSelectionView with Stub to Collapse
                    VStack(spacing: 0) {
                        // Stub with Down Chevron
                        Button(action: {
                            toggleFriendSelection()
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Actual FriendSelectionView
                        FriendSelectionView(
                            friends: friendsDataManager.friends.filter { $0.id != friendsDataManager.currentUser?.id },
                            selectedFriend: $selectedFriend,
                            onSelect: selectFriend
                        )
                        // Removed negative padding
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .background(Color(.systemBackground).opacity(0.95))
                    .cornerRadius(16, corners: [.topLeft, .topRight])
                    .shadow(radius: 5)
                    .ignoresSafeArea(edges: .bottom) // Ensures the background extends to the bottom
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // Collapsed Button with Up Chevron
                    Button(action: {
                        toggleFriendSelection()
                    }) {
                        Image(systemName: "chevron.up")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                            .padding(.bottom, 20)
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom) // Aligns the VStack to the bottom
            .animation(.easeInOut, value: isFriendSelectionExpanded)
        }
    }

    // Function to toggle the friend selection section
    private func toggleFriendSelection() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isFriendSelectionExpanded.toggle()
        }
    }

    private func selectFriend(_ friend: Profile) {
        selectedFriend = friend
        withAnimation {
            region.center = CLLocationCoordinate2D(latitude: friend.latitude, longitude: friend.longitude)
        }
    }
}

// MARK: - RoundedCorner Extension for Specific Corners

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    // Defines the path for the shape
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - FriendSelectionView

struct FriendSelectionView: View {
    let friends: [Profile]
    @Binding var selectedFriend: Profile?
    var onSelect: (Profile) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(friends) { friend in
                    Button(action: {
                        onSelect(friend)
                    }) {
                        VStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(friend.full_name.prefix(1))
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                )
                                .overlay(
                                    Circle().stroke(
                                        friend.id == selectedFriend?.id ? Color.blue : Color.gray,
                                        lineWidth: 5
                                    )
                                )
                            Text(friend.full_name)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .padding(.horizontal) // Only horizontal padding to prevent vertical gaps
            .padding(.bottom, 10) // Add some padding at the bottom if desired
        }
    }
}

// MARK: - FriendAnnotationView

struct FriendAnnotationView: View {
    let friend: Profile

    @State private var isExpanded = false

    var body: some View {
        ZStack {
            if isExpanded {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.yellow]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 2)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)

                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.yellow]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)

                    if !isExpanded {
                        Text(String(friend.full_name.prefix(1)))
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                            .transition(.opacity)
                    }
                }
            }

            if isExpanded {
                Text(friend.full_name)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
                    .transition(.opacity)
            }
        }
        .frame(width: isExpanded ? 150 : 40, height: 40)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }

            // Automatically toggle back to the circle after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded = false
                }
            }
        }
        .shadow(radius: 3)
    }
}

////
////  FullScreenMapView.swift
////  Radius
////
////  Created by Aadi Shiv Malhotra on 4/25/24.
////
//
// import MapKit
// import SwiftUI
//
// struct FullScreenMapView: View {
//    @EnvironmentObject var friendsDataManager: FriendsDataManager
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var locationManager = LocationManager.shared
//    @State private var region = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
//        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
//    )
//    @State private var selectedFriend: Profile? // Added state to track the selected friend
//
//    var body: some View {
//        ZStack(alignment: .topTrailing) {
//            Map(
//                coordinateRegion: $region,
//                showsUserLocation: true,
//                annotationItems: friendsDataManager.friends.filter { $0.id != friendsDataManager.currentUser?.id }
//            ) { friend in
//                MapAnnotation(coordinate: CLLocationCoordinate2D(
//                    latitude: friend.latitude,
//                    longitude: friend.longitude
//                )) {
//                    FriendAnnotationView(friend: friend)
//                        .onTapGesture {
//                            selectFriend(friend)
//                        }
//                }
//            }
//            .ignoresSafeArea()
//            .onAppear {
//                if let location = locationManager.userLocation?.coordinate {
//                    region.center = location
//                } else {
//                    // Fallback to a default location if userLocation is not available
//                    region.center = CLLocationCoordinate2D(latitude: 42.278378215221565, longitude:
//                    -83.74388859636869)
//                }
//            }
//
//            // Close button
//            Button(action: {
//                dismiss()
//            }) {
//                Image(systemName: "xmark")
//                    .foregroundColor(.primary)
//                    .padding()
//                    .background(Color(.systemBackground))
//                    .clipShape(Circle())
//                    .shadow(radius: 2)
//            }
//            .padding()
//
//            // Friend selection list at the bottom
//            VStack {
//                Spacer()
//                FriendSelectionView(
//                    friends: friendsDataManager.friends.filter { $0.id != friendsDataManager.currentUser?.id },
//                    selectedFriend: $selectedFriend,
//                    onSelect: selectFriend
//                )
//                .background(Color(.systemBackground).opacity(0.9))
//            }
//        }
//    }
//
//    private func selectFriend(_ friend: Profile) {
//        selectedFriend = friend
//        withAnimation {
//            region.center = CLLocationCoordinate2D(latitude: friend.latitude, longitude: friend.longitude)
//        }
//    }
// }
//
///// Friend selection view
// struct FriendSelectionView: View {
//    let friends: [Profile]
//    @Binding var selectedFriend: Profile?
//    var onSelect: (Profile) -> Void
//
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 16) {
//                ForEach(friends) { friend in
//                    Button(action: {
//                        onSelect(friend)
//                    }) {
//                        VStack {
//                            Circle()
//                                .fill(Color.white)
//                                .frame(width: 50, height: 50)
//                                .overlay(
//                                    Text(friend.full_name.prefix(1))
//                                        .font(.headline)
//                                        .foregroundColor(.blue)
//                                )
//                                .overlay(
//                                    Circle().stroke(
//                                        friend.id == selectedFriend?.id ? Color.blue : Color.gray,
//                                        lineWidth: 3
//                                    )
//                                )
//                            Text(friend.full_name)
//                                .font(.caption)
//                                .foregroundColor(.primary)
//                        }
//                    }
//                }
//            }
//            .padding()
//        }
//    }
// }
//
///// Friend annotation view
// struct FriendAnnotationView: View {
//    let friend: Profile
//
//    @State private var isExpanded = false
//
//    var body: some View {
//        ZStack {
//            if isExpanded {
//                RoundedRectangle(cornerRadius: 20)
//                    .fill(
//                        LinearGradient(
//                            gradient: Gradient(colors: [Color.blue, Color.yellow]),
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                    )
//                    .frame(width: 150, height: 40)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 20)
//                            .stroke(Color.white, lineWidth: 2)
//                    )
//            } else {
//                ZStack {
//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: 40, height: 40)
//
//                    Circle()
//                        .fill(
//                            LinearGradient(
//                                gradient: Gradient(colors: [Color.blue, Color.yellow]),
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                        )
//                        .frame(width: 34, height: 34)
//
//                    if !isExpanded {
//                        Text(String(friend.full_name.prefix(1)))
//                            .foregroundColor(.white)
//                            .font(.system(size: 20, weight: .bold))
//                            .transition(.opacity)
//                    }
//                }
//            }
//
//            if isExpanded {
//                Text(friend.full_name)
//                    .foregroundColor(.white)
//                    .font(.system(size: 16, weight: .bold))
//                    .transition(.opacity)
//            }
//        }
//        .frame(width: isExpanded ? 150 : 40, height: 40)
//        .onTapGesture {
//            withAnimation(.easeInOut(duration: 0.3)) {
//                isExpanded.toggle()
//            }
//
//            // Automatically toggle back to the circle after a delay
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                withAnimation(.easeInOut(duration: 0.3)) {
//                    isExpanded = false
//                }
//            }
//        }
//        .shadow(radius: 3)
//    }
// }
//
//// import SwiftUI
//// import MapKit
////
//// struct FullScreenMapView: View {
////    @EnvironmentObject var friendsDataManager: FriendsDataManager
////    @Environment(\.dismiss) private var dismiss
////    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
////
////    var body: some View {
////        ZStack(alignment: .topTrailing) {
////            Map(position: $position) {
////                UserAnnotation()
////                ForEach(friendsDataManager.friends) { friend in
////                    Annotation(
////                        coordinate: CLLocationCoordinate2D(latitude: friend.latitude, longitude: friend.longitude),
////                        content: {
////                            FriendAnnotationView(friend: friend)
////                        },
////                        label: {
////                            Text(friend.full_name)
////                        }
////                    )
////                }
////            }
////            .mapControls {
////                MapUserLocationButton()
////                MapCompass()
////                MapScaleView()
////            }
////            .ignoresSafeArea()
////
////            Button(action: {
////                dismiss()
////            }) {
////                Image(systemName: "xmark")
////                    .foregroundColor(.primary)
////                    .padding()
////                    .background(Color(.systemBackground))
////                    .clipShape(Circle())
////                    .shadow(radius: 2)
////            }
////            .padding()
////        }
////    }
//// }
////
//// struct FriendAnnotationView: View {
////    let friend: Profile
////
////    var body: some View {
////        ZStack {
////            Circle()
////                .fill(Color.white)
////                .frame(width: 40, height: 40)
////
////            Circle()
////                .fill(Color.gray)
////                .frame(width: 34, height: 34)
////
////            Text(String(friend.full_name.prefix(1)))
////                .foregroundColor(.white)
////                .font(.system(size: 20, weight: .bold))
////        }
////        .shadow(radius: 3)
////    }
//// }
////
