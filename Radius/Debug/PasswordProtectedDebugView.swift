//
//  PasswordProtectedDebugView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/24/24.
//

import Foundation
import SwiftUI

struct PasswordProtectedDebugMenuView: View {
    @State private var password: String = ""
    @State private var isAuthenticated: Bool = false
    @State private var showAlert: Bool = false
    private let correctPassword: String = "testing123" // Replace with your desired password

    var body: some View {
        if isAuthenticated {
            DebugMenuView()
        } else {
            VStack {
                SecureField("Enter Debug Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Submit") {
                    verifyPassword()
                }
                .padding()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Incorrect Password"),
                    message: Text("Please try again."),
                    dismissButton: .default(Text("OK")) {
                        password = ""
                    }
                )
            }
        }
    }

    private func verifyPassword() {
        if password == correctPassword {
            isAuthenticated = true
        } else {
            showAlert = true
        }
    }
}
