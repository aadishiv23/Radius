import CoreLocation
import Foundation
import MapKit

enum FogOfWarConstants {
    static let annArborCoordinate = CLLocationCoordinate2D(latitude: 42.2808, longitude: -83.7430)
    static let radiusMiles = 100.0
    static let radiusMeters = radiusMiles * 1609.34 // Convert miles to meters
    static let tileSizeMeters = 100.0
    static let updateInterval = 1.0 // Update interval in seconds
}

struct TileRegion {
    let bounds: MKCoordinateRegion
    let key: String
    let timestamp: Date

    init(coordinate: CLLocationCoordinate2D, tileSizeMeters: Double, key: String) {
        let latitudeDelta = tileSizeMeters / 111_000.0
        let longitudeDelta = tileSizeMeters / (111_000.0 * cos(coordinate.latitude * .pi / 180))

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
        let latInRange = coordinate.latitude >= (region.center.latitude - region.span.latitudeDelta / 2) &&
            coordinate.latitude <= (region.center.latitude + region.span.latitudeDelta / 2)
        let lonInRange = coordinate.longitude >= (region.center.longitude - region.span.longitudeDelta / 2) &&
            coordinate.longitude <= (region.center.longitude + region.span.longitudeDelta / 2)
        return latInRange && lonInRange
    }
}

class FogOfWarManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var fogOverlay: MKOverlay?
    @Published var totalTiles = 0
    @Published var uncoveredTiles = 0
    @Published var uncoverMessage: String?
    @Published var isWithinBoundary = true

    private var locationManager = CLLocationManager()
    private var visitedRegions: [String: TileRegion] = [:]
    private var updateTimer: Timer?
    private let visitedRegionsQueue = DispatchQueue(label: "visitedRegionsQueue", attributes: .concurrent)

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        loadVisitedRegions()

        // Calculate total number of tiles within the 100-mile radius
        let area = Double.pi * pow(FogOfWarConstants.radiusMeters, 2)
        let tileArea = pow(FogOfWarConstants.tileSizeMeters, 2)
        totalTiles = Int(area / tileArea)

        // Initialize uncoveredTiles based on loaded regions
        uncoveredTiles = visitedRegions.count

        // Initial fog overlay
        Task { @MainActor in
            self.updateFogOverlay()
        }
    }

    private func generateRegionKey(for coordinate: CLLocationCoordinate2D) -> String {
        let tileSizeMeters = FogOfWarConstants.tileSizeMeters
        let latitudeDegree = tileSizeMeters / 111_000.0
        let longitudeDegree = tileSizeMeters / (111_000.0 * cos(coordinate.latitude * .pi / 180))

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
        let region = TileRegion(
            coordinate: coordinate,
            tileSizeMeters: FogOfWarConstants.tileSizeMeters,
            key: key
        )
        visitedRegionsQueue.async(flags: .barrier) {
            self.visitedRegions[key] = region
        }
        saveVisitedRegions()
    }

    private func showUncoverMessage() {
        DispatchQueue.main.async {
            self.uncoverMessage = "New area uncovered!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.uncoverMessage = nil
            }
        }
    }

    private func loadVisitedRegions() {
        if let savedRegions = UserDefaults.standard.dictionary(forKey: "VisitedRegions") as? [String: [String: Any]] {
            var loadedRegions: [String: TileRegion] = [:]

            for (key, data) in savedRegions {
                if let latitude = data["latitude"] as? Double,
                   let longitude = data["longitude"] as? Double
                {
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    loadedRegions[key] = TileRegion(
                        coordinate: coordinate,
                        tileSizeMeters: FogOfWarConstants.tileSizeMeters,
                        key: key
                    )
                }
            }

            visitedRegionsQueue.async(flags: .barrier) {
                self.visitedRegions = loadedRegions
            }
        }
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

    private func createRectangularCoordinates(for region: MKCoordinateRegion) -> [CLLocationCoordinate2D] {
        [
            CLLocationCoordinate2D(
                latitude: region.center.latitude - region.span.latitudeDelta / 2,
                longitude: region.center.longitude - region.span.longitudeDelta / 2
            ),
            CLLocationCoordinate2D(
                latitude: region.center.latitude - region.span.latitudeDelta / 2,
                longitude: region.center.longitude + region.span.longitudeDelta / 2
            ),
            CLLocationCoordinate2D(
                latitude: region.center.latitude + region.span.latitudeDelta / 2,
                longitude: region.center.longitude + region.span.longitudeDelta / 2
            ),
            CLLocationCoordinate2D(
                latitude: region.center.latitude + region.span.latitudeDelta / 2,
                longitude: region.center.longitude - region.span.longitudeDelta / 2
            )
        ]
    }
}

extension FogOfWarManager {
    @MainActor
    func updateFogOverlay() {
        let visitedPolygons: [MKPolygon] = visitedRegions.values.map { tileRegion in
            let coords = createRectangularCoordinates(for: tileRegion.bounds)
            return MKPolygon(coordinates: coords, count: coords.count)
        }

        let multiPolygon = MKMultiPolygon(visitedPolygons)
        fogOverlay = multiPolygon
    }
}

extension FogOfWarManager {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = location.coordinate

        // Calculate distance from Ann Arbor
        let distance = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            .distance(from: CLLocation(latitude: FogOfWarConstants.annArborCoordinate.latitude,
                                       longitude: FogOfWarConstants.annArborCoordinate.longitude))
        
        DispatchQueue.main.async {
            self.isWithinBoundary = distance <= FogOfWarConstants.radiusMeters
        }

        // If out of bounds, do not process further
        if distance > FogOfWarConstants.radiusMeters {
            return
        }

        let key = generateRegionKey(for: coordinate)

        if !isRegionVisited(coordinate) {
            addVisitedRegion(coordinate, key: key)
            DispatchQueue.main.async {
                self.uncoveredTiles += 1
                self.updateFogOverlay()
                self.showUncoverMessage()
            }
        }
    }
}
