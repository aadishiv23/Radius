//
//  RealtimeManager.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 6/16/24.
//

import Foundation
import Supabase
import CoreLocation
import Realtime

class RealtimeManager: ObservableObject {
    private var locationManager = LocationManager.shared
    
    @Published var currentUser: Profile?
    
    init() {
        Task {
            let channel = await supabase.realtimeV2.channel("public:profiles")
            
            let insertions = await channel.postgresChange(InsertAction.self, table: "profiles")
            let updates = await channel.postgresChange(UpdateAction.self, table: "profiles")
            let deletions = await channel.postgresChange(DeleteAction.self, table: "profiles")
            
            await channel.subscribe()
        }
    }
}
