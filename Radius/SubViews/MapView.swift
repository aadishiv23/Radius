//
//  MapView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/28/24.
//

import Foundation
import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var location: CLLocationCoordinate2D?
    @Binding var radius: Double
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: true)
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
        if let location = location {
            // Remove existing annotations and overlays
            uiView.removeAnnotations(uiView.annotations)
            uiView.removeOverlays(uiView.overlays)
            
            // Add new annotation and overlay for the zone
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            uiView.addAnnotation(annotation)
            
            let circle = MKCircle(center: location, radius: radius)
            uiView.addOverlay(circle)
            
            context.coordinator.adjustMapView(uiView, forLocation: location, withRadius: radius)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }
        
        @objc func handleTap( _ gestureRecognizer: UITapGestureRecognizer) {
            let location = gestureRecognizer.location(in: gestureRecognizer.view)
            if let mapView = gestureRecognizer.view as? MKMapView {
                let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
                parent.location = coordinate
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circleOverlay = overlay as? MKCircle {
                let circleRenderer = MKCircleRenderer(overlay: circleOverlay)
                circleRenderer.strokeColor = .blue
                circleRenderer.fillColor = .blue.withAlphaComponent(0.5)
                circleRenderer.lineWidth = 1
                
                circleRenderer.alpha = 0
                UIView.animate(withDuration: 0.25) {
                    circleRenderer.alpha = 1
                }
                return circleRenderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func adjustMapView(_ mapView: MKMapView, forLocation location: CLLocationCoordinate2D, withRadius radius: CLLocationDistance) {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: radius * 2.5, longitudinalMeters: radius * 2.5)
            mapView.setRegion(region, animated: true)
        }
    }
}
