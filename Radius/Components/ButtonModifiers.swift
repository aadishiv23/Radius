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
            .background(Color.white.opacity(0.9))
            .clipShape(Circle())
            .shadow(radius: 3)
    }
}

extension View {
    func circularButtonStyle() -> some View {
        modifier(CircleButtonStyle())
    }
}
