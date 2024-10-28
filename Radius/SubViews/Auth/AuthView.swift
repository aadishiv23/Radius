//
//  AuthView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/7/24.
//

import AuthenticationServices
import Foundation
import Supabase
import SwiftUI

struct AuthView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var result: Result<Void, Error>?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.yellow.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 25) {
                    Text(isSignUp ? "Create Your Account" : "Welcome Back")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    // Animated logo
                    Image(systemName: "mappin.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .shadow(color: .yellow.opacity(0.3), radius: 10, x: 0, y: 5)
                        .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
                        .animation(Animation.linear(duration: 2).repeatForever(autoreverses: true), value: isLoading)
                    
                    VStack(spacing: 20) {
                        CustomTextField(text: $email, placeholder: "Email", imageName: "envelope")
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                        CustomTextField(text: $password, placeholder: "Password", imageName: "lock", isSecure: true)
                    }
                    .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.5)
                    }
                    
                    Button(action: isSignUp ? signUpWithEmailPassword : signInWithEmailPassword) {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .fontWeight(.semibold)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.yellow]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(5)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)
                    
                    SignInView(isSignUp: $isSignUp) // Pass `isSignUp` binding to SignInView
                    
                    if !isSignUp {
                        NavigationLink(destination: ChangePasswordView()) {
                            Text("Forgot Password?")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button("Switch to \(isSignUp ? "Sign In" : "Sign Up")") {
                        withAnimation {
                            isSignUp.toggle()
                        }
                    }
                    .foregroundColor(.secondary)
                    
                    if let result = result {
                        ResultView(result: result, isSignUp: isSignUp)
                    }
                }
                .padding()
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                .padding()
            }
        }
    }
    
    private func signInWithEmailPassword() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await supabase.auth.signIn(email: email, password: password)
                await friendsDataManager.fetchCurrentUserProfile()
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

struct CustomTextField: View {
    @Binding var text: String
    var placeholder: String
    var imageName: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
            
            Spacer()
            
            Image(systemName: imageName)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

struct ResultView: View {
    let result: Result<Void, Error>
    let isSignUp: Bool
    
    var body: some View {
        switch result {
        case .success:
            Text(isSignUp ? "Signup successful, please verify your email if required." : "Logged in successfully")
                .foregroundColor(.green)
                .padding()
                .background(Color.green.opacity(0.2))
                .cornerRadius(10)
        case .failure(let error):
            Text(error.localizedDescription)
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.2))
                .cornerRadius(10)
        }
    }
}
