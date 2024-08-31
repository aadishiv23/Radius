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
    @Published var needsProfileSetup = false
    private var cancellables = Set<AnyCancellable>()
    var friendsDataManager: FriendsDataManager?

    init(friendsDataManager: FriendsDataManager) {
        self.friendsDataManager = friendsDataManager
        setupAuthListener()
    }

    private func setupAuthListener() {
        Task {
            for await state in await supabase.auth.authStateChanges {
                if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                    DispatchQueue.main.async {
                        self.isAuthenticated = state.session != nil
                        if self.isAuthenticated {
                            Task {
                                await self.friendsDataManager?.fetchCurrentUserProfile()
                                if let profile = self.friendsDataManager?.currentUser,
                                   profile.full_name.isEmpty || profile.username.isEmpty {
                                    self.needsProfileSetup = true
                                } else {
                                    self.needsProfileSetup = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

