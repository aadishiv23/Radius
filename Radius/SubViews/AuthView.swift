//
//  AuthView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/7/24.
//

import Foundation
import SwiftUI
import Supabase
import AuthenticationServices


struct AuthView: View {
    @Binding var isAuthenticated: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUp = false // Toggle between sign up and sign in
    @State private var isLoading = false
    @State private var result: Result<Void, Error>?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(isSignUp ? "Sign Up" : "Sign In")) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(.password)

                    if isSignUp {
                        Button("Sign Up") {
                            signUpWithEmailPassword()
                        }
                    } else {
                        Button("Sign In") {
                            signInWithEmailPassword()
                        }

                        Button("Forgot Password?") {
                            // Handle forgotten password logic
                        }
                    }
                }

                Section {
                    Button(isSignUp ? "Already have an account? Sign In" : "Need an account? Sign Up") {
                        isSignUp.toggle()
                    }

                    if isLoading {
                        ProgressView()
                    }
                }

                if let result = result {
                    Section {
                        switch result {
                        case .success:
                            Text(isSignUp ? "Signup successful, please verify your email if required." : "Logged in successfully").foregroundColor(.green)
                        case .failure(let error):
                            Text(error.localizedDescription).foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationBarTitle(isSignUp ? "Sign Up" : "Sign In")
        }
    }

    private func signInWithEmailPassword() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await supabase.auth.signIn(email: email, password: password)
                isAuthenticated = true
                result = .success(())
            } catch {
                result = .failure(error)
            }
        }
    }

    private func signUpWithEmailPassword() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await supabase.auth.signUp(email: email, password: password)
                result = .success(())
            } catch {
                result = .failure(error)
            }
        }
    }
}
    /*
     
     struct AuthView: View {
     @State var email: String = ""
     @State var password: String = ""
     @State var isLoading = false
     @State var result: Result<Void, Error>?
     @Binding var isAuthenticated: Bool
     
     
     var body: some View {
     Form {
     
     
     Divider()
     Text("OR")
     
     Section(header: Text("Magic Link")) {
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
     
     
     */
