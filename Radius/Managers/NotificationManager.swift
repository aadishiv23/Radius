//
//  NotificationManager.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 10/30/24.
//

import SwiftUI
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                print("Authorization error: \(error)")
            } else if granted {
                print("Notifications authorized")
            }
        }
    }

    func scheduleZoneExitNotification(zoneName: String, time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Radius: Zone Exit"
        content.body = "You have left \(zoneName) at \(formattedTime(time)). Click to confirm this zone exit!"
        content.sound = .default
        content.categoryIdentifier = "RADIUS.ZONE_EXIT"

        // Configure a trigger for this notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // Create the request
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
