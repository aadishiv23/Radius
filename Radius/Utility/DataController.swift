//
//  DataController.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 8/16/24.
//

import Foundation
import CoreData

// can use @stateobj so can stay alive for app lifetime
class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "Radius")
    
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        print("Load Succesfull")
    }
    
}
