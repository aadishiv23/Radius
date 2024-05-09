//
//  AuthView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/7/24.
//

import Foundation
import SwiftUI
import Supabase

struct AuthView: View {
    @State var email: String = ""
    @State var isLoading = false
    @State var result: Result<Void, Error>?
    @Binding var isAuthenticated: Bool


    var body: some View {
        Form {
            Section {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            
            Section {
                Button("Sign In") {
                    signInButtonTapped()
                }
                
                if isLoading {
                    ProgressView()
                }
            }
            
            if let result {
                Section {
                    switch result {
                    case .success:
                        Text("Check your inbox")
                    case .failure(let error):
                        Text(error.localizedDescription).foregroundStyle(.red)

                    }
                }
            }
        }
        .onOpenURL(perform: { url in
              Task {
                do {
                  try await supabase.auth.session(from: url)
                } catch {
                  self.result = .failure(error)
                }
              }
            })
    }
    
    func signInButtonTapped() {
        Task {
            isLoading = true
            defer {isLoading = false}
            
            do {
                try await supabase.auth.signInWithOTP(email: email,
                                                redirectTo: URL(string:"io.supabase.user-management://radius-login-callback"))
                isAuthenticated = true
                result = .success(())
            } catch {
                result = .failure(error)
            }
        }
    }
}
