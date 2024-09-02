//
//  SupabaseModels.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/8/24.
//

import Foundation
import SwiftUI

//struct FriendRequest: Identifiable, Codable {
//    var id: UUID
//    var sender_id: UUID
//    var receiver_id: UUID
//    var status: String
//    var created_at: Date
//    
//    // For more readable status values, you can use an enum
//    enum Status: String, Codable {
//        case pending = "pending"
//        case accepted = "accepted"
//        case rejected = "rejected"
//    }
//    
//    // Computed property to get the status as an enum
//    var requestStatus: Status {
//        return Status(rawValue: status) ?? .pending
//    }
//    
//    // Additional convenience computed properties
//    var isPending: Bool {
//        return requestStatus == .pending
//    }
//    
//    var isAccepted: Bool {
//        return requestStatus == .accepted
//    }
//    
//    var isRejected: Bool {
//        return requestStatus == .rejected
//    }
//}

struct FriendRequest: Identifiable, Codable {
    var id: UUID
    var sender_id: UUID
    var receiver_id: UUID
    var status: String
    var created_at: Date

    enum CodingKeys: String, CodingKey {
        case id, sender_id, receiver_id, status, created_at
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        sender_id = try container.decode(UUID.self, forKey: .sender_id)
        receiver_id = try container.decode(UUID.self, forKey: .receiver_id)
        status = try container.decode(String.self, forKey: .status)

        let dateString = try container.decode(String.self, forKey: .created_at)
        if let date = DateFormatter.customSupabaseFormat.date(from: dateString) {
            created_at = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .created_at, in: container, debugDescription: "Invalid date format: \(dateString)")
        }
    }
}


extension DateFormatter {
    static let customSupabaseFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static let zoneExitSupabaseFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
//extension DateFormatter {
//    static let customSupabaseFormat: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
//        formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        formatter.locale = Locale(identifier: "en_US_POSIX")
//        return formatter
//    }()
//}


struct Group: Codable, Identifiable, Hashable {
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

enum ZoneCategory: String, Codable, CaseIterable {
    case home = "home"
    case school = "school"
    case gym = "gym"
    case food = "food"
    case social = "social"
    case other = "other"
}

struct Zone: Codable, Identifiable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let radius: Double
    let profile_id: UUID
    let category: ZoneCategory

    // Provide a default value for the category if not initialized
    init(id: UUID = UUID(), name: String, latitude: Double, longitude: Double, radius: Double, profile_id: UUID, category: ZoneCategory = .other) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.profile_id = profile_id
        self.category = category
    }
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

struct DailyZoneExit: Identifiable, Codable {
    var id: UUID
    var date: Date
    var profileId: UUID
    var zoneExitId: UUID
    var exitOrder: Int
    var pointsEarned: Int
}

struct GroupTotalPoints: Identifiable, Codable {
    var id: UUID
    var groupId: UUID
    var totalPoints: Int
}

struct UserTotalPoints: Identifiable, Codable {
    var id: UUID
    var profileId: UUID
    var totalPoints: Int
}

struct DailyPoints: Identifiable, Codable {
    var id: UUID
    var profileId: UUID
    var groupId: UUID?
    var points: Int
    var date: Date
}

struct ZoneExit: Identifiable, Codable {
    var id: UUID
    var profile_id: UUID
    var zone_id: UUID
    var exit_time: Date
    
    enum CodingKeys: String, CodingKey {
        case id, profile_id, zone_id, exit_time
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        profile_id = try container.decode(UUID.self, forKey: .profile_id)
        zone_id = try container.decode(UUID.self, forKey: .zone_id)
        
        let dateString = try container.decode(String.self, forKey: .exit_time)
        if let date = DateFormatter.zoneExitSupabaseFormat.date(from: dateString) {
            exit_time = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .exit_time, in: container, debugDescription: "Invalid date format: \(dateString)")
        }
    }
}

struct GroupCompetition: Identifiable, Codable {
    var id: UUID
    var competition_name: String
    var competition_date: Date
    var max_points: Int
    var created_at: Date

    enum CodingKeys: String, CodingKey {
        case id, competition_name, competition_date, max_points, created_at
    }

    init(id: UUID, competition_name: String, competition_date: Date, max_points: Int, created_at: Date) {
        self.id = id
        self.competition_name = competition_name
        self.competition_date = competition_date
        self.max_points = max_points
        self.created_at = created_at
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        competition_name = try container.decode(String.self, forKey: .competition_name)
        max_points = try container.decode(Int.self, forKey: .max_points)
        
        // Custom date decoding
        let dateString = try container.decode(String.self, forKey: .competition_date)
        let createdAtString = try container.decode(String.self, forKey: .created_at)
        
        let isoDateFormatter = DateFormatter()
        isoDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        isoDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let simpleDateFormatter = DateFormatter()
        simpleDateFormatter.dateFormat = "yyyy-MM-dd"
        simpleDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let competitionDate = simpleDateFormatter.date(from: dateString) {
            self.competition_date = competitionDate
        } else if let competitionDate = isoDateFormatter.date(from: dateString) {
            self.competition_date = competitionDate
        } else {
            throw DecodingError.dataCorruptedError(forKey: .competition_date, in: container, debugDescription: "Invalid date format: \(dateString)")
        }

        if let createdAtDate = isoDateFormatter.date(from: createdAtString) {
            self.created_at = createdAtDate
        } else {
            throw DecodingError.dataCorruptedError(forKey: .created_at, in: container, debugDescription: "Invalid date format: \(createdAtString)")
        }
    }
}




struct GroupCompetitionLink: Identifiable, Codable {
    var id: UUID
    var competition_id: UUID
    var group_id: UUID
}

struct FriendRelation: Codable {
    let friendship_id: UUID
    let profile_id1: UUID
    let profile_id2: UUID
}
