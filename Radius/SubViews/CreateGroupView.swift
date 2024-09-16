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
        NavigationView {
            VStack(spacing: 20) {
                Form {
                    Section(header: Text("Group Information")) {
                        TextField("Group Name", text: $groupName)
                            .padding()
                            .background(Color.gray.opacity(0.2).cornerRadius(10))
                    }
                    
                    Section(header: Text("Set a Password")) {
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.gray.opacity(0.2).cornerRadius(10))
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(Color.gray.opacity(0.2).cornerRadius(10))
                            .onChange(of: confirmPassword) { _ in
                                checkPasswordsMatch()
                            }
                        
                        passwordFeedbackView
                    }
                    
                    Button(action: saveGroup) {
                        Text("Create Group")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(passwordMatch ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.vertical)
                    }
                    .disabled(!passwordMatch)
                    
                    Text("Please note down the password and group name.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                }
                .navigationTitle("Create Group")
                .navigationBarItems(trailing: Button("Done") {
                    isPresented = false
                })
            }
            .padding()
        }
    }
    
    private var passwordFeedbackView: some View {
        HStack {
            if !passwordMatch {
                Text("Passwords do not match")
                    .foregroundColor(.red)
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            } else if !confirmPassword.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                ProgressView()
            }
        }
        .padding(.top, 10)
    }
    
    private func saveGroup() {
        // Save group only if passwords match
        if passwordMatch {
            Task {
                await friendsDataManager.createGroup(name: groupName, description: "A new group", password: password)
                let val = try await friendsDataManager.joinGroup(groupName: groupName, password: password)
                if val {
                    print("works")
                } else {
                    print("bruh no work")
                }
                isPresented = false
            }
        }
    }
    
    private func checkPasswordsMatch() {
        passwordMatch = password == confirmPassword
    }
}
