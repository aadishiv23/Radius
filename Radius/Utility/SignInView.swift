//
//  SignInView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 10/18/24.
//

import AuthenticationServices
import SwiftUI

// Animated Globe Background Component
struct AnimatedGlobesBackground: View {
    let rowCount = 5
    let globesPerRow = 8
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(0..<rowCount, id: \.self) { row in
                HStack(spacing: 15) {
                    ForEach(0..<globesPerRow, id: \.self) { _ in
                        Image(systemName: "globe")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .opacity(0.2)
                            .rotationEffect(.degrees(360))
                            .animation(
                                Animation.linear(duration: row.isMultiple(of: 2) ? 4 : 2)
                                    .repeatForever(autoreverses: false),
                                value: 360
                            )
                    }
                }
                .offset(x: row.isMultiple(of: 2) ? 20 : -20)
            }
        }
    }
}

// Main Sign In View
struct SignInView: View {
    @State private var showEmailSignIn = false
    @Binding var isSignUp: Bool
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            AnimatedGlobesBackground()
            
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "mappin.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("Radius")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                
                Spacer()
                
                VStack(spacing: 16) {
                    SignInWithAppleButton(isSignUp ? .signUp : .signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task {
                            do {
                                guard let credential = try result.get().credential as? ASAuthorizationAppleIDCredential else { return }
                                guard let idToken = credential.identityToken.flatMap({ String(data: $0, encoding: .utf8) }) else { return }
                                try await supabase.auth.signInWithIdToken(
                                    credentials: .init(provider: .apple, idToken: idToken)
                                )
                            } catch {
                                dump(error)
                            }
                        }
                    }
                    .frame(height: 50)
                    
                    Button(action: { showEmailSignIn = true }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Continue with Email")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showEmailSignIn) {
            EmailSignInView(isSignUp: $isSignUp)
        }
    }
}

// Email Sign In View
struct EmailSignInView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isSignUp: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var result: Result<Void, Error>?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                
                VStack(spacing: 20) {
                    CustomTextField(text: $email, placeholder: "Email", imageName: "envelope")
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    CustomTextField(text: $password, placeholder: "Password", imageName: "lock", isSecure: true)
                }
                .padding(.horizontal)
                
                if isLoading {
                    ProgressView()
                }
                
                Button(action: isSignUp ? signUpWithEmail : signInWithEmail) {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Button("Switch to \(isSignUp ? "Sign In" : "Sign Up")") {
                    withAnimation {
                        isSignUp.toggle()
                    }
                }
                
                if let result = result {
                    ResultView(result: result, isSignUp: isSignUp)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
        }
    }
    
    private func signInWithEmail() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await supabase.auth.signIn(email: email, password: password)
                result = .success(())
                dismiss()
            } catch {
                result = .failure(error)
            }
        }
    }
    
    private func signUpWithEmail() {
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

// Tutorial View
struct TutorialView: View {
    @State private var currentPage = 0
    @Binding var showTutorial: Bool
    
    let tutorials: [(image: Image, title: String, description: String)] = [
        (image: Image("radius_pg_1"), title: "Explore the Home Screen", description: "Stay connected with friends, manage your zones, and view real-time locations on the map. Easily add new friends, manage requests, and immerse yourself in the fog of war map for a new perspective."),
        (image: Image("radius_pg_2"), title: "Connect & Compete", description: "View friends' profiles, manage group activities, and join competitions. Strengthen connections while enjoying friendly challenges!"),
        (image: Image("radius_pg_3"), title: "Track & Earn Points", description: "Score points through group activities and competitions. Analyze your progress in the analytics view with interactive charts and graphs for deeper insights."),
        (image: Image("radius_pg_4"), title: "Personalize Your Profile", description: "Customize your profile settings, update your zones, and control privacy options to make the app truly yours.")
    ]
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<tutorials.count, id: \.self) { index in
                        GeometryReader { geometry in
                            VStack(spacing: 0) {
                                // Image Container
                                tutorials[index].image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: geometry.size.height * 0.6)
                                    .clipped()
                                
                                // Content Container
                                VStack(spacing: 20) {
                                    Text(tutorials[index].title)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.center)
                                    
                                    Text(tutorials[index].description)
                                        .font(.body)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 32)
                                .padding(.bottom, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 0))
                            .background(Color.white)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                // Button Container
                Button(action: {
                    if currentPage == tutorials.count - 1 {
                        showTutorial = false
                    } else {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                }) {
                    Text(currentPage == tutorials.count - 1 ? "Get Started" : "Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.white)
            }
        }
    }
}
