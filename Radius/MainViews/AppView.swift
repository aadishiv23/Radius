////
////  AppView.swift
////  Radius
////
////  Created by Aadi Shiv Malhotra on 5/8/24.
////
//
//import Foundation
//import SwiftUI
//
//struct AppView: View {
//  @State var isAuthenticated = false
//
//  var body: some View {
//    Group {
//      if isAuthenticated {
//          Group {
//              TabView {
//                  HomeView()
//                      .tabItem {
//                          Label("Home", systemImage: "house.fill")
//                      }
//                  
//                  InfoView()
//                      .tabItem {
//                          Label("Person", systemImage: "person.fill")
//                      }
//                  
//                  ContentView()
//                      .tabItem {
//                          Label("Map", systemImage: "map")
//                      }
//              }
//              .environmentObject(friendsDataManager)  // Provide the EnvironmentObject to all views
//      } else {
//        AuthView()
//      }
//    }
//    .task {
//      for await state in await supabase.auth.authStateChanges {
//        if [.initialSession, .signedIn, .signedOut].contains(state.event) {
//          isAuthenticated = state.session != nil
//        }
//      }
//    }
//  }
//}
