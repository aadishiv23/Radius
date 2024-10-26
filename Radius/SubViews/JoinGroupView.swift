//
//  JoinGroupView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/11/24.
//

import Foundation
import SwiftUI

struct JoinGroupView: View {
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @State private var groupName: String = ""
    @State private var password: String = ""
    @State private var joinSuccess: Bool?
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isLoading: Bool = false
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Icon
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding(.top, 20)
                    
                    // Group Information Section
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Group Name")
                                .font(.headline)
                            
                            TextField("Enter group name", text: $groupName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                            
                            SecureField("Enter group password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Join Button
                    Button(action: { Task { await joinGroup() } }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isValid ? Color.blue : Color.gray.opacity(0.5))
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Join Group")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(height: 50)
                    .padding(.horizontal)
                    .disabled(!isValid || isLoading)
                    
                    // Help Text
                    Text("Ask the group creator for the name and password")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationTitle("Join Group")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Done") {
                    isPresented = false
                }
                .disabled(joinSuccess != true)
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(joinSuccess == true ? "Success" : "Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if joinSuccess == true {
                            isPresented = false
                        }
                    }
                )
            }
        }
    }
    
    private var isValid: Bool {
        !groupName.isEmpty && !password.isEmpty
    }
    
    private func joinGroup() async {
        guard isValid else {
            alertMessage = "Please fill in all fields."
            showAlert = true
            return
        }
        
        isLoading = true
        
        do {
            let success = try await friendsDataManager.joinGroup(groupName: groupName, password: password)
            joinSuccess = success
            alertMessage = success ?
                "You have successfully joined the group." :
                "Failed to join the group. Check the details and try again."
        } catch {
            joinSuccess = false
            alertMessage = error.localizedDescription
        }
        
        isLoading = false
        showAlert = true
    }
}

//struct JoinGroupView_Previews: PreviewProvider {
//    static var previews: some View {
//        JoinGroupView(isPresented: .constant(true))
//            .environmentObject(FriendsDataManager())
//    }
//}

