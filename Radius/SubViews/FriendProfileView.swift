//
//  FriendProfileView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/25/24.
//

import Foundation
import SwiftUI
import MapKit

// Define a simple profile view for displaying friend details
struct FriendProfileView: View {
    var friend: Profile
    @State private var editingZoneId: UUID? = nil
    @State private var zoneName: String = ""
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @State private var iconTapped: Bool = false
    @State private var rotationAngle: Double = 0


    var body: some View {
        ScrollView(showsIndicators: false) {
            Spacer().frame(height: 20)
            VStack {
                ZStack {
                   Circle()
                       .foregroundStyle(LinearGradient(colors: [.red, .pink, .blue], startPoint: .leading, endPoint: .trailing))
                       .frame(width: iconTapped ? 100 : 60, height: iconTapped ? 100 : 60)
                       .rotationEffect(.degrees(rotationAngle))
                       .onTapGesture {
                           withAnimation(.spring()) {
                               iconTapped.toggle()
                               rotationAngle += 360
                           }
                       }
                   Text(friend.full_name.prefix(1))
                       .font(.largeTitle)
                       .fontWeight(.bold)
                       .foregroundStyle(Color.white)
                       .shadow(radius: iconTapped ? 10 : 5)
               }
            }
            .frame(maxWidth: .infinity)
            Text("Coordinates: \(friend.latitude), \(friend.longitude)")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
            
//            ScrollView(.horizontal, showsIndicators: false) {
//                LazyHStack {
//                    ForEach(0..<10) { i in
//                        RoundedRectangle(cornerRadius: 25)
//                            .fill(Color(hue: Double(i) / 10, saturation: 1, brightness: 1).gradient)
//                            .frame(width: 300, height: 100)
//                    }
//                }
//                .scrollTargetLayout()
//            }
//            .scrollTargetBehavior(.viewAligned)
//            .safeAreaPadding(.horizontal, 40)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ProfileCard(title: "Username", value: friend.username)
                    ProfileCard(title: "Full Name", value: friend.full_name)
                    ProfileCard(title: "Phone Number", value: friend.phone_num)
                    ProfileCard(title: "Zones", value: "\(friend.zones.count)")
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .safeAreaPadding(.horizontal, 40)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    ForEach(friend.zones) { zone in
                        PolaroidCard(zone: zone)
                            .padding(.vertical, 10)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .safeAreaPadding(.horizontal, 40)
            
            NavigationLink(destination: FriendDetailMapView(friend: friend)) {
                ZStack(alignment: .center) {
                    Rectangle()
                        .background(Color(hue: Double(6) / 10, saturation: 1, brightness: 1).gradient)
                        .frame(width: 275, height: 275)
                        .cornerRadius(25)
                        .shadow(radius: 5)
                    Map(initialPosition: MapCameraPosition.automatic)
                        .frame(width: 250, height: 250)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
            }
//            ForEach(friend.zones) { zone in
//                VStack {
//                    if editingZoneId == zone.id {
//                        TextField("Zone name", text: $zoneName)
//                            .onSubmit {
//                                Task {
//                                    do {
//                                        try await friendsDataManager.renameZone(zoneId: zone.id, newName: zoneName)
//                                        // Refresh friend profile data here or use an observable object to trigger a view update.
//                                        editingZoneId = nil // Exit editing mode after saving.
//                                    } catch {
//                                        print("Failed to rename zone")
//                                    }
//                                }
//                            }
//                            .onAppear {
//                                zoneName = zone.name
//                            }
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .padding()
//                            .background(
//                                RoundedRectangle(cornerRadius: 10)
//                                    .stroke(LinearGradient(gradient: Gradient(colors: [.pink, .blue]), startPoint: .leading, endPoint: .trailing), lineWidth: 2)
//                                    .padding(-5)
//                                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
//                            )
//                    } else {
//                        Text(zone.name)
//                            .onTapGesture {
//                                editingZoneId = zone.id
//                                zoneName = zone.name
//                            }
//                    }
//                    Text(String(zone.latitude))
//                    Text(String(zone.longitude))
//                    Text(String(zone.radius))
//                }
//                .background(
//                    RoundedRectangle(cornerRadius: 10)
//                        .foregroundStyle(.blue)
//                        .opacity(0.3)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 10)
//                                .stroke(LinearGradient(gradient: Gradient(colors: [.pink, .blue]), startPoint: .leading, endPoint: .trailing), lineWidth: 2)
//                                .opacity(editingZoneId == zone.id ? 1 : 0)
//                                .animation(.easeInOut, value: editingZoneId)
//                        )
//                )
//                .padding(.vertical, 5)
//            }
//            Spacer()
        }
        //.padding()
        .navigationTitle(friend.full_name)
    }
}

struct ProfileCard: View {
    var title: String
    var value: String

    var body: some View {
        VStack {
            Text(title)
                .foregroundColor(.white)
                .font(.headline)
            Text(value)
                .foregroundColor(.white)
                .font(.subheadline)
        }
        .frame(width: 300, height: 100)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.green.opacity(0.3)]), startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(25)
        .shadow(radius: 5)
    }
}

struct PolaroidCard: View {
    var zone: Zone
    
    var body: some View {
        VStack {
            MapViewForPolaroid(coordinate: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude), radius: zone.radius)
                .frame(height: 150)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white, lineWidth: 4)
                )
            
            VStack {
                Text("\(zone.name)")
                    .font(.footnote)
                    .padding(.top, 5)
                    .padding(.bottom, 10)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
//            .cornerRadius(10)
//            .shadow(radius: 5)
        }
        .frame(width: 200)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct MapViewForPolaroid: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D
    var radius: CLLocationDistance

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        view.setRegion(region, animated: true)
        
        // Remove existing overlays to avoid duplication
        view.removeOverlays(view.overlays)
        
        // Add a circle overlay to represent the zone
        let circle = MKCircle(center: coordinate, radius: radius)
        view.addOverlay(circle)
        
        view.delegate = context.coordinator
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewForPolaroid

        init(_ parent: MapViewForPolaroid) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circleOverlay = overlay as? MKCircle {
                let renderer = MKCircleRenderer(overlay: circleOverlay)
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}



struct CardGradientView: View {
    @State var rotation: CGFloat = 0.0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .frame(width: 260, height: 340)
                .foregroundColor(.black.opacity(0.9))
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .frame(width: 130, height: 500)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.red, Color.purple]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(rotation))
                .mask {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(lineWidth: 7)
                        .frame(width: 256, height: 336)
                }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        
    }
}

struct CardGradientViewV2: View {
    @State var rotation: CGFloat = 0.0

    var body: some View {
        ZStack {
            Color(.gray)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .frame(width: 440, height: 430)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(rotation))
                .mask {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(lineWidth: 10)
                        .frame(width: 250, height: 335)
                        .blur(radius: 5)
                }
            
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .frame(width: 260, height: 340)
                .foregroundColor(.black)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .frame(width: 500, height: 440)
                .rotationEffect(.degrees(rotation))
                .mask {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(lineWidth: 10)
                        .frame(width: 250, height: 336)
                }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        
    }
}
