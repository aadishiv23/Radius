//
//  ActionScrollList.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 12/20/24.
//

import SwiftUI

// MARK: - ActionButton

private struct ActionButton: View {
    let imageName: String
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: imageName)
                    .font(.title3)
                Text(text)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle()) // Removes the default button highlight
        .foregroundColor(.primary)
    }
}

// MARK: - Flashy Extension

extension View {
    func flashy() -> some View {
        transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: UUID())
    }
}

// MARK: - ActionScrollList

struct ActionScrollList: View {
    let actions: [(imageName: String, text: String, action: () -> Void)] // Generic actions

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(actions, id: \.text) { action in
                    ActionButton(imageName: action.imageName, text: action.text, action: action.action)
                        .flashy()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Previews

struct ActionScrollList_Previews: PreviewProvider {
    static var previews: some View {
        ActionScrollList(actions: [
            (imageName: "star.fill", text: "Favorite", action: {}),
            (imageName: "bell.fill", text: "Alerts", action: {}),
            (imageName: "heart.fill", text: "Like", action: {})
        ])
        .preferredColorScheme(.light) // Light mode preview
        .previewDisplayName("Light Mode")
        
        ActionScrollList(actions: [
            (imageName: "star.fill", text: "Favorite", action: {}),
            (imageName: "bell.fill", text: "Alerts", action: {}),
            (imageName: "heart.fill", text: "Like", action: {})
        ])
        .preferredColorScheme(.dark) // Dark mode preview
        .previewDisplayName("Dark Mode")
    }
}
