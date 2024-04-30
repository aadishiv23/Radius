//
//  FriendLocationEntity+CoreDataProperties.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/30/24.
//
//

import Foundation
import CoreData


extension FriendLocationEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FriendLocationEntity> {
        return NSFetchRequest<FriendLocationEntity>(entityName: "FriendLocationEntity")
    }

    @NSManaged public var color: NSObject?
    @NSManaged public var coordinate: NSObject?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var zones: NSSet?

}

// MARK: Generated accessors for zones
extension FriendLocationEntity {

    @objc(addZonesObject:)
    @NSManaged public func addToZones(_ value: ZoneEntity)

    @objc(removeZonesObject:)
    @NSManaged public func removeFromZones(_ value: ZoneEntity)

    @objc(addZones:)
    @NSManaged public func addToZones(_ values: NSSet)

    @objc(removeZones:)
    @NSManaged public func removeFromZones(_ values: NSSet)

}

extension FriendLocationEntity : Identifiable {

}
