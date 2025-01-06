//
//  MapViewSnapshot.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on [Current Date]
//

import SwiftUI
import MapKit

// MARK: - MapView Snapshot

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
        
        let circle = MKCircle(center: coordinate, radius: radius)
        view.addOverlay(circle)
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
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = UIColor.blue.withAlphaComponent(0.1)
            return renderer
        }
    }
}
