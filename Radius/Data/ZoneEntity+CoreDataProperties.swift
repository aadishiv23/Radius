//
//  ZoneEntity+CoreDataProperties.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/30/24.
//
//

import Foundation
import CoreData


extension ZoneEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ZoneEntity> {
        return NSFetchRequest<ZoneEntity>(entityName: "ZoneEntity")
    }

    @NSManaged public var coordinate: NSObject?
    @NSManaged public var id: UUID?
    @NSManaged public var radius: Double
    @NSManaged public var friendLocation: FriendLocationEntity?

}

extension ZoneEntity : Identifiable {

}