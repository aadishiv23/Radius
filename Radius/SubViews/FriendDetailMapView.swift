//
//  MapKitView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/25/24.
//

import Foundation
import SwiftUI
import MapKit

struct FriendDetailMapView: View {
    var friend: Profile
    
    var body: some View {
        
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
                    MapCircle(MKCircle(center: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude), radius: zone.radius))
                        .foregroundStyle(.blue.opacity(0.2))
                        .stroke(Color.blue.opacity(0.5), lineWidth: 5)
                    
                    Annotation(friend.full_name, coordinate: CLLocationCoordinate2D(latitude: friend.latitude, longitude: friend.longitude)) {
                        Circle()
                            .foregroundStyle(LinearGradient(colors: [.red, .pink, .blue], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 20, height: 20)
                            .overlay {
                                Text(friend.full_name.prefix(1))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.white)
                                //RadialGradient(colors: [.blue, .black], center: .center, startRadius: 20, endRadius: 200)

                            }
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
        } else {
            // Fallback on earlier versions
            OldFriendDetailMapView(friend: friend)
        }
        
    }
}

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
            let circle = MKCircle(center: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude), radius: zone.radius)
            mapView.addOverlay(circle)
        }
        
        // Ensure the friend's location is marked
        let annotation = ColorAnnotation(coordinate: CLLocationCoordinate2D(latitude: friend.latitude, longitude: friend.longitude), color: Color(hex: friend.color) ?? .black)
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
            }
            else {
                annotationView?.annotation = annotation
            }
            
            annotationView?.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            annotationView?.layer.cornerRadius = 10
            annotationView?.backgroundColor = UIColor(colorAnnotation.color)
            
            return annotationView
        }
    }
}

// Custom annotation
class ColorAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var color: Color
    
    init(coordinate: CLLocationCoordinate2D, color: Color) {
        self.coordinate = coordinate
        self.color = color
    }
}
