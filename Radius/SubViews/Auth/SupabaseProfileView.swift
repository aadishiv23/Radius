//
//  SupabaseProfileView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/8/24.
//

import CoreLocation
import Foundation
import MapKit
import Supabase
import SwiftUI

struct SupabaseProfileView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @State private var username = ""
    @State private var fullName = ""
    @State private var website = ""
    @State private var isLoading = false
    @State private var currentUserZones: [Zone] = []
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                AnimatedGradientBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        ProfileHeader(fullName: fullName, username: username)
                            .padding(.top)
                        
                        // Stats View
                        if let currentUser = friendsDataManager.currentUser {
                            StatsView(user: currentUser)
                        }
                        
                        // User Info Card
                        UserInfoCard(currentUser: friendsDataManager.currentUser)
                        
                        // Zones Section
                        ZonesSection(currentUser: friendsDataManager.currentUser)
                        
                        // Action Buttons
                        ActionButtonsGroup(
                            isLoading: $isLoading,
                            updateProfile: updateProfileButtonTapped,
                            signOut: signOut
                        )
                        
                        // Version Info
                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 8)
                    }
                    .padding()
                }
            }
            //.background(backgroundGradient)
            //.navigationBarHidden(true)
            //             .navigationBarTitleDisplayMode(.inline)

            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: LocationSettingsView()) {
                        Image(systemName: "gear.badge")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .task {
            await getInitialProfile()
        }
    }
    
    // MARK: - Data Methods
    func getInitialProfile() async {
        do {
            let currentUser = try await supabase.auth.session.user
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: currentUser.id)
                .single()
                .execute()
                .value
            
            username = profile.username
            fullName = profile.full_name
        } catch {
            debugPrint(error)
        }
    }
    
    func updateProfileButtonTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let currentUser = try await supabase.auth.session.user
                try await supabase
                    .from("profiles")
                    .update(UpdateProfileParams(username: username, fullName: fullName))
                    .eq("id", value: currentUser.id)
                    .execute()
            } catch {
                debugPrint(error)
            }
        }
    }
    
    func signOut() {
        Task {
            try? await supabase.auth.signOut()
        }
    }
}

// MARK: - Supporting Views
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.7),
                Color.purple.opacity(0.5),
                Color.orange.opacity(0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .hueRotation(.degrees(animateGradient ? 45 : 0))
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct ProfileHeader: View {
    let fullName: String
    let username: String
    
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 110, height: 110)
                    )
                    .shadow(radius: 10)
                
                VStack(spacing: 8) {
                    Text(fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            Spacer()
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct StatsView: View {
    let user: Profile
    
    var body: some View {
        HStack(spacing: 20) {
            ProfileStatItem(title: "Zones", value: "\(user.zones.count)", icon: "map.fill")
            ProfileStatItem(title: "Friends", value: "0", icon: "person.2.fill")
            ProfileStatItem(title: "Active", value: "Yes", icon: "circle.fill")
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct ProfileStatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

struct UserInfoCard: View {
    let currentUser: Profile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let user = currentUser {
                InfoRow(title: "Name", value: user.full_name.isEmpty ? "Unknown" : user.full_name, icon: "person.fill")
                InfoRow(title: "Username", value: user.username.isEmpty ? "Unavailable" : user.username, icon: "at")
                InfoRow(title: "Location", value: user.latitude != 0 ? "\(user.latitude), \(user.longitude)" : "No location", icon: "location.fill")
            } else {
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Loading user information...")
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct ZonesSection: View {
    let currentUser: Profile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Zones")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: ZoneGridView()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if let user = currentUser {
                        ForEach(user.zones) { zone in
                            ZoneCard(zone: zone)
                        }
                    } else {
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct EnhancedZoneCard: View {
    var zone: Zone
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MapViewSnapshot(coordinate: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude), radius: zone.radius)
                .frame(width: 200, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
            
            Text(zone.name)
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Label("\(Int(zone.radius))m", systemImage: "ruler")
                Spacer()
                Label("Active", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .frame(width: 200)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ActionButtonsGroup: View {
    @Binding var isLoading: Bool
    let updateProfile: () -> Void
    let signOut: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: updateProfile) {
                HStack {
                    Text("Update Profile")
                        .fontWeight(.semibold)
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading)
            
            NavigationLink(destination: MyProfileView()) {
                Text("My Profile")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Button(action: signOut) {
                Text("Sign Out")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.3))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - ProfileTextField Component

struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 30)

            TextField(title, text: $text)
                .textContentType(title == "Full Name" ? .name : .username)
                .autocapitalization(title == "Full Name" ? .words : .none)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ZoneCard: View {
    var zone: Zone

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Map Snapshot
            MapViewSnapshot(
                coordinate: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude),
                radius: zone.radius
            )
            .frame(height: 100)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 1)
            )
            .shadow(radius: 3)

            // Zone Name
            Text(zone.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)

            // Zone Details
            HStack(spacing: 5) {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                Text("Radius: \(zone.radius)m")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 5) {
                Image(systemName: "map")
                    .foregroundColor(.green)
                Text(String(format: "Lat: %.4f, Lon: %.4f", zone.latitude, zone.longitude))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        .frame(width: 180)
    }
}

struct MapViewSnapshot: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D
    var radius: CLLocationDistance

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = false
        mapView.layer.cornerRadius = 10
        mapView.clipsToBounds = true
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )
        view.setRegion(region, animated: false)

        // Remove existing annotations and overlays
        view.removeAnnotations(view.annotations)
        view.removeOverlays(view.overlays)

        // Add a circle overlay to represent the zone
        let circle = MKCircle(center: coordinate, radius: radius)
        view.addOverlay(circle)

        // Add a pin annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        view.addAnnotation(annotation)

        view.delegate = context.coordinator
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewSnapshot

        init(_ parent: MapViewSnapshot) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circleOverlay = overlay as? MKCircle {
                let renderer = MKCircleRenderer(overlay: circleOverlay)
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.1)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKPointAnnotation {
                let identifier = "ZoneCenter"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = false
                } else {
                    annotationView?.annotation = annotation
                }

                return annotationView
            }
            return nil
        }
    }
}
