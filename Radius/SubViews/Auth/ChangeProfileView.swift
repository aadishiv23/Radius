//
//  ChangeProfileView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 10/27/24.
//

import Foundation
import SwiftUI

struct ChangePasswordView: View {
    @State private var email: String = ""
    @State private var isLoading = false
    @State private var result: Result<Void, Error>?

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
            
            Button("Send Reset Password Email") {
                sendResetPasswordEmail()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            
            if isLoading {
                ProgressView()
            }
            
            if let result = result {
                Section {
                    switch result {
                    case .success:
                        Text("Password reset email sent successfully").foregroundColor(.green)
                    case .failure(let error):
                        Text(error.localizedDescription).foregroundStyle(.red)
                    }
                }
            }
        }
    }
    
    private func sendResetPasswordEmail() {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                try await supabase.auth.resetPasswordForEmail(email)
                result = .success(())
            } catch {
                result = .failure(error)
            }
        }
    }
}
