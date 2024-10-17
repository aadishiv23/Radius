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

    private var locationManager = CLLocationManager()
    private var visitedTiles: Set<String> = []

    private let tileSizeMeters = 100.0
    private let maxDistance = 1609.0

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        loadVisitedTiles()
        updateFogOverlay()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }

        let tileKey = tileKeyForLocation(location.coordinate)
        if !visitedTiles.contains(tileKey) {
            visitedTiles.insert(tileKey)
            saveVisitedTiles()
            updateFogOverlay()
        }
    }

    private func tileKeyForLocation(_ coordinate: CLLocationCoordinate2D) -> String {
        let latitudeDegree = tileSizeMeters / 111_000.0
        let longitudeDegree = tileSizeMeters / (111_000.0 * cos(coordinate.latitude * .pi / 180))

        let x = Int(coordinate.latitude / latitudeDegree)
        let y = Int(coordinate.longitude / longitudeDegree)
        return "\(x)_\(y)"
    }

    func updateFogOverlay() {
        guard let userLocation = locationManager.location?.coordinate else {
            return
        }

        let latitudeDegree = tileSizeMeters / 111_000.0
        let longitudeDegree = tileSizeMeters / (111_000.0 * cos(userLocation.latitude * .pi / 180))

        let userTileX = Int(userLocation.latitude / latitudeDegree)
        let userTileY = Int(userLocation.longitude / longitudeDegree)

        let tileCount = Int((maxDistance / tileSizeMeters).rounded(.up))
        let minX = userTileX - tileCount
        let maxX = userTileX + tileCount
        let minY = userTileY - tileCount
        let maxY = userTileY + tileCount

        var outerCoordinates: [CLLocationCoordinate2D] = []
        // Define the outer boundary (e.g., a square or circle around the user)
        // For simplicity, let's use a square here
        let boundarySize = tileCount * Int(tileSizeMeters)
        let boundaryDegreeLat = Double(tileCount) * latitudeDegree
        let boundaryDegreeLon = Double(tileCount) * longitudeDegree

        let topLeft = CLLocationCoordinate2D(
            latitude: userLocation.latitude - boundaryDegreeLat,
            longitude: userLocation.longitude - boundaryDegreeLon
        )
        let topRight = CLLocationCoordinate2D(
            latitude: userLocation.latitude - boundaryDegreeLat,
            longitude: userLocation.longitude + boundaryDegreeLon
        )
        let bottomRight = CLLocationCoordinate2D(
            latitude: userLocation.latitude + boundaryDegreeLat,
            longitude: userLocation.longitude + boundaryDegreeLon
        )
        let bottomLeft = CLLocationCoordinate2D(
            latitude: userLocation.latitude + boundaryDegreeLat,
            longitude: userLocation.longitude - boundaryDegreeLon
        )
        outerCoordinates = [topLeft, topRight, bottomRight, bottomLeft]

        var holeCoordinates: [[CLLocationCoordinate2D]] = []
        for x in minX...maxX {
            for y in minY...maxY {
                let tileKey = "\(x)_\(y)"
                if visitedTiles.contains(tileKey) {
                    let tileCenter = coordinateForTileCenter(
                        x: x,
                        y: y,
                        latitudeDegree: latitudeDegree,
                        longitudeDegree: longitudeDegree
                    )
                    let tileCoords = coordinatesForTile(
                        x: x,
                        y: y,
                        latitudeDegree: latitudeDegree,
                        longitudeDegree: longitudeDegree
                    )
                    holeCoordinates.append(tileCoords)
                }
            }
        }

        let combinedPolygon = MKPolygon(
            coordinates: outerCoordinates,
            count: outerCoordinates.count,
            interiorPolygons: holeCoordinates.map { MKPolygon(coordinates: $0, count: $0.count) }
        )

        DispatchQueue.main.async {
            self.fogOverlay = combinedPolygon
            self.totalTiles = (maxX - minX + 1) * (maxY - minY + 1)
            self.uncoveredTiles = holeCoordinates.count
        }
    }

    private func coordinatesForTile(
        x: Int,
        y: Int,
        latitudeDegree: Double,
        longitudeDegree: Double
    ) -> [CLLocationCoordinate2D] {
        let latitude = Double(x) * latitudeDegree
        let longitude = Double(y) * longitudeDegree

        return [
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude + longitudeDegree),
            CLLocationCoordinate2D(latitude: latitude + latitudeDegree, longitude: longitude + longitudeDegree),
            CLLocationCoordinate2D(latitude: latitude + latitudeDegree, longitude: longitude)
        ]
    }

    private func coordinateForTileCenter(
        x: Int,
        y: Int,
        latitudeDegree: Double,
        longitudeDegree: Double
    ) -> CLLocationCoordinate2D {
        let latitude = (Double(x) + 0.5) * latitudeDegree
        let longitude = (Double(y) + 0.5) * longitudeDegree
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Persistence Methods remain the same
    private func saveVisitedTiles() {
        let tilesArray = Array(visitedTiles)
        UserDefaults.standard.set(tilesArray, forKey: "VisitedTiles")
    }

    private func loadVisitedTiles() {
        if let tilesArray = UserDefaults.standard.array(forKey: "VisitedTiles") as? [String] {
            visitedTiles = Set(tilesArray)
        }
    }
}
