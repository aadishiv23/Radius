//
//  SignInView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 10/18/24.
//

import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @Binding var isSignUp: Bool // Add binding to control sign in or sign up

    var body: some View {
        VStack {
            // FUCKFUCKFUCK
            SignInWithAppleButton(isSignUp ? .signUp : .signIn) { request in
                // authorization request for an Apple ID
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                // completion handler that is called when the sign-in completes
//                switch result {
//                case .success(let authorization):
//                    handleSuccessfulLogin(with: authorization)
//                case .failure(let error):
//                    handleLoginError(with: error)
//                }

                Task {
                    do {
                        guard let credential = try result.get().credential as? ASAuthorizationAppleIDCredential
                        else {
                            return
                        }

                        guard let idToken = credential.identityToken
                            .flatMap({ String(data: $0, encoding: .utf8) })
                        else {
                            return
                        }
                        try await supabase.auth.signInWithIdToken(
                            credentials: .init(
                                provider: .apple,
                                idToken: idToken
                            )
                        )
                    } catch {
                        dump(error)
                    }
                }
            }
            .frame(height: 50)
            .padding()
        }
    }

    private func handleSuccessfulLogin(with authorization: ASAuthorization) {
        if let userCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            print(userCredential.user)

            if userCredential.authorizedScopes.contains(.fullName) {
                print(userCredential.fullName?.givenName ?? "No given name")
            }

            if userCredential.authorizedScopes.contains(.email) {
                print(userCredential.email ?? "No email")
            }
        }
    }

    private func handleLoginError(with error: Error) {
        print("Could not authenticate: \(error.localizedDescription)")
    }
}
