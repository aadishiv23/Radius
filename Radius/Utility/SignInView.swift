//
//  SignInView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 10/18/24.
//

import AuthenticationServices
import SwiftUI

/// Direction Enum for Scrolling
enum ScrollDirection {
    case left
    case right
}

/// ScrollingRow Component
struct ScrollingRow: View {
    let direction: ScrollDirection
    let speed: Double
    let globeSize: CGFloat
    let globeSpacing: CGFloat
    let globeColor: Color

    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { _ in
            let totalWidth = (globeSize + globeSpacing) * 20 // Number of globes
            let animationDuration = totalWidth / 50 * speed // Adjust speed as needed

            HStack(spacing: globeSpacing) {
                ForEach(0..<20, id: \.self) { _ in
                    Image(systemName: "globe")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: globeSize, height: globeSize)
                        .foregroundColor(globeColor.opacity(0.2))
                }
                // Duplicate the globes for seamless scrolling
                ForEach(0..<20, id: \.self) { _ in
                    Image(systemName: "globe")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: globeSize, height: globeSize)
                        .foregroundColor(globeColor.opacity(0.2))
                }
            }
            .offset(x: offset)
            .onAppear {
                // Initialize offset based on direction
                offset = direction == .left ? 0 : -totalWidth / 2
                withAnimation(Animation.linear(duration: animationDuration).repeatForever(autoreverses: false)) {
                    offset = direction == .left ? -totalWidth / 2 : 0
                }
            }
        }
        .frame(height: 50) // Adjust height as needed
    }
}

/// Animated Globe Background Component
struct AnimatedGlobesBackground: View {
    let globeSize: CGFloat = 24
    let globeSpacing: CGFloat = 15
    let globeColor: Color = .blue

    var body: some View {
        GeometryReader { geometry in
            let rowHeight: CGFloat = 50
            let rowSpacing: CGFloat = 20
            let totalHeight = geometry.size.height
            // Calculate number of rows needed to cover the screen height
            let rowCount = Int(totalHeight / (rowHeight + rowSpacing)) + 4

            VStack(spacing: rowSpacing) {
                ForEach(0..<rowCount, id: \.self) { row in
                    ScrollingRow(
                        direction: row.isMultiple(of: 2) ? .left : .right,
                        speed: 15.0, // Duration for one full scroll (adjust as needed)
                        globeSize: globeSize,
                        globeSpacing: globeSpacing,
                        globeColor: globeColor
                    )
                    .frame(height: rowHeight)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}


/// Main Sign In View
struct SignInView: View {
    @State private var showEmailSignIn = false
    @Binding var isSignUp: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(
                    colors: colorScheme == .dark
                        ? [Color.black, Color.gray]
                        : [
                            Color.blue.opacity(0.3),
                            Color.purple.opacity(0.3)
                        ]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            // Animated Globes Background
            AnimatedGlobesBackground()
                .opacity(0.7)

            // Foreground Content
            VStack(spacing: 30) {
                Spacer()

                // App Icon
                Image(systemName: "mappin.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .shadow(radius: 10)

                // App Title
                Text("Radius")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 5)

                Spacer()

                // Sign-In Buttons
                VStack(spacing: 20) {
                    // Sign in with Apple
                    SignInWithAppleButton(isSignUp ? .signUp : .signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
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
                                
                                // Extract full name
                                let fullName = [
                                    credential.fullName?.givenName,
                                    credential.fullName?.familyName
                                ]
                                .compactMap { $0 }
                                .joined(separator: "")
                                
                                try await supabase.auth.signInWithIdToken(
                                    credentials: .init(provider: .apple, idToken: idToken)
                                )
                                
                                // Update full name in Supabase if available
                                if !fullName.isEmpty {
                                    let currentUser = try await supabase.auth.session.user
                                    try await supabase
                                       .from("profiles")
                                       .update(["full_name": fullName])
                                       .eq("id", value: currentUser.id)
                                       .execute()
                                }
                            } catch {
                                dump(error)
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(8)

                    // Continue with Email
                    Button(action: { showEmailSignIn = true }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .accessibilityHidden(true)
                            Text("Continue with Email")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                        .accessibilityLabel("Continue with Email")
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
            .padding()
        }
        .sheet(isPresented: $showEmailSignIn) {
            EmailSignInView(isSignUp: $isSignUp)
        }
    }
}

/// Email Sign In View
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

                if let result {
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

/// Tutorial View
struct TutorialView: View {
    @State private var currentPage = 0
    @Binding var showTutorial: Bool

    let tutorials: [(image: Image, title: String, description: String)] = [
        (
            image: Image("radius_pg_1"),
            title: "Explore the Home Screen",
            description: "Stay connected with friends, manage your zones, and view real-time locations on the map. Easily add new friends, manage requests, and immerse yourself in the fog of war map for a new perspective."
        ),
        (
            image: Image("radius_pg_2"),
            title: "Connect & Compete",
            description: "View friends' profiles, manage group activities, and join competitions. Strengthen connections while enjoying friendly challenges!"
        ),
        (
            image: Image("radius_pg_3"),
            title: "Track & Earn Points",
            description: "Score points through group activities and competitions. Analyze your progress in the analytics view with interactive charts and graphs for deeper insights."
        ),
        (
            image: Image("radius_pg_4"),
            title: "Personalize Your Profile",
            description: "Customize your profile settings, update your zones, and control privacy options to make the app truly yours."
        )
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
