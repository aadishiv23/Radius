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
    @Binding var isPresented: Bool  // Binding to control the presentation


    var body: some View {
        NavigationView {
            Form {
                TextField("Group Name", text: $groupName)
                SecureField("Password", text: $password)
                Button("Join Group") {
                    Task {
                        joinGroup()
                    }
                }
            }
            .navigationTitle("Join Group")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isPresented = false
                    }, label: {
                        Text("Done")
                    })
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(joinSuccess == true ? "Success" : "Error"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
    }

    private func joinGroup() {
        guard !groupName.isEmpty, !password.isEmpty else {
            alertMessage = "Please fill in all fields."
            showAlert = true
            return
        }

        Task {
            let success = try await friendsDataManager.joinGroup(groupName: groupName, password: password)
            joinSuccess = success
            alertMessage = success ? "You have successfully joined the group." : "Failed to join the group. Check the details and try again."
            showAlert = true
        }
    }
}

