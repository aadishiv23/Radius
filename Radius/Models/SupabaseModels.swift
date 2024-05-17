//
//  SupabaseModels.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/8/24.
//

import Foundation
import SwiftUI


struct Group: Codable {
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

struct Profile: Decodable, Identifiable {
    let id: UUID
    let username: String
    let full_name: String
    let color: String
    let latitude: Double
    let longitude: Double
    var zones: [Zone]

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case full_name
        case color
        case latitude
        case longitude
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
  let website: String

  enum CodingKeys: String, CodingKey {
    case username
    case fullName = "full_name"
    case website
  }
}
