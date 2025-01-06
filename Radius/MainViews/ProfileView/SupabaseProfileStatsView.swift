//
//  SupabaseProfileStatsView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on [Current Date]
//

import SwiftUI

// MARK: - Stats View

/// Displays the user's profile statistics.
struct SupabaseProfileStatsView: View {
    let user: Profile

    var body: some View {
        HStack(spacing: 20) {
            ProfileStatItem(title: "Zones", value: "\(user.zones.count)", icon: "map.fill")
            ProfileStatItem(title: "Friends", value: "0", icon: "person.2.fill")
            ProfileStatItem(title: "Active", value: "Yes", icon: "circle.fill")
        }
        .padding()
        .background(Color.gray.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct ProfileStatItem: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.primary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.primary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}
