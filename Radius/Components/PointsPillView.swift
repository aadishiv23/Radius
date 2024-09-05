//
//  PointsPillView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/4/24.
//

import Foundation
import SwiftUI

struct PointsPillView: View {
    var points: Int?
    
    var body: some View {
        HStack {
            Image(systemName: "dollarsign.circle.fill") // Replace with your coin image if available
                .foregroundColor(.yellow)
                .font(.system(size: 24, weight: .bold))
            Text(points != nil ? "\(points!) pts" : "N/A")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.2))
        .clipShape(Capsule())
        .shadow(color: Color.gray.opacity(0.4), radius: 4, x: 0, y: 2)
    }
}
