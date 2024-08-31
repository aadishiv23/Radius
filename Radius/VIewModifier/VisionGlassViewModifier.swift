//
//  VisionGlassViewModifier.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 8/31/24.
//

import Foundation
import SwiftUI

struct VisionGlass: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(10)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)  // Softer shadow for subtle elevation
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(12)
            .padding(.horizontal)
    }
}

extension View {
    func visionGlass() -> some View {
        self.modifier(VisionGlass())
    }
}
