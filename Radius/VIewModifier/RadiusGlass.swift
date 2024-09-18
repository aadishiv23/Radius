//
//  RadiusGlass.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/3/24.
//

import Foundation
import SwiftUI

struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(15)
            .shadow(radius: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

extension View {
    func applyRadiusGlassStyle() -> some View {
        self.modifier(CardStyleModifier())
    }
}


// Custom View Modifier
struct BlueCardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.white.opacity(0.5), .clear]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}

// Modifier Extension for easier use
extension View {
    func blueCardStyle() -> some View {
        self.modifier(BlueCardStyleModifier())
    }
}
