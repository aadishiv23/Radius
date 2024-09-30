//
//  FogOfWarManager.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/29/24.
//

import Foundation
import MapKit
import CoreLocation

class FogOfWarManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var fogOverlays: [MKOverlay] = []

    private var locationManager = CLLocationManager()
    private var visitedTiles: Set<String> = []

    // Tile size in meters
    private let tileSize: Double = 100.0

    // Maximum distance in meters (25 miles ≈ 40,233.6 meters)
    private let maxDistance: Double = 40233.6

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // High accuracy
        locationManager.distanceFilter = 10 // Update every 10 meters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        loadVisitedTiles()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Determine which tile the user is in
        let tileKey = tileKeyForLocation(location.coordinate)
        if !visitedTiles.contains(tileKey) {
            visitedTiles.insert(tileKey)
            saveVisitedTiles()
            updateFogOverlays()
        }
    }

    private func tileKeyForLocation(_ coordinate: CLLocationCoordinate2D) -> String {
        let x = Int(coordinate.latitude * 1000 / tileSize)
        let y = Int(coordinate.longitude * 1000 / tileSize)
        return "\(x)_\(y)"
    }

    private func updateFogOverlays() {
        // Generate fog overlays for unvisited tiles within 25-mile radius
        var overlays: [MKOverlay] = []

        guard let userLocation = locationManager.location?.coordinate else {
            DispatchQueue.main.async {
                self.fogOverlays = overlays
            }
            return
        }

        let userPoint = MKMapPoint(userLocation)

        // Calculate the range of tiles to consider based on maxDistance
        let tileCount = Int((maxDistance / tileSize).rounded(.up))
        let userTileX = Int(userLocation.latitude * 1000 / tileSize)
        let userTileY = Int(userLocation.longitude * 1000 / tileSize)

        let minX = userTileX - tileCount
        let maxX = userTileX + tileCount
        let minY = userTileY - tileCount
        let maxY = userTileY + tileCount

        for x in minX...maxX {
            for y in minY...maxY {
                let tileCenterCoordinate = coordinateForTileCenter(x: x, y: y)
                let tileCenterPoint = MKMapPoint(tileCenterCoordinate)
                let distance = userPoint.distance(to: tileCenterPoint)

                if distance <= maxDistance {
                    let tileKey = "\(x)_\(y)"
                    if !visitedTiles.contains(tileKey) {
                        // Create overlay for this tile
                        let overlay = overlayForTile(x: x, y: y)
                        overlays.append(overlay)
                    }
                }
            }
        }

        DispatchQueue.main.async {
            self.fogOverlays = overlays
        }
    }

    private func coordinateForTileCenter(x: Int, y: Int) -> CLLocationCoordinate2D {
        let latitude = (Double(x) + 0.5) * tileSize / 1000
        let longitude = (Double(y) + 0.5) * tileSize / 1000
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private func overlayForTile(x: Int, y: Int) -> MKOverlay {
        let latitude = Double(x) * tileSize / 1000
        let longitude = Double(y) * tileSize / 1000

        let topLeft = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let topRight = CLLocationCoordinate2D(latitude: latitude, longitude: longitude + tileSize / 1000)
        let bottomRight = CLLocationCoordinate2D(latitude: latitude + tileSize / 1000, longitude: longitude + tileSize / 1000)
        let bottomLeft = CLLocationCoordinate2D(latitude: latitude + tileSize / 1000, longitude: longitude)

        var coordinates = [topLeft, topRight, bottomRight, bottomLeft]

        let polygon = MKPolygon(coordinates: &coordinates, count: coordinates.count)
        return polygon
    }

    // Persistence Methods
    private func saveVisitedTiles() {
        // Save visitedTiles to persistent storage
        let tilesArray = Array(visitedTiles)
        UserDefaults.standard.set(tilesArray, forKey: "VisitedTiles")
    }

    private func loadVisitedTiles() {
        // Load visitedTiles from persistent storage
        if let tilesArray = UserDefaults.standard.array(forKey: "VisitedTiles") as? [String] {
            visitedTiles = Set(tilesArray)
        }
    }
}
