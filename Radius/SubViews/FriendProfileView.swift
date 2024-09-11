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
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.yellow.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    friendInfoSection // Name, Username, Coordinates, Number of Zones
                        .visionGlass()
                    
                    zonesSection // List of Zones
                        .visionGlass()
                }
                .padding(.top, 40)
            }
        }
        .navigationTitle(friend.full_name)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }, label: {
                    Label("Back", systemImage: "arrow.backward")
                })
            }
        }
    }
    
    // Friend's Name, Username, Coordinates, and Number of Zones
    private var friendInfoSection: some View {
        VStack(spacing: 10) {
            Text("Name: \(friend.full_name)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Username: \(friend.username)")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Coordinates: \(friend.latitude), \(friend.longitude)")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Number of Zones: \(friend.zones.count)")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
    
    // List of Zones with modified Polaroid Card
    private var zonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Zones")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(friend.zones) { zone in
                        PolaroidCard(zone: zone)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
            }
        }
        .padding()
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
        VStack(spacing: 0) {
            MapViewForPolaroid(coordinate: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude), radius: zone.radius)
                .frame(width: 165, height: 165)  // Slightly wider and taller
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white, lineWidth: 2)
                )
            
            VStack {
                Text("\(zone.name)")
                    .font(.headline)
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .padding(.vertical, 5)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
        .padding(5)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        .frame(width: 180, height: 200)  // Adjusted frame to make the card taller and wider
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

#Preview {
    PolaroidCard(zone: Zone(
        id: UUID(),
        name: "Central Park",
        latitude: 40.785091,
        longitude: -73.968285,
        radius: 500,
        profile_id: UUID()
    ))
//    struct PolaroidCard_Previews: PreviewProvider {
//        static var previews: some View {
//            PolaroidCard(zone: Zone(
//                id: UUID(),
//                name: "Central Park",
//                latitude: 40.785091,
//                longitude: -73.968285,
//                radius: 500
//            ))
//            .previewLayout(.sizeThatFits)
//            .padding(10)
//            .background(Color.gray.edgesIgnoringSafeArea(.all))
//        }
//    }
}
