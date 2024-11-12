//
//  ZoneEntity.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 11/6/24.
//

import AppIntents
import Foundation

/// Entity to represent a `zone` for selection in an App Intent / Shortcut
struct ZoneEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Zone"
    static var defaultQuery = ZoneQuery()

    var id: UUID
    var name: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    /// Add initializer to convert from Zone
    init(from zone: Zone) {
        self.id = zone.id
        self.name = zone.name
    }

    /// Regular initializer
    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}
