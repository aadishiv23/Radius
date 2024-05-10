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

struct ChangePasswordView: View {
    @State private var password: String = ""
    @State private var passwordReconfirm: String = ""
    @State private var isLoading = false
    @State private var result: Result<Void, Error>?

    var body: some View {
        VStack {
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            
            SecureField("Reconfirm", text: $passwordReconfirm)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            
            Button("Reset") {
                resetPassword()
            }
            
            if let result = result {
                Section {
                    switch result {
                    case .success:
                        Text("Password reset succesfully").foregroundColor(.green)
                    case .failure(let error):
                        Text(error.localizedDescription).foregroundStyle(.red)
                    }
                }
            }
        }
    }
    
    private func resetPassword() {
        Task {
            isLoading = true
            defer {isLoading = false }
            do {
                try await supabase.auth.update(user: UserAttributes(password: password))
                result = .success(())
            } catch {
                result = .failure(error)
            }
        }
    }
}

struct AuthView: View {
    @Binding var isAuthenticated: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUp = false // Toggle between sign up and sign in
    @State private var isLoading = false
    @State private var result: Result<Void, Error>?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(isSignUp ? "Create Your Account" : "Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Image(systemName: "map.fill")
                    .resizable()
                    .frame(width: 200, height: 200)
                Spacer()
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .overlay(HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.gray)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                                .padding(.trailing, 25)
                        })

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .overlay(HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.gray)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                                .padding(.trailing, 30)
                        })
                }
                
                if isLoading {
                    ProgressView()
                }
                
                Button(action: isSignUp ? signUpWithEmailPassword : signInWithEmailPassword) {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .fontWeight(.semibold)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 20)

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
                    Section {
                        switch result {
                        case .success:
                            Text(isSignUp ? "Signup successful, please verify your email if required." : "Logged in successfully").foregroundColor(.green)
                        case .failure(let error):
                            Text(error.localizedDescription).foregroundStyle(.red)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            //.navigationTitle(isSignUp ? "Sign Up" : "Sign In")
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
     @Binding var isAuthenticated: Bool
     @State private var email: String = ""
     @State private var password: String = ""
     @State private var isSignUp = false // Toggle between sign up and sign in
     @State private var isLoading = false
     @State private var result: Result<Void, Error>?
     
     var body: some View {
         NavigationView {
             VStack(spacing: 20) {
                 Text(isSignUp ? "Create Your Account" : "Welcome Back")
                     .font(.largeTitle)
                     .fontWeight(.bold)
                 
                 VStack(spacing: 15) {
                     TextField("Email", text: $email)
                         .padding()
                         .background(Color(.systemGray6))
                         .cornerRadius(10)
                         .padding(.horizontal)
                         .textInputAutocapitalization(.never)
                         .autocorrectionDisabled()
                         .keyboardType(.emailAddress)
                         .overlay(HStack {
                             Image(systemName: "envelope")
                                 .foregroundColor(.gray)
                                 .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                 .padding(.leading, 15)
                         })

                     SecureField("Password", text: $password)
                         .padding()
                         .background(Color(.systemGray6))
                         .cornerRadius(10)
                         .padding(.horizontal)
                         .overlay(HStack {
                             Image(systemName: "lock")
                                 .foregroundColor(.gray)
                                 .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                 .padding(.leading, 15)
                         })
                 }
                 
                 if isLoading {
                     ProgressView()
                 }
                 
                 Button(action: isSignUp ? signUpWithEmailPassword : signInWithEmailPassword) {
                     Text(isSignUp ? "Sign Up" : "Sign In")
                         .fontWeight(.semibold)
                         .frame(minWidth: 0, maxWidth: .infinity)
                         .padding()
                         .foregroundColor(.white)
                         .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                         .cornerRadius(10)
                 }
                 .padding(.horizontal)
                 .padding(.top, 20)

                 if !isSignUp {
                     NavigationLink(destination: ForgotPasswordView()) {
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
                 
                 Spacer()
             }
             .padding()
             .navigationTitle(isSignUp ? "Sign Up" : "Sign In")
             .alert(item: $result) { result in
                 switch result {
                 case .success:
                     return Alert(title: Text("Success"), message: Text(isSignUp ? "Please check your email to verify." : "You are successfully logged in!"), dismissButton: .default(Text("OK")))
                 case .failure(let error):
                     return Alert(title: Text("Error"), message: Text(error.localizedDescription), dismissButton: .default(Text("OK")))
                 }
             }
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

 
 */
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
