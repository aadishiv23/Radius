//
//  CompetitionManagerViewModel.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 8/26/24.
//

import Foundation
import Foundation
import SwiftUI
import Supabase

class CompetitionManagerViewModel: ObservableObject {
    @Published var groups: [Group] = []
    private let competitionManager = CompetitionManager(supabaseClient: supabase)

    func fetchGroups() {
        Task {
            do {
                groups = try await competitionManager.fetchAllGroups()
            } catch {
                print("Failed to fetch groups: \(error)")
            }
        }
    }

    func createCompetition(name: String, date: Date, points: Int, groupIds: [UUID]) async throws -> GroupCompetition {
        return try await competitionManager.createCompetition(
            competitionName: name,
            competitionDate: date,
            maxPoints: points,
            groupIds: groupIds
        )
    }
}
