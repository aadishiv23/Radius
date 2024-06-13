//
//  FriendProfileView.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/25/24.
//

import Foundation
import SwiftUI

// Define a simple profile view for displaying friend details
struct FriendProfileView: View {
    var friend: Profile
    @State private var editingZoneId: UUID? = nil
    @State private var zoneName: String = ""
    @EnvironmentObject var friendsDataManager: FriendsDataManager
    @State private var iconTapped: Bool = false
    @State private var rotationAngle: Double = 0


    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 20)
            VStack {
                ZStack {
                   Circle()
                       .foregroundStyle(LinearGradient(colors: [.red, .pink, .blue], startPoint: .leading, endPoint: .trailing))
                       .frame(width: iconTapped ? 100 : 60, height: iconTapped ? 100 : 60)
                       .rotationEffect(.degrees(rotationAngle))
                       .onTapGesture {
                           withAnimation(.spring()) {
                               iconTapped.toggle()
                               rotationAngle += 360
                           }
                       }
                   Text(friend.full_name.prefix(1))
                       .font(.largeTitle)
                       .fontWeight(.bold)
                       .foregroundStyle(Color.white)
                       .shadow(radius: iconTapped ? 10 : 5)
               }
            }
            .frame(maxWidth: .infinity)
            Text("Coordinates: \(friend.latitude), \(friend.longitude)")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .center)
            
            ForEach(friend.zones) { zone in
                VStack {
                    if editingZoneId == zone.id {
                        TextField("Zone name", text: $zoneName)
                            .onSubmit {
                                Task {
                                    do {
                                        try await friendsDataManager.renameZone(zoneId: zone.id, newName: zoneName)
                                        // Refresh friend profile data here or use an observable object to trigger a view update.
                                        editingZoneId = nil // Exit editing mode after saving.
                                    } catch {
                                        print("Failed to rename zone")
                                    }
                                }
                            }
                            .onAppear {
                                zoneName = zone.name
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(LinearGradient(gradient: Gradient(colors: [.pink, .blue]), startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                                    .padding(-5)
                                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
                            )
                    } else {
                        Text(zone.name)
                            .onTapGesture {
                                editingZoneId = zone.id
                                zoneName = zone.name
                            }
                    }
                    Text(String(zone.latitude))
                    Text(String(zone.longitude))
                    Text(String(zone.radius))
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundStyle(.blue)
                        .opacity(0.3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(LinearGradient(gradient: Gradient(colors: [.pink, .blue]), startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                                .opacity(editingZoneId == zone.id ? 1 : 0)
                                .animation(.easeInOut, value: editingZoneId)
                        )
                )
                .padding(.vertical, 5)
            }
            Spacer()
        }
        .padding()
        .navigationTitle(friend.full_name)
    }
}

struct CardGradientView: View {
    @State var rotation: CGFloat = 0.0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .frame(width: 260, height: 340)
                .foregroundColor(.black.opacity(0.9))
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .frame(width: 130, height: 500)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.red, Color.purple]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(rotation))
                .mask {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(lineWidth: 7)
                        .frame(width: 256, height: 336)
                }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        
    }
}

struct CardGradientViewV2: View {
    @State var rotation: CGFloat = 0.0

    var body: some View {
        ZStack {
            Color(.gray)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .frame(width: 440, height: 430)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(rotation))
                .mask {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(lineWidth: 10)
                        .frame(width: 250, height: 335)
                        .blur(radius: 5)
                }
            
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .frame(width: 260, height: 340)
                .foregroundColor(.black)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .frame(width: 500, height: 440)
                .rotationEffect(.degrees(rotation))
                .mask {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(lineWidth: 10)
                        .frame(width: 250, height: 336)
                }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        
    }
}

