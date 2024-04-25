//
//  MapViewModel.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/6/24.
//

//import CoreLocation
//import MapKit
//
//enum MapDetails {
//    static let startingLocation = CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783)
//    static let defaulSpan =  MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
//}
//
//final class MapViewModel: NSObject ,ObservableObject, CLLocationManagerDelegate {
//    
//    
//    @Published var region = MKCoordinateRegion(center: MapDetails.startingLocation, span: MapDetails.defaulSpan)
//    
//    var locationManager: CLLocationManager? // Optional, as user can turn off location service for their whole phone - have to make sure its on
//    
//    func checkIfLocationServiceEnabled() {
//        if CLLocationManager.locationServicesEnabled() {
//            print("enabled")
//            locationManager = CLLocationManager()
//            locationManager!.delegate = self
//            //locationManager?.desiredAccuracy = kCLLocationAccuracyBest
//        }
//        else {
//            print("Show user alert and ask to turn on")
//        }
//    }
//    
//    private func checkLocationAuthorization() {
//        // sue location manager in this scope
//        guard let locationManager = locationManager else { return }
//        
//        // check for cases
//        
//        switch locationManager.authorizationStatus {
//        
//            case .notDetermined: // Ask for permission
//            print("1")
//            DispatchQueue.main.async {
//                self.locationManager?.requestWhenInUseAuthorization()
//                locationManager.requestAlwaysAuthorization()
//            }
//
//
//
//            case .restricted:
//                print("Your locatoin suage is likely restricted due to parental control") // sometimes location restricted due to personal
//            case .denied:
//                print("You have denied the usage of locatoin. Please go into locations and fix")
//            case .authorizedAlways, .authorizedWhenInUse:
//            
//            if let currentLocation = locationManager.location?.coordinate {
//                        DispatchQueue.main.async {
//                            self.region = MKCoordinateRegion(center: currentLocation, span: MapDetails.defaulSpan)
//                        }
//                    }
//            @unknown default:
//                break
//        }
//        
//        
//    }
//    
//    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        DispatchQueue.main.async {
//            self.checkLocationAuthorization()
//        }
//    }
//    
//    
//}
