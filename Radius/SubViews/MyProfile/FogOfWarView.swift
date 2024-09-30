//
//  FogOfWarView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/29/24.
//

import CoreLocation
import Foundation
import MapKit
import SwiftUI

struct FogOfWarMapView: UIViewRepresentable {
    @ObservedObject var fogOfWarManager: FogOfWarManager

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // Show user location
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow

        // Add overlays
        mapView.addOverlays(fogOfWarManager.fogOverlays)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update overlays when fogOverlays changes
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlays(fogOfWarManager.fogOverlays)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: FogOfWarMapView

        init(_ parent: FogOfWarMapView) {
            self.parent = parent
        }

        /// Render overlays
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                let renderer = MKTileOverlayRenderer(tileOverlay: tileOverlay)
                return renderer
            } else if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.5)
                renderer.strokeColor = UIColor.clear
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
