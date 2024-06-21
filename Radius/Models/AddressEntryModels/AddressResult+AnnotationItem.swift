//
//  AddressResult+AnnotationItem.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/20/24.
//

import Foundation
import MapKit
/// based of https://levelup.gitconnected.com/implementing-address-autocomplete-using-swiftui-and-mapkit-c094d08cda24

/// Conforms to Identifiable so that they can be used in collections
struct AddressResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

struct AnnotationItem: Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
