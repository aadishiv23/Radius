//
//  CompetitionDetailView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 9/2/24.
//

import Foundation
import SwiftUI

struct CompetitionDetailView: View {
    let competition: GroupCompetition
    @StateObject private var viewModel = CompetitionDetailViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Competition Info Section
                Section(header: Text("Competition Info").font(.headline).foregroundColor(.primary)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Name: \(competition.competition_name)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Date: \(formattedDate(competition.competition_date))")
                        Text("Max Points: \(competition.max_points)")
                        Text("Number of Groups: \(viewModel.groups.count)")
                        Text("Number of Users: \(viewModel.totalUsers)")
                    }
                    .padding()
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(10)
                }

                // Groups and Players Section
                Section(header: Text("Groups and Players").font(.headline).foregroundColor(.primary)) {
                    ForEach(viewModel.groups, id: \.id) { group in
                        VStack(alignment: .leading) {
                            Text(group.name)
                                .font(.title3)
                                .fontWeight(.bold)
                            ForEach(viewModel.playersInGroup[group.id] ?? [], id: \.id) { player in
                                Text(player.full_name)
                                    .padding(.leading)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
                .padding(.top)

                // Stats Section
                Section(header: Text("Stats").font(.headline).foregroundColor(.primary)) {
                    VStack {
                        Image(systemName: "hammer")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Under Construction")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
                .padding(.top)
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.yellow.opacity(0.5)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
        )
        .navigationTitle("Competition Details")
        .onAppear {
            viewModel.fetchDetails(for: competition)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
