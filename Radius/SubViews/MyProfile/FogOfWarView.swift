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

        // Set initial region to Ann Arbor
        let annArborRegion = MKCoordinateRegion(
            center: FogOfWarConstants.annArborCoordinate,
            latitudinalMeters: FogOfWarConstants.radiusMeters * 2,
            longitudinalMeters: FogOfWarConstants.radiusMeters * 2
        )
        mapView.setRegion(annArborRegion, animated: false)

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
                renderer.fillColor = UIColor.red.withAlphaComponent(0.7)
                renderer.strokeColor = UIColor.white.withAlphaComponent(0.2)

                // Create gradient effect using Core Graphics instead of CAGradientLayer
                let gradientColors = [
                    UIColor.black.withAlphaComponent(0.6),
                    UIColor.black.withAlphaComponent(0.4)
                ]

                renderer.setNeedsDisplay()

                return renderer
            }
            return MKOverlayRenderer()
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // if parent.fogOfWarManager.isWithinBoundary {
            Task { @MainActor in
                parent.fogOfWarManager.updateFogOverlay()
            }
            // }
        }
    }
}

// Preview for SwiftUI
#if DEBUG
struct FogOfWarMapView_Previews: PreviewProvider {
    static var previews: some View {
        FogOfWarMapView(fogOfWarManager: FogOfWarManager())
            .edgesIgnoringSafeArea(.all)
    }
}
#endif

//  FogOfWarContainerView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 10/05/24.

/// FogOfWarContainerView.swift
struct FogOfWarContainerView: View {
    @StateObject var fogOfWarManager = FogOfWarManager()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Map View
            FogOfWarMapView(fogOfWarManager: fogOfWarManager)
                .edgesIgnoringSafeArea(.all)

            // Top and Bottom Overlays
            VStack {
                // Top Row with Dismiss Button
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .background(Color.black.opacity(0.2))
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                }

                Spacer()

                // Stats Overlay
                StatsOverlay(fogOfWarManager: fogOfWarManager)
                    .padding()
                    .animation(.easeInOut(duration: 0.3), value: UUID()) // Use UUID for animation independence
            }
        }
    }
}

struct OutOfBoundsView: View {
    var body: some View {
        Text("Outside Exploration Area")
            .font(.headline)
            .padding()
            .background(.ultraThinMaterial)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
    }
}

struct StatsOverlay: View {
    @ObservedObject var fogOfWarManager: FogOfWarManager
    @State private var isExpanded = false

    var percentExplored: Double {
        guard fogOfWarManager.totalTiles > 0 else { return 0 }
        return Double(fogOfWarManager.uncoveredTiles) / Double(fogOfWarManager.totalTiles) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(Int(percentExplored))% Explored")
                        .font(.headline)
                    Text("Ann Arbor Region")
                        .font(.subheadline)
                }
                .foregroundColor(.white)

                Spacer()

                // Expand Button with Animation
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.up.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }

            // Expandable Stats Section
            if isExpanded {
                VStack(spacing: 8) {
                    StatRow(
                        title: "Tiles Uncovered",
                        value: fogOfWarManager.uncoveredTiles,
                        total: fogOfWarManager.totalTiles
                    )

                    ProgressView(value: percentExplored, total: 100)
                        .tint(.blue)
                        .progressViewStyle(.linear)
                        .scaleEffect(1.05)
                        .animation(.easeInOut(duration: 0.3), value: percentExplored)
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}


struct StatRow: View {
    let title: String
    let value: Int
    let total: Int

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Text("\(value)/\(total)")
                .foregroundColor(.white)
                .fontWeight(.bold)
        }
    }
}

// #Preview {
//    FogOfWarContainerView()
// }

//
// struct FogOfWarContainerView_Previews: PreviewProvider {
//    static var previews: some View {
//        FogOfWarContainerView()
//    }
// }
