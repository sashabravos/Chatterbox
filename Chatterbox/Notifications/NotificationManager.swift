//
//  NotificationManager.swift
//  Chatterbox
//
//  Created by Александра Кострова on 10.08.2023.
//

import UserNotifications

final class NotificationManager {
    
    static let shared = NotificationManager()
    
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "You have a new message"
        content.body = "Sender's username here"
        content.sound = UNNotificationSound.default
    
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
    
        // create request
        let request = UNNotificationRequest(identifier: "notification",
                                            content: content,
                                            trigger: trigger)
        // create request to NotificationCenter
        UNUserNotificationCenter.current().add(request) { error in
            print(error?.localizedDescription as Any)
        }
    }

}
