//
//  CompetitionDetailViewModel.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/2/24.
//

import Foundation

class CompetitionDetailViewModel: ObservableObject {
    @Published var groups: [Group] = []
    @Published var playersInGroup: [UUID: [Profile]] = [:]
    @Published var totalUsers: Int = 0

    func fetchDetails(for competition: GroupCompetition) {
        // Fetch groups and players logic here, update groups, playersInGroup, and totalUsers
        // For the purpose of this code, this is a placeholder.
        // Fetch the necessary details using Supabase or your data source.
    }
}
