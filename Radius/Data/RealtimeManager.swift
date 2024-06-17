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
            
            let insertions = await channel.postgresChange(InsertAction.self, schema: "public", table: "profiles")
            let updates = await channel.postgresChange(UpdateAction.self, table: "profiles")
            let deletions = await channel.postgresChange(DeleteAction.self, table: "profiles")
            
            await channel.subscribe()
            
            Task {
                for await insertion in insertions {
                    handleInsertedChannel(insertion)
                }
            }
        }
    }
    
    private func handleInsertedChannel(_ action: InsertAction) {
        do {
            let channel = try action.decodeRecord(decoder: decoder) as Profile
        } catch {
            print("Failed to handleInsertedChannel due to \(error)")
        }
    }
}
