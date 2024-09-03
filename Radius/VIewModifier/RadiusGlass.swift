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

