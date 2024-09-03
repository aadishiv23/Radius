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
    @State private var selectedGroup: Group?
    @State private var isAnimating = false
    
    // MARK: - Main View
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                competitionInfoSection
                groupsAndPlayersSection
                statsSection
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
            Task {
                await viewModel.fetchDetails(for: competition)
                selectedGroup = nil
            }
        }
    }

    // MARK: - Subviews
    
    private var competitionInfoSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("Name: \(competition.competition_name)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Date: \(formattedDate(competition.competition_date))")
                Text("Max Points: \(competition.max_points)")
                Text("Number of Groups: \(viewModel.groups.count)")
                Text("Number of Users: \(viewModel.totalUsers)")
            }
            Spacer()  // Push the content to the left while allowing the background to stretch
        }
        .applyRadiusGlassStyle()
    }


    private var groupsAndPlayersSection: some View {
          VStack(alignment: .leading, spacing: 10) {
              Text("Groups and Players")
                  .font(.title2)
                  .fontWeight(.bold)
                  .foregroundColor(.primary)
              
              CustomGroupPicker(
                  selection: $selectedGroup,
                  groups: viewModel.groups
              )
              
              if let group = selectedGroup, let players = viewModel.playersInGroup[group.id] {
                  PlayerList(players: players, isAnimating: $isAnimating)
              } else {
                  Text("Select a group to view players.")
                      .foregroundColor(.secondary)
                      .frame(maxWidth: .infinity, alignment: .center)
                      .padding()
                      .background(Color.white.opacity(0.1))
                      .cornerRadius(10)
              }
          }
          .applyRadiusGlassStyle()
          .onChange(of: selectedGroup) { _ in
              isAnimating = false
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                  withAnimation(.easeOut(duration: 0.5)) {
                      isAnimating = true
                  }
              }
          }
      }

    private var statsSection: some View {
        Section(header: Text("Stats").font(.headline).foregroundColor(.primary).frame(maxWidth: .infinity, alignment: .leading)) {
            VStack {
                Image(systemName: "hammer")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                Text("Under Construction")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .applyRadiusGlassStyle()
        }
        .padding(.top)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}


struct CustomGroupPicker: View {
    @Binding var selection: Group?
    let groups: [Group]
    
    var body: some View {
        Menu {
            ForEach(groups, id: \.id) { group in
                Button(action: {
                    selection = group
                }) {
                    Text(group.name)
                }
            }
        } label: {
            HStack {
                Text(selection?.name ?? "Select a Group")
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.white.opacity(0.5))
            .cornerRadius(10)
        }
    }
}

struct PlayerList: View {
    let players: [Profile]
    @Binding var isAnimating: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                    Text(player.full_name)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.3))
                .cornerRadius(8)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.5)
                    .delay(Double(index) * 0.05),
                    value: isAnimating
                )
            }
        }
    }
}
