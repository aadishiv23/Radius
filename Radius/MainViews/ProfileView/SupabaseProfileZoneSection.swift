//
//  SupabaseProfileZonesSection.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on [Current Date]
//

import SwiftUI
import CoreLocation

// MARK: - Zones Section View

/// Displays the user's zones in a horizontal scrollable view.
struct SupabaseProfileZonesSection: View {
    // MARK: - Properties
    
    let currentUser: Profile?
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Zones")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                NavigationLink(destination: ZoneGridView()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if let user = currentUser {
                        ForEach(user.zones) { zone in
                            ZoneCard(zone: zone)
                        }
                    } else {
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Preview
//
//struct SupabaseProfileZonesSection_Previews: PreviewProvider {
//    static var previews: some View {
//        SupabaseProfileZonesSection(
//            currentUser: Profile(full_name: "Aadi Shiv Malhotra", username: "aadi123", zones: [])
//        )
//        .previewLayout(.sizeThatFits)
//        .padding()
//    }
//}
