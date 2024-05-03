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


class FriendsDataManager: ObservableObject {
    private let dataController: DataController
    
    @Published var friends: [FriendLocation] = []
    
    init(dataController: DataController) {
        self.dataController = dataController
    }
    
    func loadFriends() {
        let context = dataController.container.viewContext
        let request: NSFetchRequest<FriendLocationEntity> = FriendLocationEntity.fetchRequest()
        do {
                let friendsEntities = try context.fetch(request)
                self.friends = friendsEntities.map { entity in
                    let transformer = CLLocationCoordinate2DTransformer()
                    let coordinate = (transformer.reverseTransformedValue(entity.coordinate as? Data) as? CLLocationCoordinate2D) ?? CLLocationCoordinate2D()
                    
                    return FriendLocation(
                        name: entity.name ?? "Unknown",
                        color: Color(entity.color as? UIColor ?? UIColor.systemTeal),  // Handling color conversion
                        coordinate: coordinate,
                        zones: [] // Assuming you have a mechanism to transform zone entities as well
                    )
                }
            } catch {
                print("Failed to fetch friends: \(error)")
            }
        
    }
    
    /// Add a friend to your saved data
    func addFriend(name: String, color: UIColor, coordinate: CLLocationCoordinate2D, zones: [Zone]) {
        let context = dataController.container.viewContext
        let friend = FriendLocationEntity(context: context)
        friend.id = UUID()
        friend.name = name
        friend.color = ColorTransformer().transformedValue(Color(uiColor: color)) as? Data as NSObject?
        friend.coordinate = CLLocationCoordinate2DTransformer().transformedValue(coordinate) as? Data as NSObject?
        
        for zone in zones {
            let zoneEntity = ZoneEntity(context: context)
            zoneEntity.id = zone.id
            zoneEntity.radius = zone.radius
            zoneEntity.coordinate = CLLocationCoordinate2DTransformer().transformedValue(zone.coordinate) as? Data as NSObject?
            zoneEntity.radius = zone.radius
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to save friend and zones: \(error.localizedDescription)")
        }
    }
    
    
    func getAllFriends() -> [FriendLocation] {
        let context = dataController.container.viewContext
        let request: NSFetchRequest<FriendLocationEntity> = FriendLocationEntity.fetchRequest()
        
        do {
            let friends = try context.fetch(request)
            return friends.map { friend in
                let zones = friend.zones?.allObjects as? [ZoneEntity] ?? []
                
                return FriendLocation(name: friend.name ?? "",
                                      color: Color(UIColor(cgColor: (friend.color as? UIColor)?.cgColor ?? UIColor.clear.cgColor)), // Convert back from stored UIColor
                                      coordinate: NSKeyedUnarchiver.unarchiveObject(with: friend.coordinate as! Data) as? CLLocationCoordinate2D ?? CLLocationCoordinate2D(),
                                      zones: zones.map { Zone(coordinate: NSKeyedUnarchiver.unarchiveObject(with: $0.coordinate as! Data) as? CLLocationCoordinate2D ?? CLLocationCoordinate2D(),
                                                              radius: $0.radius) })
            }
        } catch {
            print("Failed to fetch friends: \(error.localizedDescription)")
            return []
        }
    }
    
    
    func deleteFriend(friend: FriendLocation) {
        let context = dataController.container.viewContext
        let request: NSFetchRequest<FriendLocationEntity> = FriendLocationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", friend.id as CVarArg)
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                context.delete(entity)
                try context.save()
            }
        } catch {
            print("Failed to delete friend: \(error.localizedDescription)")
            return
        }
    }
    
    func addZone(to friendID: UUID, with newZone: Zone) {
        let context = dataController.container.viewContext
        let request: NSFetchRequest<FriendLocationEntity> = FriendLocationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", friendID as CVarArg)
        
        do {
            if let friend = try context.fetch(request).first {
                let zoneEntity = ZoneEntity(context: context)
                zoneEntity.id = UUID()
                zoneEntity.coordinate = CLLocationCoordinate2DTransformer().transformedValue(newZone.coordinate) as? Data as NSObject?
                zoneEntity.radius = newZone.radius
                friend.addToZones(zoneEntity)
                try context.save()
            }
        } catch {
            print("Failed to add zone: \(error)")
        }
    }
}
