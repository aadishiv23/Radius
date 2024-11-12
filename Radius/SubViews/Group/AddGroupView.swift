//
//  AddGroupView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/5/24.
//

import Foundation
import SwiftUI

struct AddGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var groupName: String = ""
    @State private var groupDescription: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Group Name", text: $groupName)
                    TextField("Description", text: $groupDescription)
                } header: {
                    Text("Group Details")
                }
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Create")
                }
            }
            .navigationBarTitle("Add Group", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
