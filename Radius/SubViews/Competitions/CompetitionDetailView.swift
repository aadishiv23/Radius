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

/*
 import SwiftUI

 struct CompetitionDetailView: View {
     let competition: GroupCompetition
     @StateObject private var viewModel = CompetitionDetailViewModel()
     @State private var selectedGroup: Group?
     @State private var isAnimating = false
     
     var body: some View {
         ScrollView {
             VStack(spacing: 24) {
                 // Hero Section
                 ZStack {
                     RoundedRectangle(cornerRadius: 20)
                         .fill(LinearGradient(
                             colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing
                         ))
                         .frame(height: 200)
                     
                     VStack(spacing: 16) {
                         Text(competition.competition_name)
                             .font(.system(size: 28, weight: .bold))
                             .foregroundColor(.white)
                         
                         HStack(spacing: 24) {
                             competitionStat(title: "Groups", value: "\(viewModel.groups.count)")
                             Divider().frame(height: 40).background(Color.white.opacity(0.3))
                             competitionStat(title: "Players", value: "\(viewModel.totalUsers)")
                             Divider().frame(height: 40).background(Color.white.opacity(0.3))
                             competitionStat(title: "Max Points", value: "\(competition.max_points)")
                         }
                         
                         Text(formattedDate(competition.competition_date))
                             .font(.subheadline)
                             .foregroundColor(.white.opacity(0.9))
                     }
                 }
                 .padding(.horizontal)
                 
                 // Groups Section
                 VStack(alignment: .leading, spacing: 16) {
                     HStack {
                         Text("Competing Groups")
                             .font(.title3)
                             .fontWeight(.bold)
                         
                         Spacer()
                         
                         Image(systemName: "trophy.fill")
                             .foregroundColor(.yellow)
                     }
                     .padding(.horizontal)
                     
                     CustomGroupPicker(selection: $selectedGroup, groups: viewModel.groups)
                         .padding(.horizontal)
                     
                     if let group = selectedGroup, let players = viewModel.playersInGroup[group.id] {
                         PlayerList(players: players, isAnimating: $isAnimating)
                             .padding(.top, 8)
                     } else {
                         emptyGroupState
                     }
                 }
                 .padding(.vertical)
                 .background(
                     RoundedRectangle(cornerRadius: 20)
                         .fill(Color.white.opacity(0.1))
                         .shadow(radius: 5)
                 )
                 .padding(.horizontal)
                 
                 // Leaderboard Preview
                 VStack(alignment: .leading, spacing: 16) {
                     HStack {
                         Text("Leaderboard")
                             .font(.title3)
                             .fontWeight(.bold)
                         
                         Spacer()
                         
                         Image(systemName: "chart.bar.fill")
                             .foregroundColor(.green)
                     }
                     
                     ScrollView(.horizontal, showsIndicators: false) {
                         HStack(spacing: 16) {
                             ForEach(viewModel.groups) { group in
                                 leaderboardCard(for: group)
                             }
                         }
                         .padding(.horizontal)
                     }
                 }
                 .padding()
                 .background(
                     RoundedRectangle(cornerRadius: 20)
                         .fill(Color.white.opacity(0.1))
                         .shadow(radius: 5)
                 )
                 .padding(.horizontal)
             }
             .padding(.vertical)
         }
         .background(
             LinearGradient(
                 colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                 startPoint: .top,
                 endPoint: .bottom
             )
             .ignoresSafeArea()
         )
         .navigationBarTitleDisplayMode(.inline)
         .onAppear {
             Task {
                 await viewModel.fetchDetails(for: competition)
                 selectedGroup = nil
             }
         }
     }
     
     private func competitionStat(title: String, value: String) -> some View {
         VStack(spacing: 4) {
             Text(value)
                 .font(.system(size: 24, weight: .bold))
                 .foregroundColor(.white)
             Text(title)
                 .font(.caption)
                 .foregroundColor(.white.opacity(0.8))
         }
     }
     
     private var emptyGroupState: some View {
         VStack(spacing: 12) {
             Image(systemName: "person.3")
                 .font(.system(size: 40))
                 .foregroundColor(.gray)
             Text("Select a group to view competitors")
                 .font(.subheadline)
                 .foregroundColor(.gray)
         }
         .frame(maxWidth: .infinity)
         .padding(.vertical, 40)
     }
     
     private func leaderboardCard(for group: Group) -> some View {
         VStack(spacing: 12) {
             Circle()
                 .fill(Color.blue.opacity(0.2))
                 .frame(width: 60, height: 60)
                 .overlay(
                     Text(String(group.name.prefix(1)))
                         .font(.title2.bold())
                         .foregroundColor(.blue)
                 )
             
             Text(group.name)
                 .font(.subheadline)
                 .fontWeight(.medium)
                 .lineLimit(1)
             
             Text("\(viewModel.playersInGroup[group.id]?.count ?? 0) players")
                 .font(.caption)
                 .foregroundColor(.gray)
         }
         .frame(width: 120)
         .padding()
         .background(Color.white.opacity(0.05))
         .cornerRadius(16)
     }
     
     private func formattedDate(_ date: Date) -> String {
         let formatter = DateFormatter()
         formatter.dateFormat = "MMM d, yyyy"
         return formatter.string(from: date)
     }
 }

 // Enhanced CustomGroupPicker
 struct CustomGroupPicker: View {
     @Binding var selection: Group?
     let groups: [Group]
     
     var body: some View {
         Menu {
             ForEach(groups, id: \.id) { group in
                 Button(action: { selection = group }) {
                     HStack {
                         Text(group.name)
                         if selection?.id == group.id {
                             Image(systemName: "checkmark")
                                 .foregroundColor(.blue)
                         }
                     }
                 }
             }
         } label: {
             HStack {
                 Image(systemName: "flag.fill")
                     .foregroundColor(.blue)
                 Text(selection?.name ?? "Select a Group")
                     .foregroundColor(.primary)
                 Spacer()
                 Image(systemName: "chevron.down")
                     .foregroundColor(.blue)
             }
             .padding()
             .background(Color.white.opacity(0.1))
             .cornerRadius(12)
             .overlay(
                 RoundedRectangle(cornerRadius: 12)
                     .stroke(Color.blue.opacity(0.3), lineWidth: 1)
             )
         }
     }
 }

 // Enhanced PlayerList
 struct PlayerList: View {
     let players: [Profile]
     @Binding var isAnimating: Bool
     
     var body: some View {
         VStack(spacing: 12) {
             ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                 HStack(spacing: 16) {
                     Text("\(index + 1)")
                         .font(.system(.callout, design: .rounded))
                         .fontWeight(.bold)
                         .foregroundColor(.blue)
                         .frame(width: 24)
                     
                     Image(systemName: "person.circle.fill")
                         .font(.title3)
                         .foregroundColor(.blue)
                     
                     Text(player.full_name)
                         .font(.system(.body, design: .rounded))
                     
                     Spacer()
                     
                     Image(systemName: "chevron.right")
                         .font(.caption)
                         .foregroundColor(.gray)
                 }
                 .padding()
                 .background(Color.white.opacity(0.05))
                 .cornerRadius(12)
                 .opacity(isAnimating ? 1 : 0)
                 .offset(y: isAnimating ? 0 : 20)
                 .animation(
                     .spring(response: 0.3, dampingFraction: 0.7)
                     .delay(Double(index) * 0.05),
                     value: isAnimating
                 )
             }
         }
         .padding(.horizontal)
     }
 }
 */
