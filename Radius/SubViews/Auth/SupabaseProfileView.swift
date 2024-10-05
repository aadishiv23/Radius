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
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                        .applyRadiusGlassStyle() // Apply glass style

                    userInfoCard
                        .applyRadiusGlassStyle() // Apply glass style

                    zonesCard
                        .applyRadiusGlassStyle() // Apply glass style

                    actionButtons

                    Spacer()

                    versionInfo
                }
                .padding()
            }
            .background(backgroundGradient)
            // .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    gearButton
                }
            }
        }
        .task {
            await getInitialProfile()
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        ZStack(alignment: .bottomLeading) {
//            // Profile Banner
//            Image("profile-banner")
//                .resizable()
//                .scaledToFill()
//                .frame(height: 150)
//                .clipped()
//                .background(Color(UIColor.secondarySystemBackground))
//                .cornerRadius(15)
//                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

            // Profile Picture and Username
            HStack(alignment: .bottom, spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 5)
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text(fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding([.bottom, .horizontal], 16)
        }
        .padding()
        .cornerRadius(15)
    }

    // MARK: - User Info Card

    private var userInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let currentUser = friendsDataManager.currentUser {
                HStack {
                    Label("Name", systemImage: "person.fill")
                        .font(.headline)
                    Spacer()
                    Text(currentUser.full_name.isEmpty ? "Unknown" : currentUser.full_name)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Label("Username", systemImage: "at")
                        .font(.headline)
                    Spacer()
                    Text(currentUser.username.isEmpty ? "Unavailable" : currentUser.username)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Label("Coordinates", systemImage: "location.fill")
                        .font(.headline)
                    Spacer()
                    Text(
                        currentUser.latitude != 0
                            ? "\(currentUser.latitude), \(currentUser.longitude)"
                            : "No coordinates available"
                    )
                    .foregroundColor(.secondary)
                }

                HStack {
                    Label("Zones", systemImage: "map")
                        .font(.headline)
                    Spacer()
                    Text(currentUser.zones.isEmpty ? "No zones available" : "\(currentUser.zones.count)")
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    ProgressView()
                    Text("Loading user information...")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .cornerRadius(15)
        //.shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Zones Card

    private var zonesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Zones")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: ZoneGridView()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    if let currentUser = friendsDataManager.currentUser {
                        ForEach(currentUser.zones) { zone in
                            ZoneCard(zone: zone)
                                .frame(width: 180) // Ensure ZoneCard has a fixed width
                        }
                    } else {
                        ProgressView()
                    }
                }
                .padding(.vertical, 10)
            }
            .frame(minWidth: 0, maxWidth: .infinity) // Ensure ScrollView takes full width
            .padding(.horizontal, -16) // Remove horizontal padding if necessary
        }
        .padding()
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 15) {
            updateProfileButton
            myProfileButton
            signOutButton
        }
    }

    private var updateProfileButton: some View {
        Button(action: updateProfileButtonTapped) {
            HStack {
                Text("Update Profile")
                    .fontWeight(.semibold)
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                Color.black.opacity(0.7)
            )
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isLoading)
    }

    private var myProfileButton: some View {
        NavigationLink(destination: MyProfileView()) {
            Text("My Profile")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    Color.black.opacity(0.7)
                )
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }

    private var signOutButton: some View {
        Button(action: signOut) {
            Text("Sign Out")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    Color.red.opacity(0.5)
                )
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }

    private func signOut() {
        Task {
            try? await supabase.auth.signOut()
        }
    }

    // MARK: - Version Info

    private var versionInfo: some View {
        Text("v1.0")
            .font(.footnote)
            .foregroundColor(.gray)
            .padding(.top, 10)
    }

    // MARK: - Background Gradient

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.yellow.opacity(0.7)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Gear Button

    private var gearButton: some View {
        NavigationLink(destination: LocationSettingsView()) {
            Image(systemName: "gear.badge")
                .foregroundColor(.primary)
                .font(.title2)
        }
    }

    // MARK: - Data Fetching

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
                    .update(
                        UpdateProfileParams(username: username, fullName: fullName)
                    )
                    .eq("id", value: currentUser.id)
                    .execute()
            } catch {
                debugPrint(error)
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
