//
//  FogOfWarManager.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/29/24.
//

import CoreLocation
import Foundation
import MapKit

class FogOfWarManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var fogOverlay: MKOverlay?
    @Published var totalTiles = 0
    @Published var uncoveredTiles = 0
    @Published var uncoverMessage: String?

    private var locationManager = CLLocationManager()
    private var visitedRegions: [String: TileRegion] = [:]
    private let visitedRegionsQueue = DispatchQueue(label: "visitedRegionsQueue", attributes: .concurrent)

    // Constants for tile and region management
    private let tileSizeMeters = 100.0
    private let viewportRadius = 10000.0  // Radius around user for rendering
    
    // Structure to represent a tile region
    private struct TileRegion {
        let bounds: MKCoordinateRegion
        let key: String
        let timestamp: Date
        
        init(coordinate: CLLocationCoordinate2D, tileSizeMeters: Double, key: String) {
            // Calculate region bounds based on tile size
            let latitudeDelta = tileSizeMeters / 111000.0
            let longitudeDelta = tileSizeMeters / (111000.0 * cos(coordinate.latitude * .pi / 180))
            
            self.bounds = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: latitudeDelta,
                    longitudeDelta: longitudeDelta
                )
            )
            self.key = key
            self.timestamp = Date()
        }
        
        func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
            let region = bounds
            let latInRange = coordinate.latitude >= (region.center.latitude - region.span.latitudeDelta/2) &&
                           coordinate.latitude <= (region.center.latitude + region.span.latitudeDelta/2)
            let lonInRange = coordinate.longitude >= (region.center.longitude - region.span.longitudeDelta/2) &&
                           coordinate.longitude <= (region.center.longitude + region.span.longitudeDelta/2)
            return latInRange && lonInRange
        }
    }

    override init() {
        super.init()
        locationManager.delegate = self
        applyLocationAccuracySettings()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        loadVisitedRegions()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = location.coordinate
        
        // Check if the current location is in any existing regions
        let regionKey = generateRegionKey(for: coordinate)
        if !isRegionVisited(coordinate) {
            addVisitedRegion(coordinate, key: regionKey)
            showUncoverMessage()
        }
        
        updateFogOverlay()
    }

    private func generateRegionKey(for coordinate: CLLocationCoordinate2D) -> String {
        let latitudeDegree = tileSizeMeters / 111000.0
        let longitudeDegree = tileSizeMeters / (111000.0 * cos(coordinate.latitude * .pi / 180))
        
        let x = Int((coordinate.latitude / latitudeDegree).rounded())
        let y = Int((coordinate.longitude / longitudeDegree).rounded())
        return "\(x)_\(y)"
    }

    private func isRegionVisited(_ coordinate: CLLocationCoordinate2D) -> Bool {
        visitedRegionsQueue.sync {
            for region in visitedRegions.values {
                if region.contains(coordinate) {
                    return true
                }
            }
            return false
        }
    }

    private func addVisitedRegion(_ coordinate: CLLocationCoordinate2D, key: String) {
        let region = TileRegion(coordinate: coordinate, tileSizeMeters: tileSizeMeters, key: key)
        visitedRegionsQueue.async(flags: .barrier) {
            self.visitedRegions[key] = region
        }
        saveVisitedRegions()
    }

    func updateFogOverlay() {
        guard let userLocation = locationManager.location?.coordinate else { return }
        
        // Create the viewport region around the user
        let viewportRegion = MKCoordinateRegion(
            center: userLocation,
            latitudinalMeters: viewportRadius * 2,
            longitudinalMeters: viewportRadius * 2
        )
        
        // Get regions within the viewport
        let visibleRegions = visitedRegionsQueue.sync {
            visitedRegions.values.filter { region in
                isRegion(region.bounds, intersectingWith: viewportRegion)
            }
        }
        
        // Create the fog polygon with holes for visited regions
        let fogPolygon = createFogPolygon(
            around: userLocation,
            withHoles: visibleRegions.map { $0.bounds }
        )
        
        DispatchQueue.main.async {
            self.fogOverlay = fogPolygon
            self.totalTiles = self.calculateTotalTilesInViewport()
            self.uncoveredTiles = visibleRegions.count
        }
    }

    private func createFogPolygon(
        around coordinate: CLLocationCoordinate2D,
        withHoles regions: [MKCoordinateRegion]
    ) -> MKPolygon {
        // Create outer boundary of fog (viewport rectangle)
        let latDelta = viewportRadius / 111000.0
        let lonDelta = viewportRadius / (111000.0 * cos(coordinate.latitude * .pi / 180))
        
        let outerCoordinates = [
            CLLocationCoordinate2D(
                latitude: coordinate.latitude - latDelta,
                longitude: coordinate.longitude - lonDelta
            ),
            CLLocationCoordinate2D(
                latitude: coordinate.latitude - latDelta,
                longitude: coordinate.longitude + lonDelta
            ),
            CLLocationCoordinate2D(
                latitude: coordinate.latitude + latDelta,
                longitude: coordinate.longitude + lonDelta
            ),
            CLLocationCoordinate2D(
                latitude: coordinate.latitude + latDelta,
                longitude: coordinate.longitude - lonDelta
            )
        ]
        
        // Create holes for visited regions
        let holes = regions.map { region -> MKPolygon in
            let coords = [
                CLLocationCoordinate2D(
                    latitude: region.center.latitude - region.span.latitudeDelta/2,
                    longitude: region.center.longitude - region.span.longitudeDelta/2
                ),
                CLLocationCoordinate2D(
                    latitude: region.center.latitude - region.span.latitudeDelta/2,
                    longitude: region.center.longitude + region.span.longitudeDelta/2
                ),
                CLLocationCoordinate2D(
                    latitude: region.center.latitude + region.span.latitudeDelta/2,
                    longitude: region.center.longitude + region.span.longitudeDelta/2
                ),
                CLLocationCoordinate2D(
                    latitude: region.center.latitude + region.span.latitudeDelta/2,
                    longitude: region.center.longitude - region.span.longitudeDelta/2
                )
            ]
            return MKPolygon(coordinates: coords, count: coords.count)
        }
        
        return MKPolygon(
            coordinates: outerCoordinates,
            count: outerCoordinates.count,
            interiorPolygons: holes
        )
    }

    private func isRegion(_ region1: MKCoordinateRegion, intersectingWith region2: MKCoordinateRegion) -> Bool {
        let lat1 = region1.center.latitude
        let lon1 = region1.center.longitude
        let lat2 = region2.center.latitude
        let lon2 = region2.center.longitude
        
        let latOverlap = abs(lat1 - lat2) <= (region1.span.latitudeDelta/2 + region2.span.latitudeDelta/2)
        let lonOverlap = abs(lon1 - lon2) <= (region1.span.longitudeDelta/2 + region2.span.longitudeDelta/2)
        
        return latOverlap && lonOverlap
    }

    private func calculateTotalTilesInViewport() -> Int {
        let tilesPerSide = Int(ceil(viewportRadius * 2 / tileSizeMeters))
        return tilesPerSide * tilesPerSide
    }

    private func saveVisitedRegions() {
        visitedRegionsQueue.sync {
            let regionData = visitedRegions.mapValues { region -> [String: Any] in
                return [
                    "key": region.key,
                    "latitude": region.bounds.center.latitude,
                    "longitude": region.bounds.center.longitude,
                    "timestamp": region.timestamp
                ]
            }
            UserDefaults.standard.set(regionData, forKey: "VisitedRegions")
        }
    }

    private func loadVisitedRegions() {
        if let savedRegions = UserDefaults.standard.dictionary(forKey: "VisitedRegions") as? [String: [String: Any]] {
            var loadedRegions: [String: TileRegion] = [:]
            
            for (key, data) in savedRegions {
                if let latitude = data["latitude"] as? Double,
                   let longitude = data["longitude"] as? Double {
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    loadedRegions[key] = TileRegion(
                        coordinate: coordinate,
                        tileSizeMeters: tileSizeMeters,
                        key: key
                    )
                }
            }
            
            visitedRegionsQueue.async(flags: .barrier) {
                self.visitedRegions = loadedRegions
            }
        }
    }

    private func showUncoverMessage() {
        DispatchQueue.main.async {
            self.uncoverMessage = "New area uncovered!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.uncoverMessage = nil
            }
        }
    }

    private func applyLocationAccuracySettings() {
        switch LocationManager.shared.accuracyMode {
        case .highAccuracy:
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.distanceFilter = 25
        case .balanced:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = 100
        case .lowPower:
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            locationManager.distanceFilter = 500
        }
    }
}
