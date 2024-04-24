//
//  RadiusApp.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/5/24.
//

import SwiftUI

@main
struct RadiusApp: App {
    @StateObject var friendData = FriendData()  // Create an instance of your data model

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                InfoView()
                    .tabItem {
                        Label("Person", systemImage: "person.fill")
                    }
                
                ContentView()
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
            }
            .environmentObject(friendData)  // Provide the EnvironmentObject to all views
        }
    }
}
