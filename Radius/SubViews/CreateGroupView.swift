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
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Image or Icon
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding(.top, 20)
                    
                    // Group Information Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Name")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter group name", text: $groupName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .padding(.horizontal, 4)
                    }
                    .padding(.horizontal)
                    
                    // Password Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Security")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            SecureField("Create password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                            
                            SecureField("Confirm password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .onChange(of: confirmPassword) { _ in
                                    checkPasswordsMatch()
                                }
                            
                            // Password Feedback
                            if !confirmPassword.isEmpty {
                                HStack {
                                    Image(systemName: passwordMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(passwordMatch ? .green : .red)
                                    
                                    Text(passwordMatch ? "Passwords match" : "Passwords don't match")
                                        .font(.subheadline)
                                        .foregroundColor(passwordMatch ? .green : .red)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Create Button
                    Button(action: saveGroup) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(buttonColor)
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Group")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(height: 50)
                    .padding(.horizontal)
                    .disabled(!isValid || isLoading)
                    
                    // Help Text
                    Text("You'll need to share both the group name and password\nwith people you want to invite.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Done") {
                    isPresented = false
                }
                .disabled(!isValid)
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var isValid: Bool {
        !groupName.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && passwordMatch
    }
    
    private var buttonColor: Color {
        isValid && !isLoading ? .blue : .gray.opacity(0.5)
    }
    
    private func saveGroup() {
        isLoading = true
        
        Task {
            do {
                await friendsDataManager.createGroup(name: groupName, description: "A new group", password: password)
                let success = try await friendsDataManager.joinGroup(groupName: groupName, password: password)
                
                await MainActor.run {
                    isLoading = false
                    if success {
                        isPresented = false
                    } else {
                        alertMessage = "Failed to join the group. Please try again."
                        showAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    private func checkPasswordsMatch() {
        passwordMatch = password == confirmPassword
    }
}

//struct CreateGroupView_Previews: PreviewProvider {
//    static var previews: some View {
//        CreateGroupView(isPresented: .constant(true))
//            .environmentObject(FriendsDataManager())
//    }
//}
