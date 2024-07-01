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
    private var channel: RealtimeChannelV2?

    @Published var currentUser: Profile?
    
    init() {
        Task {
            channel = await supabase.realtimeV2.channel("public:profiles")
            
            let insertions = await channel?.postgresChange(InsertAction.self, schema: "public", table: "profiles")
            let updates = await channel.postgresChange(UpdateAction.self, table: "profiles")
            let deletions = await channel.postgresChange(DeleteAction.self, table: "profiles")
            
            await channel.subscribe()
            
            Task {
                for await insertion in insertions {
                    handleInsertedChannel(insertion)
                }
            }
            Task {
                for await update in updates {
                    handleUpdatedChannel(update)
                }
            }
            Task {
                for await deletion in deletions {
                    handleDeletionChannel(deletion)
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
    
    private func handleUpdatedChannel(_ action: UpdateAction) {
        do {
            let updatedProfile = try action.decodeRecord(decoder: decoder) as Profile
            DispatchQueue.main.async {
                // Handle update logic
            }
        } catch {
            print("Failed to handleUpdatedChannel due to \(error)")
        }
    }
    
    private func handleDeletionChannel(_ action: DeleteAction) {
        do {
            let profileToDelete = try action.decodeOldRecord(decoder: decoder) as Profile
            DispatchQueue.main.async {
                // Handle deletion logic
            }
        } catch {
            print("Failed to handleDeletionChannel due to \(error)")
        }
    }
}
