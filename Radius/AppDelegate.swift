//
//  AppDelegate.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/28/24.
//

import CoreLocation
import Foundation
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var locationManager: LocationManager!

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Start monitoring significant location changes in the background
        locationManager.startMonitoringSignificantLocationChanges()
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize the LocationManager
        locationManager = LocationManager.shared

        // Reinitiate location monitoring if needed
        if CLLocationManager.locationServicesEnabled() {
            locationManager.reinitializeMonitoringIfNeeded()
        }

        return true
    }
}
