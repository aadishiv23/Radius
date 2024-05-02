//
//  FriendsDataManager.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/1/24.
//

import Foundation
import CoreData
import CoreLocation
import SwiftUI


class FriendsDataManager {
    private let dataController: DataController
    
    init(dataController: DataController) {
        self.dataController = dataController
    }
    
    // Temporary functions
    func addFriend(name: String, color: UIColor, coordinate: CLLocationCoordinate2D, zones: [Zone]) {
        let context = dataController.container.viewContext
        let friend = FriendLocationEntity(context: context)
        friend.id = UUID()
        friend.name = name
        // friend.color = color  //IMPLEMENT TRANSFORMER    }
    }
}
