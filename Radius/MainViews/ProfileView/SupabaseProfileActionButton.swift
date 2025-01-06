//
//  SupabaseProfileActionButtons.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on [Current Date]
//

import SwiftUI

// MARK: - Action Buttons Group

/// A set of buttons for profile actions like Update, Sign Out, and Delete Account.
struct SupabaseProfileActionButtons: View {
    // MARK: - Properties

    @Binding var isLoading: Bool
    let updateProfile: () -> Void
    let signOut: () -> Void
    let deleteAccount: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            Button(action: updateProfile) {
                HStack {
                    Text("Update Profile")
                        .fontWeight(.semibold)
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading)

            Button(action: signOut) {
                Text("Sign Out")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.3))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button(action: showDeleteAccountConfirmation) {
                Text("Delete Account")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.6))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Private Methods

    private func showDeleteAccountConfirmation() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "Are you sure you want to delete your account? This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            deleteAccount()
        })

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController
        {
            rootVC.present(alert, animated: true)
        }
    }
}

// MARK: - Preview

struct SupabaseProfileActionButtons_Previews: PreviewProvider {
    static var previews: some View {
        SupabaseProfileActionButtons(
            isLoading: .constant(false),
            updateProfile: {},
            signOut: {},
            deleteAccount: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
