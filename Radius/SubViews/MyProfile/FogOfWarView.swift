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
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow

        if let fogOverlay = fogOfWarManager.fogOverlay {
            mapView.addOverlay(fogOverlay)
        }

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        if let existingOverlay = fogOfWarManager.fogOverlay {
            mapView.removeOverlays(mapView.overlays)
            mapView.addOverlay(existingOverlay)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: FogOfWarMapView

        init(_ parent: FogOfWarMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
                renderer.strokeColor = UIColor.clear
                return renderer
            }
            return MKOverlayRenderer()
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.fogOfWarManager.updateFogOverlay()
        }
    }
}

//  FogOfWarContainerView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 10/05/24.

import SwiftUI

struct FogOfWarContainerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var fogOfWarManager = FogOfWarManager()

    var body: some View {
        ZStack {
            FogOfWarMapView(fogOfWarManager: fogOfWarManager)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Uncovered Tiles:")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("\(fogOfWarManager.totalTiles - fogOfWarManager.uncoveredTiles)")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        
                        HStack {
                            Text("Total Tiles:")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("\(fogOfWarManager.totalTiles)")
                                .font(.headline)
                                .foregroundColor(.yellow)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding([.top, .leading], 16)
                
                Spacer()
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
            .padding([.top, .trailing], 16)
        }
    }
}

//
// struct FogOfWarContainerView_Previews: PreviewProvider {
//    static var previews: some View {
//        FogOfWarContainerView()
//    }
// }
