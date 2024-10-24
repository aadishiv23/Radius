//
//  ButtonModifiers.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/25/24.
//

import Foundation
import SwiftUI

struct CircleButtonStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                colorScheme == .light ? Color.white.opacity(0.9) : Color.black.opacity(0.7)
            )
            .clipShape(Circle())
            .shadow(color: .gray.opacity(0.4), radius: 3)
    }
}

extension View {
    func circularButtonStyle() -> some View {
        modifier(CircleButtonStyle())
    }
}

