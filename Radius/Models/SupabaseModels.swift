//
//  SupabaseModels.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/8/24.
//

import Foundation
import SwiftUI

// struct FriendRequest: Identifiable, Codable {
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
// }

struct FriendRequest: Identifiable, Codable {
    var id: UUID
    var sender_id: UUID
    var receiver_id: UUID
    var status: String
    var created_at: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sender_id
        case receiver_id
        case status
        case created_at
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.sender_id = try container.decode(UUID.self, forKey: .sender_id)
        self.receiver_id = try container.decode(UUID.self, forKey: .receiver_id)
        self.status = try container.decode(String.self, forKey: .status)

        let dateString = try container.decode(String.self, forKey: .created_at)
        if let date = DateFormatter.customSupabaseFormat.date(from: dateString) {
            self.created_at = date
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .created_at,
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
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

// extension DateFormatter {
//    static let customSupabaseFormat: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
//        formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        formatter.locale = Locale(identifier: "en_US_POSIX")
//        return formatter
//    }()
// }

struct Group: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var description: String?
    var password: String
    var plain_password: String?
    
    // Implement Hashable manually to ensure proper dictionary key handling
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Group, rhs: Group) -> Bool {
        lhs.id == rhs.id
    }
}

struct Group2: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let password: String
}

enum ZoneCategory: String, Codable, CaseIterable {
    case home
    case school
    case gym
    case food
    case social
    case other
}

struct Zone: Codable, Identifiable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let radius: Double
    let profile_id: UUID?
    let category: ZoneCategory

    /// Provide a default value for the category if not initialized
    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        radius: Double,
        profile_id: UUID,
        category: ZoneCategory = .other
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.profile_id = profile_id
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.radius = try container.decode(Double.self, forKey: .radius)
        self.profile_id = try container.decodeIfPresent(UUID.self, forKey: .profile_id)
        self.category = try container.decode(ZoneCategory.self, forKey: .category)
    }
}

struct Profile: Codable, Identifiable {
    var id: UUID
    var username: String
    var full_name: String
    var latitude: Double
    var longitude: Double
    var zones: [Zone]

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case full_name
        case latitude
        case longitude
        case zones
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.username = try container.decodeIfPresent(String.self, forKey: .username) ?? "Unknown User"
        self.full_name = try container.decodeIfPresent(String.self, forKey: .full_name) ?? "Unknown Full Name"
        self.latitude = try container.decodeIfPresent(Double.self, forKey: .latitude) ?? 0.0
        self.longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) ?? 0.0
        self.zones = try container.decodeIfPresent([Zone].self, forKey: .zones) ?? []
    }

//    var swiftUIColor: Color {
//      //  Color(hex: color) ?? .black // .black
//    }
}

// struct Profile: Decodable, Identifiable {
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
// }

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
    let profile_name: String?
    let group_name: String?
}

struct GroupMemberWoBS: Codable {
    var group_id: UUID
    var profile_id: UUID
}

struct DailyZoneExit: Identifiable, Codable {
    var id: UUID
    var date: Date
    var profile_id: UUID
    var zone_exit_id: UUID
    var exit_order: Int
    var points_earned: Int

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case profile_id
        case zone_exit_id
        case exit_order
        case points_earned
    }

    /// Custom decoding to handle the `yyyy-MM-dd` date format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(UUID.self, forKey: .id)
        self.profile_id = try container.decode(UUID.self, forKey: .profile_id)
        self.zone_exit_id = try container.decode(UUID.self, forKey: .zone_exit_id)
        self.exit_order = try container.decode(Int.self, forKey: .exit_order)
        self.points_earned = try container.decode(Int.self, forKey: .points_earned)

        // Custom decoding for the `date` field
        let dateString = try container.decode(String.self, forKey: .date)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let parsedDate = dateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .date,
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }
        self.date = parsedDate
    }

    /// Custom encoding to ensure the date is saved as `yyyy-MM-dd`
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(profile_id, forKey: .profile_id)
        try container.encode(zone_exit_id, forKey: .zone_exit_id)
        try container.encode(exit_order, forKey: .exit_order)
        try container.encode(points_earned, forKey: .points_earned)

        // Custom encoding for the `date` field
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        try container.encode(dateString, forKey: .date)
    }
}

struct GroupTotalPoints: Identifiable, Codable {
    var id: UUID
    var group_id: UUID
    var total_points: Int
}

struct UserTotalPoints: Identifiable, Codable {
    var id: UUID
    var profile_id: UUID
    var total_points: Int
}

struct DailyPoints: Identifiable, Codable {
    var id: UUID
    var profile_id: UUID
    var group_id: UUID?
    var points: Int
    var date: Date
}

struct CombinedDailyPoint: Identifiable {
    let id = UUID()
    let memberName: String
    let date: Date
    let points: Int
}

struct ZoneExit: Identifiable, Codable {
    var id: UUID
    var profile_id: UUID
    var zone_id: UUID
    var exit_time: Date

    enum CodingKeys: String, CodingKey {
        case id
        case profile_id
        case zone_id
        case exit_time
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.profile_id = try container.decode(UUID.self, forKey: .profile_id)
        self.zone_id = try container.decode(UUID.self, forKey: .zone_id)

        let dateString = try container.decode(String.self, forKey: .exit_time)
        if let date = DateFormatter.zoneExitSupabaseFormat.date(from: dateString) {
            self.exit_time = date
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .exit_time,
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }
    }
}

struct GroupCompetition: Identifiable, Hashable, Codable {
    var id: UUID
    var competition_name: String
    var competition_date: Date
    var max_points: Int
    var created_at: Date

    enum CodingKeys: String, CodingKey {
        case id
        case competition_name
        case competition_date
        case max_points
        case created_at
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

        self.id = try container.decode(UUID.self, forKey: .id)
        self.competition_name = try container.decode(String.self, forKey: .competition_name)
        self.max_points = try container.decode(Int.self, forKey: .max_points)

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
            throw DecodingError.dataCorruptedError(
                forKey: .competition_date,
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }

        if let createdAtDate = isoDateFormatter.date(from: createdAtString) {
            self.created_at = createdAtDate
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .created_at,
                in: container,
                debugDescription: "Invalid date format: \(createdAtString)"
            )
        }
    }
}

struct GroupCompetitionLink: Identifiable, Codable {
    var id: UUID
    var competition_id: UUID
    var group_id: UUID
}

struct FriendRelation: Codable {
    var friendship_id: UUID
    var profile_id1: UUID
    var profile_id2: UUID
}

struct DailyPoint: Identifiable, Codable {
    var id: UUID // Changed from computed property to unique UUID
    var profile_id: UUID
    var date: Date
    var points: Int

    enum CodingKeys: String, CodingKey {
        case profile_id
        case date
        case points
    }

    init(profile_id: UUID, date: Date, points: Int) {
        self.id = UUID() // Assign a unique UUID
        self.profile_id = profile_id
        self.date = date
        self.points = points
    }

    /// Custom decoding to handle the `yyyy-MM-dd` date format from UTC
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.profile_id = try container.decode(UUID.self, forKey: .profile_id)
        self.points = try container.decode(Int.self, forKey: .points)

        // Decode the date string from UTC `yyyy-MM-dd` format
        let dateString = try container.decode(String.self, forKey: .date)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let parsedDate = dateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .date,
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }
        self.date = parsedDate
        self.id = UUID() // Assign a unique UUID during decoding
    }

    /// Custom encoding to ensure the date is saved as `yyyy-MM-dd` in UTC
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(profile_id, forKey: .profile_id)
        try container.encode(points, forKey: .points)

        // Encode the date as a string in `yyyy-MM-dd` format in UTC
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        try container.encode(dateString, forKey: .date)
    }

    /// Helper method to get the date as a string in the user's local timezone
    func localDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current // User's local timezone
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }
}
