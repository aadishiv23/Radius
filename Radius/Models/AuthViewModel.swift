//
//  AuthViewModel.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/15/24.
//

import Foundation
import Combine
import Supabase
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupAuthListener()
    }

    private func setupAuthListener() {
        Task {
            for await state in await supabase.auth.authStateChanges {
                if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                    DispatchQueue.main.async {
                        self.isAuthenticated = state.session != nil
                    }
                }
            }
        }
    }
}

