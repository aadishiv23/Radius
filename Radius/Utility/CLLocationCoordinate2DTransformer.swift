//
//  CoordinateTransformer.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/30/24.
//

import Foundation
import CoreData
import CoreLocation
import SwiftUI

class CLLocationCoordinate2DTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    // MARK: Write a CLLocationCoordinate2D object to the CoreData DB as a Data type
    override public func transformedValue(_ value: Any?) -> Any? {
        guard let coordinate = value as? CLLocationCoordinate2D else { return nil }
        
        var lat = coordinate.latitude
        var lon = coordinate.longitude
        return Data(bytes: &lat, count: MemoryLayout<Double>.size) + Data(bytes: &lon, count: MemoryLayout<Double>.size)
    }
    
    // MARK: Read a CLLocationCoordinate2D object from a NSData object stored in CoreData DB
    override public func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        
        let lat = data.withUnsafeBytes { $0.load(as: Double.self)}
        let lon = data.subdata(in: MemoryLayout<Double>.size..<data.count).withUnsafeBytes { $0.load(as: Double.self) }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// Register the transformer
extension CLLocationCoordinate2DTransformer {
    static func register() {
        let transformer = CLLocationCoordinate2DTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: NSValueTransformerName("CLLocationCoordinate2DTransformer"))
    }
}
