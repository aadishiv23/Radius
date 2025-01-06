//
//  EnhancedZoneCard.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on [Current Date]
//

import SwiftUI
import MapKit

// MARK: - Enhanced Zone Card

/// A detailed view displaying a zone snapshot and its information.
struct EnhancedZoneCard: View {
    var zone: Zone
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MapViewSnapshot(
                coordinate: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude),
                radius: zone.radius
            )
            .frame(width: 200, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            
            Text(zone.name)
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Label("\(Int(zone.radius))m", systemImage: "ruler")
                Spacer()
                Label("Active", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .frame(width: 200)
        .background(Color.gray.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ZoneCard: View {
    var zone: Zone

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Map Snapshot
            MapViewSnapshot(
                coordinate: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude),
                radius: zone.radius
            )
            .frame(height: 100)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 1)
            )
            .shadow(radius: 3)

            // Zone Name
            Text(zone.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)

            // Zone Details
            HStack(spacing: 5) {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                Text("Radius: \(zone.radius)m")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 5) {
                Image(systemName: "map")
                    .foregroundColor(.green)
                Text(String(format: "Lat: %.4f, Lon: %.4f", zone.latitude, zone.longitude))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        .frame(width: 180)
    }
}
