//
//  GoogleCalNoisyNotificationApp.swift
//  GoogleCalNoisyNotification
//
//  Created by Erin Gallagher on 2026-06-14.
//

import SwiftUI

@main
struct GoogleCalNoisyNotificationApp: App {
    @State private var calendarManager = CalendarManager()
    
    var body: some Scene {
        MenuBarExtra("GoogleCalNoisyNotificationsApp", systemImage: "calendar.badge.clock") {
            Button("GoogleCalNoisyNotificationsApp") { }
                .disabled(true)
            
            Button("Test Banner") {
                BannerWindowManager.show(
                    title: "Test Meeting",
                    startTime: "In 3 minutes — 2:30 PM"
                )
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
