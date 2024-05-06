//
//  Friends.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/24/24.
//

import Foundation
import MapKit
import CoreLocation
import SwiftUI


struct Zone: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    var radius: Double // Radius in meters
}

struct FriendLocation: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let coordinate: CLLocationCoordinate2D
    var zones: [Zone]  // Each friend can have multiple zones
}

struct UserLocation: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var zones: [Zone]  // Zones specific to the user
}

//class FriendData: ObservableObject {
////    @Published var friendsLocations: [FriendLocation] = [
////        FriendLocation(name: "Alice", color: .red, coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)),
////        FriendLocation(name: "Bob", color: .blue, coordinate: CLLocationCoordinate2D(latitude: 40.7158, longitude: -74.0080)),
////        FriendLocation(name: "Charlie", color: .green, coordinate: CLLocationCoordinate2D(latitude: 40.7108, longitude: -74.0100)),
////        FriendLocation(name: "David", color: .yellow, coordinate: CLLocationCoordinate2D(latitude: 40.7138, longitude: -74.0120))
////    ]
//    @Published var friendsLocations: [FriendLocation] = [
//            // Initial friends data with zones
//        ]
//    @Published var userLocation: UserLocation?
//    
//    init() {
//            friendsLocations = [
//                FriendLocation(
//                    name: "Alice",
//                    color: .red,
//                    coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
//                    zones: [
//                        Zone(name: "Home", coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), radius: 150.0),
//                        Zone(name: "Work", coordinate: CLLocationCoordinate2D(latitude: 40.7125, longitude: -74.0065), radius: 250.0)
//                    ]
//                ),
//                FriendLocation(
//                    name: "Bob",
//                    color: .blue,
//                    coordinate: CLLocationCoordinate2D(latitude: 40.7158, longitude: -74.0080),
//                    zones: [
//                        Zone(name: "Gym", coordinate: CLLocationCoordinate2D(latitude: 40.7158, longitude: -74.0080), radius: 100.0),
//                        Zone(name: "Zoo", coordinate: CLLocationCoordinate2D(latitude: 40.7160, longitude: -74.0085), radius: 200.0)
//                    ]
//                ),
//                FriendLocation(
//                    name: "Charlie",
//                    color: .green,
//                    coordinate: CLLocationCoordinate2D(latitude: 40.7108, longitude: -74.0100),
//                    zones: [
//                        Zone(name: <#String#>, coordinate: CLLocationCoordinate2D(latitude: 40.7108, longitude: -74.0100), radius: 120.0),
//                        Zone(name: <#String#>, coordinate: CLLocationCoordinate2D(latitude: 40.7105, longitude: -74.0105), radius: 300.0)
//                    ]
//                ),
//                FriendLocation(
//                    name: "David",
//                    color: .yellow,
//                    coordinate: CLLocationCoordinate2D(latitude: 40.7138, longitude: -74.0120),
//                    zones: [
//                        Zone(name: <#String#>, coordinate: CLLocationCoordinate2D(latitude: 40.7138, longitude: -74.0120), radius: 180.0),
//                        Zone(name: <#String#>, coordinate: CLLocationCoordinate2D(latitude: 40.7140, longitude: -74.0125), radius: 280.0)
//                    ]
//                )
//            ]
//        }
//    
//    func addZone(to friendID: UUID, with radius: Double, at coordinate: CLLocationCoordinate2D) {
//        if let index = friendsLocations.firstIndex(where: { $0.id == friendID }) {
//            let newZone = Zone(coordinate: coordinate, radius: radius)
//            friendsLocations[index].zones.append(newZone)
//        }
//    }
//
//    func addUserZone(with radius: Double, at coordinate: CLLocationCoordinate2D) {
//        if userLocation == nil {
//            userLocation = UserLocation(coordinate: coordinate, zones: [])
//        }
//        let newZone = Zone(coordinate: coordinate, radius: radius)
//        userLocation?.zones.append(newZone)
//    }
//    
//}
//
//class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
//    private var locationManager: CLLocationManager?
//    @Published var userLocation: CLLocation?
//
//    func checkIfLocationServicesIsEnabled() {
//        if CLLocationManager.locationServicesEnabled() {
//            locationManager = CLLocationManager()
//            locationManager!.delegate = self
//            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
//            locationManager!.requestWhenInUseAuthorization()
//        } else {
//            print("Location services are not enabled")
//        }
//    }
//
//    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        switch manager.authorizationStatus {
//        case .notDetermined, .restricted, .denied:
//            print("Not authorized to use location services")
//        case .authorizedWhenInUse, .authorizedAlways:
//            locationManager?.startUpdatingLocation()
//        @unknown default:
//            break
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.last else { return }
//        userLocation = location
//    }
//    
//    func plsInitiateLocationUpdates() {
//        locationManager.startUpdatingLocation()
//    }
//}


