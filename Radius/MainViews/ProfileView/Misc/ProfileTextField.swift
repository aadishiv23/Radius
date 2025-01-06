//
//  ProfileTextField.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on [Current Date]
//

import SwiftUI

// MARK: - Profile TextField

/// A reusable styled text field for profile inputs.
struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            TextField(title, text: $text)
                .autocapitalization(.none)
                .textContentType(title == "Full Name" ? .name : .username)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
