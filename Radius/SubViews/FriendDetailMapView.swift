//
//  MapKitView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/25/24.
//

import Foundation
import MapKit
import SwiftUI

struct FriendDetailMapView: View {
    var friend: Profile
    @State private var showOverlay = false
    @State private var currentZoneIndex = 0

    var body: some View {
        ZStack {
            if #available(iOS 17.0, *) {
                Map(
                    initialPosition: MapCameraPosition.automatic,
                    bounds: MapCameraBounds(centerCoordinateBounds: MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: friend.latitude, longitude: friend.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    )),
                    interactionModes: MapInteractionModes.all
                ) {
                    ForEach(friend.zones) { zone in
                        MapCircle(MKCircle(
                            center: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude),
                            radius: zone.radius
                        ))
                        .foregroundStyle(.blue.opacity(0.2))
                        .stroke(Color.blue.opacity(0.5), lineWidth: 5)
                    }

                    Annotation(
                        friend.full_name,
                        coordinate: CLLocationCoordinate2D(latitude: friend.latitude, longitude: friend.longitude)
                    ) {
                        Circle()
                            .foregroundStyle(LinearGradient(
                                colors: [.red, .pink, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: 20, height: 20)
                            .overlay {
                                Text(friend.full_name.prefix(1))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.white)
                                // RadialGradient(colors: [.blue, .black], center: .center, startRadius: 20, endRadius: 200)
                            }
                            .onTapGesture {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5)) {
                                    showOverlay.toggle()
                                }
                            }
                    }
                }
                .mapStyle(.standard(pointsOfInterest: .excludingAll))
            } else {
                // Fallback on earlier versions
                OldFriendDetailMapView(friend: friend)
            }

//            if showOverlay {
//                SwipeableOverlay(friend: friend, currentZoneIndex: $currentZoneIndex)
//                    .transition(.move(edge: .bottom))
//                    .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5))
//            }
            if showOverlay {
                VStack {
                    Spacer()

                    Text(friend.full_name)
                        .font(.title)
                        .padding()
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.9)
                        .background(Color.white.opacity(0.8))
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.bottom, 25)
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5), value: showOverlay)
            }
        }
        .onAppear {
            print("Zones for friend \(friend.full_name): \(friend.zones)")
        }
    }
}

// struct SwipeableOverlay: View {
//    var friend: Profile
//    @Binding var currentZoneIndex: Int
//    @State private var translation: CGFloat = 0
//
//    var body: some View {
//        VStack {
//            Spacer()
//
//            Text("Zone \(currentZoneIndex + 1): \(friend.zones[currentZoneIndex].name ?? "Unnamed")")
//                .font(.title)
//                .padding()
//                .frame(maxWidth: UIScreen.main.bounds.width * 0.9)
//                .background(Color.white.opacity(0.8))
//                .foregroundColor(.black)
//                .cornerRadius(10)
//                .shadow(radius: 5)
//                .padding(.bottom, 25)
//                .offset(x: translation)
//                .gesture(
//                    DragGesture()
//                        .onChanged { value in
//                            self.translation = value.translation.width
//                        }
//                        .onEnded { value in
//                            let threshold: CGFloat = 50
//                            if value.translation.width < -threshold {
//                                withAnimation(.spring()) {
//                                    currentZoneIndex = (currentZoneIndex + 1) % friend.zones.count
//                                    translation = 0
//                                }
//                            } else if value.translation.width > threshold {
//                                withAnimation(.spring()) {
//                                    currentZoneIndex = (currentZoneIndex - 1 + friend.zones.count) %
//                                    friend.zones.count
//                                    translation = 0
//                                }
//                            } else {
//                                withAnimation(.spring()) {
//                                    translation = 0
//                                }
//                            }
//                        }
//                )
//        }
//    }
// }

struct OldFriendDetailMapView: UIViewRepresentable {
    var friend: Profile

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsScale = true
        mapView.showsCompass = false
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: friend.latitude, longitude: friend.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        mapView.setRegion(region, animated: true)

        // Clear existing overlays
        mapView.removeOverlays(mapView.overlays)

        // Add new overlays for each zone
        for zone in friend.zones {
            let circle = MKCircle(
                center: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude),
                radius: zone.radius
            )
            mapView.addOverlay(circle)
        }

        // Ensure the friend's location is marked
        let annotation = ColorAnnotation(
            coordinate: CLLocationCoordinate2D(latitude: friend.latitude, longitude: friend.longitude),
            color: Color(hex: friend.color) ?? .black
        )
        mapView.addAnnotation(annotation)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: OldFriendDetailMapView

        init(_ parent: OldFriendDetailMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circleOverlay = overlay as? MKCircle {
                let circleRenderer = MKCircleRenderer(circle: circleOverlay)
                circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.1)
                circleRenderer.strokeColor = .blue
                circleRenderer.lineWidth = 2
                return circleRenderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            guard let colorAnnotation = annotation as? ColorAnnotation else {
                return nil
            }

            let identifier = "ColorAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }

            annotationView?.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            annotationView?.layer.cornerRadius = 10
            annotationView?.backgroundColor = UIColor(colorAnnotation.color)

            return annotationView
        }
    }
}

/// Custom annotation
class ColorAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var color: Color

    init(coordinate: CLLocationCoordinate2D, color: Color) {
        self.coordinate = coordinate
        self.color = color
    }
}
