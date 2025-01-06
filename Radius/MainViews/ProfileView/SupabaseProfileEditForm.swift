//
//  SupabaseProfileEditForm.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on [Current Date]
//

import SwiftUI

// MARK: - Edit Profile Form

/// Form for editing the user's profile information.
struct SupabaseProfileEditForm: View {
    // MARK: - Properties

    @Binding var username: String
    @Binding var fullName: String
    @Binding var usernameError: String?
    @Binding var isCheckingUsername: Bool
    @Binding var isLoading: Bool

    let validateUsername: () -> Void
    let updateProfile: () -> Void
    let cancelEdit: () -> Void

    private var isFormValid: Bool {
        !username.isEmpty && !fullName.isEmpty && usernameError == nil && !isCheckingUsername
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            TextField("Full Name", text: $fullName)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                TextField("Username", text: $username)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .textInputAutocapitalization(.never)
                    .onChange(of: username) { _ in
                        validateUsername()
                    }

                if isCheckingUsername {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Checking username availability...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else if let error = usernameError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            HStack(spacing: 16) {
                Button(action: cancelEdit) {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: updateProfile) {
                    Text("Save")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!isFormValid)
            }

            if isLoading {
                ProgressView()
                    .padding(.top, 16)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

struct SupabaseProfileEditForm_Previews: PreviewProvider {
    static var previews: some View {
        SupabaseProfileEditForm(
            username: .constant("aadi123"),
            fullName: .constant("Aadi Shiv Malhotra"),
            usernameError: .constant(nil),
            isCheckingUsername: .constant(false),
            isLoading: .constant(false),
            validateUsername: {},
            updateProfile: {},
            cancelEdit: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
