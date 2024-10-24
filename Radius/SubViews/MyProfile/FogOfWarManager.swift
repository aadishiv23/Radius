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
    private var visitedTiles: Set<String> = []
    private let visitedTilesQueue = DispatchQueue(label: "visitedTilesQueue", attributes: .concurrent)

    private let tileSizeMeters = 100.0
    private let maxDistance = 5000.0

    override init() {
        super.init()
        locationManager.delegate = self
        applyLocationAccuracySettings()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        loadVisitedTiles()
        updateFogOverlay()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let tileKey = tileKeyForLocation(location.coordinate)
        
        if !isTileVisited(tileKey) {
            addVisitedTile(tileKey)
            updateFogOverlay(newTileKey: tileKey)
            showUncoverMessage()
        }
        else {
            // Force update for the current tile if already marked as visited
            updateFogOverlay(newTileKey: tileKey)
        }
    }

    private func tileKeyForLocation(_ coordinate: CLLocationCoordinate2D) -> String {
        let latitudeDegree = tileSizeMeters / 111_000.0
        let longitudeDegree = tileSizeMeters / (111_000.0 * cos(coordinate.latitude * .pi / 180))

        let x = Int((coordinate.latitude / latitudeDegree).rounded())
        let y = Int((coordinate.longitude / longitudeDegree).rounded())
        return "\(x)_\(y)"
    }

    private func addVisitedTile(_ tileKey: String) {
        visitedTilesQueue.async(flags: .barrier) {
            self.visitedTiles.insert(tileKey)
        }
        saveVisitedTiles()
    }

    private func isTileVisited(_ tileKey: String) -> Bool {
        visitedTilesQueue.sync {
            visitedTiles.contains(tileKey)
        }
    }

    func updateFogOverlay(newTileKey: String? = nil) {
        guard let userLocation = locationManager.location?.coordinate else { return }

        let latitudeDegree = tileSizeMeters / 111_000.0
        let longitudeDegree = tileSizeMeters / (111_000.0 * cos(userLocation.latitude * .pi / 180))

        let userTileX = Int(userLocation.latitude / latitudeDegree)
        let userTileY = Int(userLocation.longitude / longitudeDegree)

        let tileCount = Int((maxDistance / tileSizeMeters).rounded(.up))
        let minX = userTileX - tileCount
        let maxX = userTileX + tileCount
        let minY = userTileY - tileCount
        let maxY = userTileY + tileCount

        // Define the outer boundary coordinates
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
        let outerCoordinates = [topLeft, topRight, bottomRight, bottomLeft]

        var holeCoordinates: [[CLLocationCoordinate2D]] = []
        for x in minX...maxX {
            for y in minY...maxY {
                let tileKey = "\(x)_\(y)"
                if visitedTiles.contains(tileKey) {
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

    private func saveVisitedTiles() {
        let tilesArray = Array(visitedTiles)
        UserDefaults.standard.set(tilesArray, forKey: "VisitedTiles")
    }

    private func loadVisitedTiles() {
        if let tilesArray = UserDefaults.standard.array(forKey: "VisitedTiles") as? [String] {
            visitedTiles = Set(tilesArray)
        }
    }

    private func showUncoverMessage() {
        uncoverMessage = "New area uncovered!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.uncoverMessage = nil
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
