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
import CryptoKit
import Supabase

/*
 rather than load friends can also call swift fr directly in view
 @FetchRequest(
        entity: FriendLocationEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FriendLocationEntity.name, ascending: true)]
    ) var friends: FetchedResults<FriendLocationEntity>
 */

class FriendsDataManager: ObservableObject {
    private let dataController: DataController
    private var supabaseClient: SupabaseClient
    
    @Published var friends: [FriendLocation] = []
    
    init(dataController: DataController, supabaseClient: SupabaseClient) {
        self.dataController = dataController
        self.supabaseClient = supabaseClient
    }
    
    private func hashPassword(_ password: String) -> String {
        let hashed = SHA256.hash(data: Data(password.utf8))
        
        // The hash result is a series of bytes. Each byte is an integer between 0 and 255.
        // This line converts each byte into a two-character hexadecimal string.
        // %x indicates hexadecimal formatting.
        // 02 ensures that the hexadecimal number is padded with zeros to always have two digits.
        // This is important because a byte represented in hexadecimal can have one or two digits (e.g., 0x3 or 0x03),
        // and consistent formatting requires two digits.
        // After converting all bytes to two-character strings, joined() concatenates all these strings into a single string, resulting in the final hashed password in hexadecimal form.
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    
    
    // Fetches all friends from friends table
    func fetchFriends() async {
        do {
            let result = try await supabaseClient
                .from("friends")
                .select("*")
                .execute()
            
            if let friendsData = result.data as? [[String: Any]] {
                DispatchQueue.main.async {
                    self.friends = friendsData.map({ data in
                        FriendLocation(name: data["name"] as? String ?? "Unknown",
                                       color: Color(data["color"] as? String ?? "$FFFFFF"),
                                       coordinate: CLLocationCoordinate2D(latitude: data["latitude"] as? Double ?? 0, 
                                                                          longitude: data["longitude"] as? Double ?? 0),
                                       zones: [])
                    })
                }
            }
        } catch {
            print("Failed to fetch friends: \(error)")
        }
    }

    
    func createGroup(name: String, description: String?, password: String) async {
        let hashedPassword = hashPassword(password)
        do {
            let result = try await supabaseClient
                .from("groups")
                .insert([
                    "name" : name,
                    "description" : description ?? "",
                    "password" : hashedPassword
                ])
                .execute()
            
            print("Group created: \(result)")
        } catch {
            print("Failed to create group: \(error)")
        }
    }
    
    
    func joinGroup(groupId: UUID, friendId: UUID, password: String) async throws -> Bool {
        do {
            let groupResult = try await supabaseClient
                .from("groups")
                .select("password")
                .eq("id", value: groupId)
                .single()
                .execute()
            
            guard let data = groupResult.data as? [String: Any],
                  let fetchedHash = data["password"] as? String else {
                throw NSError(domain: "Invalid Data format", code: 1, userInfo: nil)
            }
            
            if fetchedHash == hashPassword(password) {
                try await supabaseClient
                    .from("groups")
                    .insert([
                        "group_id": groupId,
                        "friendId": friendId
                    ])
                    .execute()
                return true
                
            } else {
                print("Unable to join desired group")
                return false
            }
            
        } catch {
            return false
            print("Failed to access group: \(error)")
        }
        
       
        
        
       return false
    }
    
    func fetchGroupMembers(groupId: UUID) async throws {
        let result = try await supabaseClient
            .from("group")
            .select("""
            friend_id,
            friends!inner(*)
            """)
            .eq("groupId", value: groupId)
            .execute()
        
        print("Group members \(result)")
    }
    
    
    func addFriend(name: String, color: String, profileId: UUID) async throws {
        let result = try await supabaseClient
            .from("friends")
            .insert([
                "name": name,
                "color": color,
                "profile_id": profileId.uuidString
            ])
    }
    
    
}





/*
 
 func loadFriends() {
     let context = dataController.container.viewContext
     let request: NSFetchRequest<FriendLocationEntity> = FriendLocationEntity.fetchRequest()
     do {
         let friendsEntities = try context.fetch(request)
         self.friends = friendsEntities.map { entity in
             let zones = (entity.zones as? Set<ZoneEntity>)?.map { zoneEntity -> Zone in
                 let coordinate = CLLocationCoordinate2DTransformer().reverseTransformedValue(zoneEntity.coordinate) as? CLLocationCoordinate2D ?? CLLocationCoordinate2D()
                 return Zone(name: zoneEntity.name ?? "", coordinate: coordinate, radius: zoneEntity.radius)
             } ?? []
             
             return FriendLocation(
                 name: entity.name ?? "Unknown",
                 color: Color(entity.color as? UIColor ?? UIColor.systemTeal),
                 coordinate: CLLocationCoordinate2DTransformer().reverseTransformedValue(entity.coordinate) as? CLLocationCoordinate2D ?? CLLocationCoordinate2D(),
                 zones: zones
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
         zoneEntity.name = zone.name
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
             let zones = (friend.zones as? Set<ZoneEntity>)?.map { zoneEntity -> Zone in
                 let coordinateTransformer = CLLocationCoordinate2DTransformer()
                 let coordinate = CLLocationCoordinate2DTransformer().reverseTransformedValue(zoneEntity.coordinate) as? CLLocationCoordinate2D ?? CLLocationCoordinate2D()
                 return Zone(name: zoneEntity.name ?? "", coordinate: coordinate, radius: zoneEntity.radius)
             } ?? []
             
             return FriendLocation(name: friend.name ?? "Unknown",
                                   color: Color(friend.color as! UIColor),
                                   coordinate: CLLocationCoordinate2DTransformer().reverseTransformedValue(friend.coordinate) as? CLLocationCoordinate2D ?? CLLocationCoordinate2D(),
                                   zones: zones)
         }
     } catch {
         print("Failed to retrieve all friends: \(error.localizedDescription)")
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
 */
