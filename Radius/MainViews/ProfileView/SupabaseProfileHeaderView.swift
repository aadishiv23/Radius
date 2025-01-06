//
//  SupabaseProfileHeaderView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on [Current Date]
//

import SwiftUI

struct SupabaseProfileHeaderView: View {
    // MARK: - Properties

    let fullName: String
    let username: String
    @State private var isAnimating = false

    // MARK: - View Components

    private var profileImage: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .foregroundColor(.white)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 110, height: 110)
                    .overlay(
                        Circle()
                            .stroke(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 3)
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(.easeInOut(duration: 1)) {
                    isAnimating = true
                }
            }
    }

    private var userInfo: some View {
        VStack(spacing: 8) {
            Text(fullName)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("@\(username)")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
        }
    }

    // MARK: - Body

    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 20) {
                profileImage
                    .padding(.top, 20)

                userInfo
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: isAnimating)
            }
            Spacer()
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity) // Makes the background stretch horizontally
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.gray.opacity(0.1))
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
        .padding(.horizontal) // Adds padding around the entire view
    }
}
