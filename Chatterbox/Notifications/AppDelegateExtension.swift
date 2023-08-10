//
//  AppDelegateExtension.swift
//  Chatterbox
//
//  Created by Александра Кострова on 10.08.2023.
//


import UserNotifications

extension AppDelegate: UNUserNotificationCenterDelegate {
    //the app on screen
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
        print("notification was presented")
    }
    
    //click on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("click on notification")
    }
}
