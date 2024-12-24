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
    @State private var selectedFriend: Profile?
    @State private var isFriendSelectionExpanded = false

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

            // Friend Selection Section with Dismissal Area
            ZStack {
                if isFriendSelectionExpanded {
                    // Full-screen dismissal area
                    Color.black.opacity(0.001) // Nearly invisible but catchable for touches
                        .onTapGesture {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                isFriendSelectionExpanded = false
                            }
                        }
                }
                
                VStack(spacing: 0) {
                    Spacer()

                    // Container for morphing animation
                    ZStack {
                        // Base morphing shape
                        MorphingShape(progress: isFriendSelectionExpanded ? 1 : 0)
                            .fill(Color.gray.opacity(0.8))
                            .frame(height: 140)
                            .shadow(radius: 3)

                        // Friend selection content
                        if isFriendSelectionExpanded {
                            FriendSelectionView(
                                friends: friendsDataManager.friends.filter { $0.id != friendsDataManager.currentUser?.id },
                                selectedFriend: $selectedFriend,
                                onSelect: selectFriend
                            )
                            .padding(.vertical, 10)
                            .opacity(isFriendSelectionExpanded ? 1 : 0)
                        }

                        // Chevron button with tap area
                        VStack {
                            Image(systemName: "chevron.up")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .bold))
                                .rotationEffect(.degrees(isFriendSelectionExpanded ? 180 : 0))
                                .frame(width: 50, height: 50) // Increased tap area
                                .contentShape(Rectangle()) // Makes entire frame tappable
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        toggleFriendSelection()
                                    }
                                }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .offset(
                            x: isFriendSelectionExpanded ? -(UIScreen.main.bounds.width * 0.9 / 2 - 25) : 0,
                            y: isFriendSelectionExpanded ? -50 : 0
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .gesture(
                        DragGesture(minimumDistance: 5)
                            .onEnded { gesture in
                                if gesture.translation.height > 50 && isFriendSelectionExpanded {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        isFriendSelectionExpanded = false
                                    }
                                } else if gesture.translation.height < -50 && !isFriendSelectionExpanded {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        isFriendSelectionExpanded = true
                                    }
                                }
                            }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }

    private func toggleFriendSelection() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
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
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    /// Defines the path for the shape
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - FriendSelectionView

struct FriendSelectionView: View {
    let friends: [Profile]
    @Binding var selectedFriend: Profile?
    var onSelect: (Profile) -> Void

    let itemWidth: CGFloat = 70 // Set a fixed width for each item

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(friends) { friend in
                    Button(action: {
                        onSelect(friend)
                    }) {
                        VStack(spacing: 8) { // Adjust spacing between elements
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
                                .lineLimit(1) // Limit to one line
                                .truncationMode(.tail) // Truncate if the name is too long
                                .frame(width: itemWidth - 10) // Adjust width to fit within the item
                                .multilineTextAlignment(.center) // Center align the text
                        }
                        .frame(width: itemWidth) // Set fixed width for each item
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            .frame(height: 120)
        }
    }
}

/// First, let's create a custom shape that can morph between circle and rectangle
struct MorphingShape: Shape {
    var progress: CGFloat // 0 = circle, 1 = rectangle

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Calculate corner radius (interpolate between circle and rectangle)
        let cornerRadius = 25 * (1 - progress) + 16 * progress

        // Calculate width (interpolate between circle width and rectangle width)
        let currentWidth = 50 * (1 - progress) + (UIScreen.main.bounds.width * 0.9) * progress

        // Calculate height (interpolate between circle height and rectangle height)
        let currentHeight = 50 * (1 - progress) + 140 * progress // Increased from 50 to 140 for expanded state

        // Center the shape
        let xOffset = (width - currentWidth) / 2
        let yOffset = (height - currentHeight) / 2

        let rect = CGRect(x: xOffset, y: yOffset, width: currentWidth, height: currentHeight)
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))

        return path
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
