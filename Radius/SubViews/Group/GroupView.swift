//
//  GroupView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/11/24.
//

import Foundation
import SwiftUI

struct GroupView: View {
    var group: Group
    @State private var isCopied = false // Track when the password has been copied

    var body: some View {
        NavigationLink(destination: GroupDetailView(group: group)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    Text(group.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Password")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(group.plain_password ?? "N/A")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    Spacer()

                    Button(action: {
                        UIPasteboard.general.string = group.plain_password
                        showCopiedStatus() // Show "Copied!" when the password is copied
                    }) {
                        Text(isCopied ? "Copied!" : "Copy Password")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isCopied ? Color.green : Color.blue)
                            .cornerRadius(8)
                    }
                }

                HStack {
                    Text(group.description ?? "No description available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .blueCardStyle()
        }
    }

    // MARK: - Function to Show Copied Status

    private func showCopiedStatus() {
        isCopied = true

        // Automatically reset the button after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isCopied = false
        }
    }
}
