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
                renderer.strokeColor = UIColor.white.withAlphaComponent(0.2)
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

struct FogOfWarContainerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var fogOfWarManager = FogOfWarManager()
    @State private var isStatsExpanded = false

    var body: some View {
        ZStack {
            // Map View
            FogOfWarMapView(fogOfWarManager: fogOfWarManager)
                .edgesIgnoringSafeArea(.all)

            // Top Bar with Close Button and Collapsible Stats
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    // Collapsible Stats Panel
                    StatsCard(
                        fogOfWarManager: fogOfWarManager,
                        isExpanded: $isStatsExpanded
                    )

                    Spacer()

                    // Close Button
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay {
                                        Circle()
                                            .fill(Color.red.opacity(0.7))
                                    }
                            )
                    }
                }
                .padding([.horizontal, .top], 16)

                // Unlock Message
                if let message = fogOfWarManager.uncoverMessage {
                    UnlockMessage(message: message)
                }

                Spacer()
            }
        }
    }
}

private struct StatsCard: View {
    @ObservedObject var fogOfWarManager: FogOfWarManager
    @Binding var isExpanded: Bool

    var percentUnlocked: Double {
        guard fogOfWarManager.totalTiles > 0 else {
            return 0
        }
        return Double(fogOfWarManager.uncoveredTiles) / Double(fogOfWarManager.totalTiles) * 100
    }

    private var springAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0.2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with stable layout
            HStack {
                Text("\(Int(percentUnlocked))% Explored")
                    .font(.headline)
                    .foregroundColor(.white)

                Image(systemName: "chevron.down")
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(springAnimation, value: isExpanded)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(springAnimation) {
                    isExpanded.toggle()
                }
            }

            // Expandable Stats - Modified layout
            VStack(alignment: .leading, spacing: 16) { // Increased spacing
                // Stack items vertically instead of horizontally
                VStack(alignment: .leading, spacing: 16) { // Added vertical layout
                    StatItem(
                        title: "Uncovered",
                        value: "\(fogOfWarManager.uncoveredTiles)",
                        color: .green
                    )

                    StatItem(
                        title: "Total",
                        value: "\(fogOfWarManager.totalTiles)",
                        color: .blue
                    )
                }

                // Progress Bar
                ProgressBar(progress: percentUnlocked / 100)
            }
            .padding(16) // Increased padding
            .frame(width: 160) // Set explicit width
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .frame(maxHeight: isExpanded ? .none : 0)
            .opacity(isExpanded ? 1 : 0)
            .animation(springAnimation, value: isExpanded)
            .clipped()
        }
    }
}

private struct StatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(.headline)
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.2))

                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .green]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: geometry.size.width * CGFloat(progress))
            }
        }
        .frame(height: 4)
        .cornerRadius(2)
    }
}

private struct UnlockMessage: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.6))
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(), value: message)
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
