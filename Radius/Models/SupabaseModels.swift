//
//  SupabaseModels.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/8/24.
//

import Foundation
import SwiftUI

struct FriendRequest: Identifiable, Codable {
    var id: UUID
    var sender_id: UUID
    var receiver_id: UUID
    var status: String
    var created_at: Date
    
    // For more readable status values, you can use an enum
    enum Status: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case rejected = "rejected"
    }
    
    // Computed property to get the status as an enum
    var requestStatus: Status {
        return Status(rawValue: status) ?? .pending
    }
    
    // Additional convenience computed properties
    var isPending: Bool {
        return requestStatus == .pending
    }
    
    var isAccepted: Bool {
        return requestStatus == .accepted
    }
    
    var isRejected: Bool {
        return requestStatus == .rejected
    }
}

struct Group: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let password: String
}


struct Group2: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let password: String
}

struct Zone: Codable, Identifiable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let radius: Double
    let profile_id: UUID
    
}

struct Profile: Codable, Identifiable {
    var id: UUID
    var username: String
    var full_name: String
    var color: String
    var latitude: Double
    var longitude: Double
    var phone_num: String
    var zones: [Zone]

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case full_name
        case color
        case latitude
        case longitude
        case phone_num
        case zones
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? "Unknown User"
        full_name = try container.decodeIfPresent(String.self, forKey: .full_name) ?? "Unknown Full Name"
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? "#FFFFFF"
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude) ?? 0.0
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) ?? 0.0
        phone_num = try container.decodeIfPresent(String.self, forKey: .phone_num) ?? "123456789"
        zones = try container.decodeIfPresent([Zone].self, forKey: .zones) ?? []
    }
    
    var swiftUIColor: Color {
        Color(hex: color) ?? .black // .black
    }
}

//struct Profile: Decodable, Identifiable {
//    let id: UUID
//    let username: String
//    let full_name: String
//    let color: String
//    let latitude: Double
//    let longitude: Double
//    var zones: [Zone]
//    
//    init(id: UUID, username: String?, full_name: String?, color: String?, latitude: Double?, longitude: Double?, zones: [Zone]?) {
//        self.id = id
//        self.username = username ?? "Unknown User"
//        self.full_name = full_name ?? "Unknown Full Name"
//        self.color = color ?? "#FFFFFF" // Default color set to white
//        self.latitude = latitude ?? 0.0
//        self.longitude = longitude ?? 0.0
//        self.zones = zones ?? []
//    }
//}

//      enum CodingKeys: String, CodingKey {
//        case username
//        case fullName = "full_name"
//        case website
//      }


struct UpdateProfileParams: Encodable {
  let username: String
  let fullName: String

  enum CodingKeys: String, CodingKey {
    case username
    case fullName = "full_name"
  }
}

struct GroupMember: Codable {
    let group_id: UUID
    let profile_id: UUID
}
