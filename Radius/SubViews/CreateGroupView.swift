//
//  CreateGroupView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/11/24.
//

import Foundation
import SwiftUI

struct CreateGroupView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @State private var groupName: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var passwordMatch: Bool = true
    @Binding var isPresented: Bool  // Binding to control the presentation


    var body: some View {
        Form {
            TextField("Group Name", text: $groupName)
            SecureField("Password", text: $password)
            SecureField("Confirm Password", text: $confirmPassword)
                .onChange(of: confirmPassword) { _ in
                    checkPasswordsMatch()
                }

            HStack {
                if !passwordMatch {
                    Text("Passwords do not match")
                        .foregroundColor(.red)
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                } else if passwordMatch && !confirmPassword.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            Button("Save") {
                // Only attempt to create the group if passwords match
                if passwordMatch {
                    Task {
                        await friendsDataManager.createGroup(name: groupName, description: "A new group", password: password)
                        isPresented = false
                    }
                }
            }
            Text("Please note down the password and group name.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Create Group")
        .navigationBarItems(trailing: Button("Done") {
            isPresented = false  
        })
    }

    private func checkPasswordsMatch() {
        passwordMatch = password == confirmPassword
    }
}
