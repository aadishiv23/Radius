//
//  RadiusApp.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 4/5/24.
//

import AppIntents
import Supabase
import SwiftUI

@main
struct RadiusApp: App {
    let supabaseClient = supabase
    @StateObject private var dataController = DataController()
    @StateObject private var friendsDataManager: FriendsDataManager
    @StateObject private var authViewModel: AuthViewModel
    @StateObject var locationManager = LocationManager.shared

    @Environment(\.scenePhase) var scenePhase

    init() {
        let friendsDataManager = FriendsDataManager(supabaseClient: supabaseClient)
        _friendsDataManager = StateObject(wrappedValue: friendsDataManager)
        _authViewModel = StateObject(wrappedValue: AuthViewModel(friendsDataManager: friendsDataManager))
        CLLocationCoordinate2DTransformer.register()
        ColorTransformer.register()
    }

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(friendsDataManager)
                .environmentObject(authViewModel)
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .background:
                        locationManager.startInactivityTimer()
                    case .active:
                        locationManager.stopInactivityTimer()
                    default:
                        break
                    }
                }
        }
    }
}

// @main
// struct RadiusApp: App {
//    let dataController = DataController()
//    let friendsDataManager: FriendsDataManager
//    let supabaseClient = supabase
//
//    init() {
//        friendsDataManager = FriendsDataManager(dataController: dataController, supabaseClient: supabaseClient)
//        CLLocationCoordinate2DTransformer.register()
//        ColorTransformer.register()
//    }
//
//    var body: some Scene {
//        WindowGroup {
//            AppView()
//                .environment(\.managedObjectContext, dataController.container.viewContext)
//                .environmentObject(FriendsDataManager(dataController: dataController, supabaseClient: supabaseClient))
//        }
//    }
//
// }

// struct RadiusApp: App {
//    //@StateObject var friendData = FriendData()  // Create an instance of your data model
//    @State var isAuthenticated = false
//    let dataController = DataController() // Initialize your Core Data controller
//    let friendsDataManager: FriendsDataManager
//
//
//    init() {
//        friendsDataManager = FriendsDataManager(dataController: dataController)
//        CLLocationCoordinate2DTransformer.register()
//        ColorTransformer.register()
//    }
//
//    var body: some Scene {
//        WindowGroup {
//            if isAuthenticated {
//                //SupabaseProfileView()
//                AppView()
//                    .environmentObject(friendsDataManager)
//                //                Group {
//                //                    TabView {
//                //                        HomeView()
//                //                            .tabItem {
//                //                                Label("Home", systemImage: "house.fill")
//                //                            }
//                //
//                //                        InfoView()
//                //                            .tabItem {
//                //                                Label("Person", systemImage: "person.fill")
//                //                            }
//                //
//                //                        ContentView()
//                //                            .tabItem {
//                //                                Label("Map", systemImage: "map")
//                //                            }
//                //                    }
//                //                    .environmentObject(friendsDataManager)  // Provide the EnvironmentObject to all
//                /views
//                //}
//            }
//            else {
//                AuthView()
//            }
//        }
//
//    }
//
// }
