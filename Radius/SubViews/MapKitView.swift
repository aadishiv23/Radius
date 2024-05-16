//
//  MapKitView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/25/24.
//

import Foundation
import SwiftUI
import MapKit

struct MapKitView: UIViewRepresentable {
    var friend: FriendLocation
    
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
        let annotation = ColorAnnotation(coordinate: CLLocationCoordinate2D(latitude: friend.latitude, longitude: friend.longitude), color: Color(friend.color))
        mapView.addAnnotation(annotation)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapKitView
        
        init(_ parent: MapKitView) {
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
